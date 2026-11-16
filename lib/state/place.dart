import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/meal_rules.dart';
import 'package:eat/state/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place.g.dart';

/// 已开放的校区列表, 数据来自 `/campus/list`.
@Riverpod(keepAlive: true)
Future<List<Campus>> campuses(Ref ref) =>
    ref.watch(placeRepositoryProvider).campuses(cancelToken: ref.cancelToken());

/// 全部商圈列表, 用于附近页的商圈胶囊筛选.
@Riverpod(keepAlive: true)
Future<List<Hub>> hubs(Ref ref) =>
    ref.watch(placeRepositoryProvider).hubs(cancelToken: ref.cancelToken());

/// 单个商圈. 先在 [hubs] 里找; 列表里没有 (列表只取了第一页) 或列表加载失败时, 按 id 查商圈详情.
@Riverpod(keepAlive: true)
Future<Hub?> hub(Ref ref, int id) async {
  try {
    for (final hub in await ref.watch(hubsProvider.future)) {
      if (hub.id == id) return hub;
    }
  } on AppFailure {
    // 列表失败时退回到按 id 查询.
  }
  return ref
      .watch(placeRepositoryProvider)
      .hub(id, cancelToken: ref.cancelToken());
}

/// 用户在 "在哪吃" 面板中的选择: 校区, 手动选择的饭点及其失效时间, 堂食还是外卖.
class const PlaceChoice({
  final int? campusId,
  final MealTime? manualMeal,
  final DateTime? manualUntil,

  /// 用餐场景 (堂食或外卖), 没选过时为 null 并按堂食处理.
  final RatingScene? scene,

  /// 本地存储中的选择是否已读出. 读出之前不按默认值请求推荐.
  final bool restored = false,
});

/// 管理持久化在本机的校区, 饭点与用餐场景选择.
///
/// 属于设备级偏好, 退出登录时不清除; 场景与校区一样长期保留, 手动选择的饭点仅保持到当前时间段结束.
@Riverpod(keepAlive: true)
class PlaceAndMeal extends _$PlaceAndMeal {
  static const campusKey = 'prefs.campus';
  static const mealKey = 'prefs.meal';
  static const sceneKey = 'prefs.scene';

  @override
  PlaceChoice build() {
    unawaited(_restore());
    return const PlaceChoice();
  }

  KvStore get _kv => ref.read(kvStoreProvider);

  Future<void> _restore() async {
    final campus = int.tryParse(await _kv.read(campusKey) ?? '');
    final meal = (await _kv.read(mealKey))?.split('|');
    MealTime? manual;
    DateTime? until;
    if (meal case [final name, final millis]) {
      manual = MealTime.fromApi(name);
      until = DateTime.fromMillisecondsSinceEpoch(int.tryParse(millis) ?? 0);
    }
    final sceneApi = await _kv.read(sceneKey);
    final scene = RatingScene.values
        .where((s) => s.api == sceneApi)
        .firstOrNull;
    if (!ref.mounted) return;
    state = PlaceChoice(
      campusId: state.campusId ?? campus,
      manualMeal: state.manualMeal ?? manual,
      manualUntil: state.manualUntil ?? until,
      scene: state.scene ?? scene,
      restored: true,
    );
  }

  Future<void> selectCampus(int id) async {
    state = PlaceChoice(
      campusId: id,
      manualMeal: state.manualMeal,
      manualUntil: state.manualUntil,
      scene: state.scene,
      restored: true,
    );
    await _kv.write(campusKey, '$id');
  }

  /// 手动选择饭点, 有效期到当前时间段结束.
  Future<void> selectMeal(MealTime meal) async {
    final until = MealRules.periodEnd(clock.now());
    state = PlaceChoice(
      campusId: state.campusId,
      manualMeal: meal,
      manualUntil: until,
      scene: state.scene,
      restored: true,
    );
    await _kv.write(mealKey, '${meal.api}|${until.millisecondsSinceEpoch}');
  }

  /// 恢复为按当前时间自动选择饭点.
  Future<void> autoMeal() async {
    state = PlaceChoice(
      campusId: state.campusId,
      scene: state.scene,
      restored: true,
    );
    await _kv.delete(mealKey);
  }

