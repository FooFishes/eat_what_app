import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/recommend/recommend_repository.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discover_providers.g.dart';

/// 转盘数据: 按批次追加的推荐店铺, 以及当前所在的位置.
class const TurntableFeed({
  required final List<Shop> shops,
  final int index = 0,

  /// 每一批在队列中的起始下标, 用于计算舞台左下角的批次圆点.
  final List<int> batchStarts = const [0],

  /// 最后一次请求的页码. 下一批请求下一页.
  final int page = 1,

  /// 是否还有下一批. 后端说没有, 或下一批里都是已经拿到过的店, 即视为没有.
  ///
  /// 没有下一批时, 在最后一家点击 "换一个" 回到第一家.
  final bool hasMore = true,

  /// 推荐请求失败, 当前显示的是该校区, 场景和饭点上一次获取的批次.
  final bool stale = false,
}) {
  Shop? get current => shops.isEmpty ? null : shops[index];

  /// 当前店铺所在批次的范围.
  ({int start, int length}) get batch {
    var start = 0;
    var end = shops.length;
    for (final (i, s) in batchStarts.indexed) {
      if (s <= index) {
        start = s;
        end = i + 1 < batchStarts.length ? batchStarts[i + 1] : shops.length;
      }
    }
    return (start: start, length: end - start);
  }

  /// 去掉 [shopId] 后的队列. 去掉的是当前这家时停在下一家, 它是最后一家时回到第一家.
  ///
  /// 批次的起始下标随之前移, 变空的批次不再计入圆点.
  TurntableFeed without(int shopId) {
    final at = shops.indexWhere((s) => s.id == shopId);
    if (at < 0) return this;
    final rest = [...shops]..removeAt(at);
    final starts = <int>[];
    for (final s in batchStarts) {
      final moved = s > at ? s - 1 : s;
      if (moved < rest.length && starts.lastOrNull != moved) starts.add(moved);
    }
    final next = index > at ? index - 1 : index;
    return TurntableFeed(
      shops: rest,
      index: next < rest.length ? next : 0,
      batchStarts: starts.isEmpty ? const [0] : starts,
      page: page,
      hasMore: hasMore,
      stale: stale,
    );
  }
}

// TODO: 后端不保存店铺的舞台色和备选色. 后端恢复后, 撞色时改用店铺的备选色.
/// 转盘上每家店实际使用的舞台色.
///
/// 与前一家撞色时依次换用该店其余品类映射的颜色, 都撞色则保持原色.
/// 替换只影响转盘显示, 店铺页仍用 `ShopRules.stageOf`.
List<StageColor> turntableColors(List<Shop> shops) {
  final colors = <StageColor>[];
  for (final shop in shops) {
    final own = ShopRules.stageOf(shop);
    final candidates = [
      own,
      for (final category in shop.categories.skip(1))
        // ShopRules 按第一个品类映射颜色, 只留一个品类即得到该品类的颜色.
        ShopRules.stageOf(
          Shop(
            id: shop.id,
            name: shop.name,
            point: shop.point,
            kind: shop.kind,
            categories: [category],
          ),
        ),
    ];
    final previous = colors.lastOrNull;
    colors.add(candidates.firstWhere((c) => c != previous, orElse: () => own));
  }
  return colors;
}

/// 推荐请求带的位置: 我的定位. 没有定位, 或人离当前校区过远时不带.
///
/// 带位置时堂食只推荐 3 km 内的店, 外卖只推荐 5 km 内的店. 人不在校区附近时, 按位置找只会是空的.
///
/// 只在请求时读取, 不监听. 定位晚于第一批推荐返回时, 不为此重排已经显示的转盘, 之后的批次再带上位置.
GcjPoint? _near(Ref ref, CurrentPlace place) {
  final me = ref.read(currentLocationProvider).point;
  final center = place.campus?.center;
  if (me == null) return null;
  if (center != null &&
      GeoRules.distance(me, center) > GeoRules.maxDistanceFromCampus) {
    return null;
  }
  return me;
}

