import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/state/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nearby_providers.g.dart';

/// 附近页的查询条件: 地图中心, 选中的商圈, 搜索框中的店名.
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

/// 未选商圈且未输入店名时的查询半径, 单位米.
const nearbyRadius = 3000;

// TODO: 接口不区分已关门的店, 已关门的店仍会出现在附近. 接口返回营业状态后过滤已关门的店.
/// 附近的店, 按与我的距离升序排列. 没有定位时按与地图中心的距离排列.
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

/// 我当前所在的商圈, 附近页默认选中该商圈.
///
/// 没有定位或不在任何商圈内时为 null.
@riverpod
Future<Hub?> myHub(Ref ref) async {
  final me = ref.watch(currentLocationProvider.select((s) => s.point));
  if (me == null) return null;
  return ref.watch(placeRepositoryProvider).locateHub(me);
}