  /// 选择用餐场景 (堂食或外卖).
  Future<void> selectScene(RatingScene scene) async {
    state = PlaceChoice(
      campusId: state.campusId,
      manualMeal: state.manualMeal,
      manualUntil: state.manualUntil,
      scene: scene,
      restored: true,
    );
    await _kv.write(sceneKey, scene.api);
  }
}

/// 当前使用的地点, 饭点和场景.
class const CurrentPlace({
  final Campus? campus,
  required final MealTime meal,
  required final bool autoMeal,

  /// 用餐场景, 决定菜品推荐的范围和排序.
  final RatingScene scene = RatingScene.dineIn,

  /// 本机选择和校区列表是否都已就绪. 未就绪时不请求推荐.
  ///
  /// 推荐按天去重. 以错误地点发出后又取消的请求, 也可能被服务端计为已推荐.
  final bool ready = false,
}) {
  @override
  bool operator ==(Object other) =>
      other is CurrentPlace &&
      other.campus?.id == campus?.id &&
      other.meal == meal &&
      other.autoMeal == autoMeal &&
      other.scene == scene &&
      other.ready == ready;

  @override
  int get hashCode => Object.hash(campus?.id, meal, autoMeal, scene, ready);
}

/// 计算当前生效的校区, 饭点与用餐场景.
///
/// - 校区: 依次优先采用上次选择的校区, 离当前定位最近的校区, 默认校区.
/// - 饭点: 手动选择且未过期时使用手动选择, 否则按当前时间推算.
/// - 场景: 采用上次选择, 没选过时为堂食.
///
/// 当时间段结束 ([mealPeriodEnd]) 或应用回到前台时, 由发现页触发重算;
/// 此处不自行启动定时器, 避免常驻 Provider 持有长期定时器.
@Riverpod(keepAlive: true)
CurrentPlace currentPlace(Ref ref) {
  final choice = ref.watch(placeAndMealProvider);
  final campusList = ref.watch(campusesProvider);
  final campuses = campusList.value ?? const <Campus>[];
  final me = ref.watch(currentLocationProvider.select((s) => s.point));
  final now = clock.now();

  Campus? campus;
  for (final c in campuses) {
    if (c.id == choice.campusId) campus = c;
  }
  if (campus == null && campuses.isNotEmpty) {
    if (me != null) {
      final sorted = [...campuses]
        ..sort(
          (a, b) => GeoRules.distance(
            me,
            a.center,
          ).compareTo(GeoRules.distance(me, b.center)),
        );
      campus = sorted.first;
    } else {
      campus = campuses.firstWhere(
        (c) => c.isDefault,
        orElse: () => campuses.first,
      );
    }
  }

  final until = choice.manualUntil;
  final manual =
      choice.manualMeal != null && until != null && now.isBefore(until)
      ? choice.manualMeal
      : null;
  return CurrentPlace(
    campus: campus,
    meal: manual ?? MealRules.at(now),
    scene: choice.scene ?? RatingScene.dineIn,
    autoMeal: manual == null,
    ready: choice.restored && !campusList.isLoading,
  );
}

/// 搜索店铺时使用的参照坐标与校区范围.
///
/// - [point]: 当前设备定位, 若无定位则回退为当前校区的中心. 两者都没有时为 null, 后端按新建时间倒序排列.
/// - [campusId]: 当前校区 id. 搜店接口不传校区时不限校区.
typedef ShopSearchScope = ({GcjPoint? point, int? campusId});

/// 计算当前的搜店范围. 若校区列表仍在加载则等待其完成, 等待期间若调用方已释放则返回 null.
Future<ShopSearchScope?> shopSearchScope(Ref ref) async {
  if (ref.read(campusesProvider).isLoading) {
    try {
      await ref.read(campusesProvider.future);
    } on Object {
      // 校区列表获取失败时按没有校区处理, 仍可使用定位.
    }
    if (!ref.mounted) return null;
  }
  final campus = ref.read(currentPlaceProvider).campus;
  final point = ref.read(currentLocationProvider).point ?? campus?.center;
  return (point: point, campusId: campus?.id);
}

/// 当前饭点的失效时间: 手动选择的到期时间, 或当前时间段的结束时间.
DateTime mealPeriodEnd(PlaceChoice choice, DateTime now) {
  final until = choice.manualUntil;
  return until != null && now.isBefore(until)
      ? until
      : MealRules.periodEnd(now);
}