/// 发现页的转盘队列: 推荐的美食店. 地点, 饭点或场景变化时重新请求.
///
/// 抽屉的分类栏不影响转盘, 转盘总是推荐美食 ([ShopKind.food]).
@Riverpod(keepAlive: true)
class TurntableQueue extends _$TurntableQueue {
  /// 一批的家数, 即舞台左下角的圆点数.
  static const batchSize = 8;

  /// 剩余店铺不多于该数量时预取下一批.
  static const _prefetch = 3;

  /// 每次重新请求第一批时加一. 预取返回时队列已经换过, 结果丢弃.
  var _generation = 0;

  @override
  Future<TurntableFeed> build() async {
    _generation++;
    final place = ref.watch(currentPlaceProvider);
    if (!place.ready) return Completer<TurntableFeed>().future;
    final repo = ref.watch(recommendRepositoryProvider);
    try {
      final first = await repo.recommend(
        scene: place.scene,
        meal: place.meal,
        campusId: place.campus?.id,
        near: _near(ref, place),
        pageSize: batchSize,
        cancelToken: ref.cancelToken(),
      );
      return TurntableFeed(
        shops: first.items,
        page: first.page,
        hasMore: first.hasNext && first.items.isNotEmpty,
      );
    } on AppFailure catch (e) {
      if (e.kind == FailureKind.cancelled) rethrow;
      final last = await repo.lastBatch(
        scene: place.scene,
        meal: place.meal,
        campusId: place.campus?.id,
      );
      if (last.isEmpty) rethrow;
      return TurntableFeed(shops: last, hasMore: false, stale: true);
    }
  }

  var _loading = false;

  /// 转到第 [index] 家. 拖动松手和点击 "换一个" 都调用此方法.
  ///
  /// [index] 超过最后一家时回到第一家.
  void select(int index) {
    final feed = state.value;
    if (feed == null || feed.shops.isEmpty) return;
    final wrapped = index >= feed.shops.length
        ? 0
        : index.clamp(0, feed.shops.length - 1);
    final next = TurntableFeed(
      shops: feed.shops,
      index: wrapped,
      batchStarts: feed.batchStarts,
      page: feed.page,
      hasMore: feed.hasMore,
      stale: feed.stale,
    );
    state = AsyncData(next);
    _prefetchIfNeeded(next);
  }

  void next() {
    final feed = state.value;
    if (feed != null) select(feed.index + 1);
  }

  /// 从队列里去掉一家店, 用于 "不想去这家". 队列空了时重新请求第一批.
  void remove(int shopId) {
    final feed = state.value;
    if (feed == null) return;
    final next = feed.without(shopId);
    if (next.shops.isEmpty) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData(next);
    _prefetchIfNeeded(next);
  }

  void _prefetchIfNeeded(TurntableFeed feed) {
    if (feed.hasMore && feed.shops.length - feed.index <= _prefetch) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadMore() async {
    final feed = state.value;
    if (_loading || feed == null) return;
    _loading = true;
    final generation = _generation;
    final place = ref.read(currentPlaceProvider);
    try {
      final more = await ref
          .read(recommendRepositoryProvider)
          .recommend(
            scene: place.scene,
            meal: place.meal,
            campusId: place.campus?.id,
            near: _near(ref, place),
            page: feed.page + 1,
            pageSize: batchSize,
          );
      if (!ref.mounted || generation != _generation) return;
      final now = state.value;
      if (now == null) return;
      final known = {for (final s in now.shops) s.id};
      final fresh = [
        for (final s in more.items)
          if (!known.contains(s.id)) s,
      ];
      state = AsyncData(
        TurntableFeed(
          shops: [...now.shops, ...fresh],
          index: now.index,
          batchStarts: fresh.isEmpty
              ? now.batchStarts
              : [...now.batchStarts, now.shops.length],
          page: more.page,
          hasMore: more.hasNext && fresh.isNotEmpty,
          stale: now.stale,
        ),
      );
    } on AppFailure {
      // 预取失败不中断浏览: 转到最后一家时回到第一家, 之后切换店铺时再次预取.
    } finally {
      _loading = false;
    }
  }
}

/// 抽屉中一栏的推荐店铺, 向下滚动时按批次追加.
class const ShopFeed({
  required final List<Shop> shops,

  /// 最后一次请求的页码. 下一批请求下一页.
  final int page = 1,
  final bool hasMore = true,
  final bool loadingMore = false,
  final AppFailure? moreError,
});

/// 抽屉里 [kind] 一栏的推荐店铺. 地点, 饭点或场景变化时重新请求.
///
/// 登录用户的推荐按天去重, 与转盘共用去重记录. "美食" 一栏因此列出转盘之外的更多推荐.
@riverpod
class DiscoverShops extends _$DiscoverShops {
  static const _pageSize = 10;

