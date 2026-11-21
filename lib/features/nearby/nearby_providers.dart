import 'dart:convert';

import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nearby_providers.g.dart';

/// 附近页筛选面板的选项. 不同选项之间为 "与" 关系.
class const NearbyFilter({
  /// 店铺类型. 为 null 时不限.
  final ShopKind? kind,

  /// 店铺品类命中其中任一即可. 为空时不限品类.
  final Set<ShopCategory> categories = const {},
  final PriceBand? priceBand,

  /// 只看口碑好的店: 任一场景至少 3 条评价且推荐率不低于 [recommendedRate]%.
  final bool recommendedOnly = false,

  /// 只看当前账号收藏的店.
  ///
  /// 后端要求登录, 游客选择时先弹登录拦截. 未认证的账号也能查看收藏的店, 不做拦截.
  final bool favoritesOnly = false,
}) {
  /// "只看口碑好的" 的推荐率门槛, 整数百分比. 与搜店接口 `recommendedOnly` 相同.
  ///
  /// 评价条数的门槛见 `ShopRules.rateMinCount`.
  static const recommendedRate = 70;

  /// 已选的项数, 显示在筛选按钮上. 每个品类各算一项.
  int get count =>
      (kind == null ? 0 : 1) +
      categories.length +
      (priceBand == null ? 0 : 1) +
      (recommendedOnly ? 1 : 0) +
      (favoritesOnly ? 1 : 0);

  @override
  bool operator ==(Object other) =>
      other is NearbyFilter &&
      other.kind == kind &&
      setEquals(other.categories, categories) &&
      other.priceBand == priceBand &&
      other.recommendedOnly == recommendedOnly &&
      other.favoritesOnly == favoritesOnly;

  @override
  int get hashCode => Object.hash(
    kind,
    Object.hashAllUnordered(categories),
    priceBand,
    recommendedOnly,
    favoritesOnly,
  );
}

/// 附近页店铺查询条件, 包含地图中心点, 选中商圈, 搜索关键词与筛选项.
class const NearbyQuery({
  required final GcjPoint center,
  final int? hubId,
  final String keyword = '',
  final NearbyFilter filter = const NearbyFilter(),
}) {
  NearbyQuery copyWith({NearbyFilter? filter}) => NearbyQuery(
    center: center,
    hubId: hubId,
    keyword: keyword,
    filter: filter ?? this.filter,
  );

  @override
  bool operator ==(Object other) =>
      other is NearbyQuery &&
      other.center == center &&
      other.hubId == hubId &&
      other.keyword == keyword &&
      other.filter == filter;

  @override
  int get hashCode => Object.hash(center, hubId, keyword, filter);
}

/// 未选商圈且未输入关键词时的查询半径, 单位米.
const nearbyRadius = 3000;

/// 查询当前校区内附近营业中的店铺, 按与用户的距离升序排列.
///
/// - 关键词同时匹配店名与地址; 搜店接口包含已歇业店铺, 此处过滤掉已关门的店, 因此实际返回数可能少于分页大小.
/// - 后端按与地图中心的距离排序, 因列表展示的是与用户实时定位的距离, 拖动地图后两者不再一致, 故客户端在有定位时按用户距离重排, 无定位时保持服务端顺序.
@riverpod
Future<List<Shop>> nearbyShops(Ref ref, NearbyQuery query) async {
  ref.cacheFor(const Duration(minutes: 1));
  final keyword = query.keyword.trim();
  final filter = query.filter;
  final page = await ref
      .watch(placeRepositoryProvider)
      .searchShops(
        keyword: keyword.isEmpty ? null : keyword,
        hubId: query.hubId,
        near: query.center,
        radius: query.hubId == null && keyword.isEmpty ? nearbyRadius : null,
        kind: filter.kind,
        categories: filter.categories,
        priceBand: filter.priceBand,
        recommendedOnly: filter.recommendedOnly,
        favoritesOnly: filter.favoritesOnly,
        sort: ShopSort.distance,
        pageSize: 60,
        cancelToken: ref.cancelToken(),
      );
  final me = ref.read(currentLocationProvider).point ?? query.center;
  return [
    for (final shop in page.items)
      if (!shop.closed) shop,
  ]..sort(
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

/// 最近在 "选商圈" 面板里选过的商圈 ID, 最近选的在前, 最多 [max] 个. "附近" 不记.
///
/// 和最近搜索一样按账号存在 `cache.` 前缀下, 退出登录时随账号缓存清除.
/// 游客不落盘, 只在这次打开 App 期间记着; 因此保持存活, 关上面板不丢.
@Riverpod(keepAlive: true)
class RecentHubs extends _$RecentHubs {
  static const max = 4;

  /// 本地缓存键名. 未登录或游客为 null, 不读写本地.
  String? _key;

  @override
  Future<List<int>> build() async {
    final key = _key = ref.watch(
      sessionProvider.select(
        (s) => switch (s) {
          SignedIn(:final user) => 'cache.nearby.hubs.${user?.id ?? 0}',
          SignedOut() || Guest() => null,
        },
      ),
    );
    if (key == null) return const [];
    final raw = await ref.watch(kvStoreProvider).read(key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<int>();
    } on Object {
      return const [];
    }
  }

  Future<void> add(int hubId) async {
    final ids = [
      hubId,
      ...?state.value?.where((id) => id != hubId),
    ].take(max).toList();
    state = AsyncData(ids);
    if (_key case final key?) {
      await ref.read(kvStoreProvider).write(key, jsonEncode(ids));
    }
  }
}
