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

/// 一家店的资料。菜品详情的店卡、餐厅详情都用它，看不见以后再留 5 分钟（技术架构 10.5）。
@riverpod
Future<Shop> shop(Ref ref, int shopId) {
  ref.cacheFor(const Duration(minutes: 5));
  return ref
      .watch(placeRepositoryProvider)
      .shop(shopId, cancelToken: ref.cancelToken());
}

/// 商圈 id 对应的名字；商圈列表还没拉到或者对不上时为 null。
@riverpod
String? hubName(Ref ref, int? hubId) {
  if (hubId == null) return null;
  final hubs = ref.watch(hubsProvider).value ?? const <Hub>[];
  for (final hub in hubs) {
    if (hub.id == hubId) return hub.name;
  }
  return null;
}

/// 从我这里到 [point] 的距离写法；没有定位、或者人离校区太远时为 null（产品 6.4）。
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