  @override
  Future<ShopFeed> build(ShopKind kind) async {
    final place = ref.watch(currentPlaceProvider);
    if (!place.ready) return Completer<ShopFeed>().future;
    final first = await ref
        .watch(recommendRepositoryProvider)
        .recommend(
          scene: place.scene,
          meal: place.meal,
          kind: kind,
          campusId: place.campus?.id,
          near: _near(ref, place),
          pageSize: _pageSize,
          cancelToken: ref.cancelToken(),
        );
    return ShopFeed(
      shops: first.items,
      page: first.page,
      hasMore: first.hasNext && first.items.isNotEmpty,
    );
  }

  Future<void> loadMore() async {
    final feed = state.value;
    if (feed == null || !feed.hasMore || feed.loadingMore) return;
    state = AsyncData(
      ShopFeed(shops: feed.shops, page: feed.page, loadingMore: true),
    );
    final place = ref.read(currentPlaceProvider);
    try {
      final more = await ref
          .read(recommendRepositoryProvider)
          .recommend(
            scene: place.scene,
            meal: place.meal,
            kind: kind,
            campusId: place.campus?.id,
            near: _near(ref, place),
            page: feed.page + 1,
            pageSize: _pageSize,
          );
      if (!ref.mounted) return;
      // 等待期间可能去掉过店铺, 因此在当前列表上追加.
      final shops = state.value?.shops ?? feed.shops;
      final known = {for (final s in shops) s.id};
      final fresh = [
        for (final s in more.items)
          if (!known.contains(s.id)) s,
      ];
      state = AsyncData(
        ShopFeed(
          shops: [...shops, ...fresh],
          page: more.page,
          hasMore: more.hasNext && fresh.isNotEmpty,
        ),
      );
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(
        ShopFeed(
          shops: state.value?.shops ?? feed.shops,
          page: feed.page,
          moreError: e,
        ),
      );
    }
  }

  /// 从列表里去掉一家店, 用于 "不想去这家".
  void remove(int shopId) {
    final feed = state.value;
    if (feed == null) return;
    state = AsyncData(
      ShopFeed(
        shops: [
          for (final s in feed.shops)
            if (s.id != shopId) s,
        ],
        page: feed.page,
        hasMore: feed.hasMore,
        loadingMore: feed.loadingMore,
        moreError: feed.moreError,
      ),
    );
  }
}

/// 不想去 [shopId]: 30 天内不再推荐, 成功后从转盘和抽屉列表里去掉这家.
///
/// 失败时抛出 [AppFailure], 由页面反馈.
Future<void> dismissShop(WidgetRef ref, int shopId) async {
  await ref.read(recommendRepositoryProvider).dismiss(shopId);
  ref.read(turntableQueueProvider.notifier).remove(shopId);
  for (final kind in ShopKind.values) {
    final list = discoverShopsProvider(kind);
    if (ref.exists(list)) ref.read(list.notifier).remove(shopId);
  }
}
