import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nearby_providers.g.dart';

/// 附近页筛选面板的选项. 不同选项之间为 "与" 关系.
class const NearbyFilter({
  /// 店里有其中任一类菜即命中. 为空时不限分类.
  final Set<DishCategory> categories = const {},
  final PriceBand? priceBand,

  /// 只看推荐率不低于 80% 的店.
  final bool recommendedOnly = false,

  /// 只看当前账号收藏的店.
  ///
  /// 产品允许未认证和封禁中的账号查看收藏的店, 因此该选项对所有已登录账号开放, 不做拦截.
  final bool favoritesOnly = false,
}) {
  /// 已选的项数, 显示在筛选按钮上. 每个分类各算一项.
  int get count =>
      categories.length +
      (priceBand == null ? 0 : 1) +
      (recommendedOnly ? 1 : 0) +
      (favoritesOnly ? 1 : 0);

  @override
  bool operator ==(Object other) =>
      other is NearbyFilter &&
      setEquals(other.categories, categories) &&
      other.priceBand == priceBand &&
      other.recommendedOnly == recommendedOnly &&
      other.favoritesOnly == favoritesOnly;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(categories),
    priceBand,
    recommendedOnly,
    favoritesOnly,
  );
}

/// 附近页的查询条件: 地图中心, 选中的商圈, 搜索框中的店名, 筛选和排序.
class const NearbyQuery({
  required final GcjPoint center,
  final int? hubId,
  final String keyword = '',
  final NearbyFilter filter = const NearbyFilter(),
  final ShopSort sort = ShopSort.distance,
}) {
  NearbyQuery copyWith({NearbyFilter? filter}) => NearbyQuery(
    center: center,
    hubId: hubId,
    keyword: keyword,
    filter: filter ?? this.filter,
    sort: sort,
  );

  @override
  bool operator ==(Object other) =>
      other is NearbyQuery &&
      other.center == center &&
      other.hubId == hubId &&
      other.keyword == keyword &&
      other.filter == filter &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(center, hubId, keyword, filter, sort);
}

/// 未选商圈且未输入店名时的查询半径, 单位米.
const nearbyRadius = 3000;

/// 当前校区内附近营业中的店, 按 [NearbyQuery.sort] 排列.
///
/// 关键词同时匹配店名和菜名. 不传校区时后端只查默认校区.
///
/// 按距离排序时, 后端按与地图中心的距离排列, 客户端改按与用户的距离重排.
/// 列表显示的是与用户的距离, 拖动地图后两者不一致. 没有定位时保持按与地图中心的距离排列.
@riverpod
Future<List<Shop>> nearbyShops(Ref ref, NearbyQuery query) async {
  ref.cacheFor(const Duration(minutes: 1));
  final keyword = query.keyword.trim();
  final filter = query.filter;
  final campusId = ref.watch(currentPlaceProvider.select((p) => p.campus?.id));
  final page = await ref
      .watch(placeRepositoryProvider)
      .searchShops(
        campusId: campusId,
        keyword: keyword.isEmpty ? null : keyword,
        hubId: query.hubId,
        near: query.center,
        radius: query.hubId == null && keyword.isEmpty ? nearbyRadius : null,
        categories: filter.categories,
        priceBand: filter.priceBand,
        recommendedOnly: filter.recommendedOnly,
        favoritesOnly: filter.favoritesOnly,
        sort: query.sort,
        pageSize: 60,
        cancelToken: ref.cancelToken(),
      );
  if (query.sort != ShopSort.distance) return page.items;
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
