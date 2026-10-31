import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/meal_rules.dart';
import 'package:eat/state/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place.g.dart';

/// 已开放的校区（`/campus/list`）。
@Riverpod(keepAlive: true)
Future<List<Campus>> campuses(Ref ref) =>
    ref.watch(placeRepositoryProvider).campuses(cancelToken: ref.cancelToken());

/// 全部商圈。附近页的商圈胶囊、餐厅详情的商圈名用它。
@Riverpod(keepAlive: true)
Future<List<Hub>> hubs(Ref ref) =>
    ref.watch(placeRepositoryProvider).hubs(cancelToken: ref.cancelToken());

/// 用户在「地点和饭点」面板里选的：校区，以及手动选的饭点和它到什么时候失效。
class const PlaceChoice({
  final int? campusId,
  final MealTime? manualMeal,
  final DateTime? manualUntil,

  /// 本机存的选择读出来了没有。读出来之前不按默认值去拉推荐。
  final bool restored = false,
});

/// 地点和饭点的选择，存在本机（设备级偏好，退出登录不删，技术架构 9.1）。
@Riverpod(keepAlive: true)
class PlaceAndMeal extends _$PlaceAndMeal {
  static const campusKey = 'prefs.campus';
  static const mealKey = 'prefs.meal';

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
    if (!ref.mounted) return;
    state = PlaceChoice(
      campusId: state.campusId ?? campus,
      manualMeal: state.manualMeal ?? manual,
      manualUntil: state.manualUntil ?? until,
      restored: true,
    );
  }

  Future<void> selectCampus(int id) async {
    state = PlaceChoice(
      campusId: id,
      manualMeal: state.manualMeal,
      manualUntil: state.manualUntil,
      restored: true,
    );
    await _kv.write(campusKey, '$id');
  }

  /// 手动选一个饭点，保持到当前时间段结束（产品 4.5）。
  Future<void> selectMeal(MealTime meal) async {
    final until = MealRules.periodEnd(clock.now());
    state = PlaceChoice(
      campusId: state.campusId,
      manualMeal: meal,
      manualUntil: until,
      restored: true,
    );
    await _kv.write(mealKey, '${meal.api}|${until.millisecondsSinceEpoch}');
  }

  /// 「按现在的时间」。
  Future<void> autoMeal() async {
    state = PlaceChoice(campusId: state.campusId, restored: true);
    await _kv.delete(mealKey);
  }
}

/// 现在用的地点和饭点。
class const CurrentPlace({
  final Campus? campus,
  required final MealTime meal,
  required final bool autoMeal,

  /// 本机的选择和校区列表都有结果了。还没好时不去拉推荐：推荐按天去重，
  /// 拿错地点发出去又取消的请求也可能算作「推荐过」。
  final bool ready = false,
}) {
  @override
  bool operator ==(Object other) =>
      other is CurrentPlace &&
      other.campus?.id == campus?.id &&
      other.meal == meal &&
      other.autoMeal == autoMeal &&
      other.ready == ready;

  @override
  int get hashCode => Object.hash(campus?.id, meal, autoMeal, ready);
}

/// 当前的校区和饭点：校区按「上次选的 → 离定位最近的 → 默认」挑；饭点手动选的没过期就用它，
/// 否则按现在的时间。
///
/// 到了时间段结束（[mealPeriodEnd]）由发现页让它重算一次，回到前台时也重算。不在这里起定时器：
/// 它常驻，定时器会一直挂着。
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
    autoMeal: manual == null,
    ready: choice.restored && !campusList.isLoading,
  );
}

/// 现在显示的饭点什么时候该换：手动选的到期时间，或者当前时间段结束。
DateTime mealPeriodEnd(PlaceChoice choice, DateTime now) {
  final until = choice.manualUntil;
  return until != null && now.isBefore(until)
      ? until
      : MealRules.periodEnd(now);
}
