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

/// 一家店的资料, 用于菜品详情的店卡和餐厅详情.
///
/// 离开页面后继续缓存一段时间, 期间返回不重新请求.
@riverpod
Future<Shop> shop(Ref ref, int shopId) {
  ref.cacheFor(const Duration(minutes: 5));
  return ref
      .watch(placeRepositoryProvider)
      .shop(shopId, cancelToken: ref.cancelToken());
}

/// 商圈 id 对应的名称. 商圈列表尚未获取或没有对应商圈时为 null.
@riverpod
String? hubName(Ref ref, int? hubId) {
  if (hubId == null) return null;
  final hubs = ref.watch(hubsProvider).value ?? const <Hub>[];
  for (final hub in hubs) {
    if (hub.id == hubId) return hub.name;
  }
  return null;
}

/// 当前位置到 [point] 的距离文字. 没有定位或用户离校区过远时为 null.
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
