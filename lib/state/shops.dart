import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shops.g.dart';

/// 指定店铺的资料, 用于菜品详情的店卡和餐厅详情页展示.
///
/// 离开页面后仍会缓存 5 分钟, 期间重新进入不会重复发起请求.
@riverpod
Future<Shop> shop(Ref ref, int shopId) {
  ref.cacheFor(const Duration(minutes: 5));
  return ref
      .watch(placeRepositoryProvider)
      .shop(shopId, cancelToken: ref.cancelToken());
}

/// 商圈 id 对应的名称. 商圈尚未获取或不存在时为 null.
///
/// 店铺自带商圈名 (`Shop.hubName`). 只有不带商圈名的数据 (如菜品) 需要按 id 查找, 见 [hubProvider].
@riverpod
String? hubName(Ref ref, int? hubId) =>
    hubId == null ? null : ref.watch(hubProvider(hubId)).value?.name;

/// 格式化当前位置到 [point] 的距离文字; 若没有定位或用户离校区过远则返回 null.
@riverpod
String? distanceTo(Ref ref, GcjPoint? point) {
  final me = ref.watch(currentLocationProvider.select((s) => s.point));
  final campus = ref.watch(currentPlaceProvider.select((p) => p.campus));
  return GeoRules.distanceLabel(
    me: me,
    target: point,
    campusCenter: campus?.center,
  );
}
