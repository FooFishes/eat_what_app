import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/state/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nearby_providers.g.dart';

/// 附近要找哪些店：地图中心、选中的商圈、搜索框里的店名。
class const NearbyQuery({
  required final GcjPoint center,
  final int? hubId,
  final String keyword = '',
}) {
  @override
  bool operator ==(Object other) =>
      other is NearbyQuery &&
      other.center == center &&
      other.hubId == hubId &&
      other.keyword == keyword;

  @override
  int get hashCode => Object.hash(center, hubId, keyword);
}

/// 不选商圈、不搜店名时，找地图中心多远以内的店（米）。
const nearbyRadius = 3000;

/// 附近的店，按离我的远近排（没有定位时按离地图中心）。已关门的店接口还不区分（现状差距 2.1）。
@riverpod
Future<List<Shop>> nearbyShops(Ref ref, NearbyQuery query) async {
  ref.cacheFor(const Duration(minutes: 1));
  final keyword = query.keyword.trim();
  final page = await ref
      .watch(placeRepositoryProvider)
      .searchShops(
        keyword: keyword.isEmpty ? null : keyword,
        hubId: query.hubId,
        near: query.center,
        radius: query.hubId == null && keyword.isEmpty ? nearbyRadius : null,
        pageSize: 60,
        cancelToken: ref.cancelToken(),
      );
  final me = ref.read(currentLocationProvider).point ?? query.center;
  return [...page.items]..sort(
    (a, b) => GeoRules.distance(
      me,
      a.point,
    ).compareTo(GeoRules.distance(me, b.point)),
  );
}

/// 我现在在哪个商圈里，附近页默认选中它；不在任何商圈里、或者没有定位时为 null（产品 6.7）。
@riverpod
Future<Hub?> myHub(Ref ref) async {
  final me = ref.watch(currentLocationProvider.select((s) => s.point));
  if (me == null) return null;
  return ref.watch(placeRepositoryProvider).locateHub(me);
}
