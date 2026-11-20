import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/data/recommend/recommend_repository.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/state/analytics.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discover_providers.g.dart';

/// 转盘数据源, 维护按批次追加的推荐店铺列表及当前选中索引.
class const TurntableFeed({
  required final List<Shop> shops,
  final int index = 0,

  /// 每一批在队列中的起始下标, 用于计算舞台左下角的批次圆点.
  final List<int> batchStarts = const [0],

  /// 最后一次请求的页码. 下一批请求下一页.
  final int page = 1,

  /// 是否还有更多批次可请求. 若服务端返回无下一页或新批次全为重复店铺, 则设为 false.
  ///
  /// 无更多批次时, 在末位店铺点击 "换一个" 会循环回到首位.
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

  /// 返回移除 [shopId] 后的新队列. 若移除当前选中店铺则顺延至下一家, 若为末位则回到首位.
  ///
  /// 后续批次的起始下标同步前移, 变空的批次不再计入圆点指示.
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

/// 推荐请求的查询位置: 有定位且离所选校区不远时用定位, 否则用校区的坐标. 两者都没有时返回 null, 后端不按位置筛选.
///
/// 后端不按校区筛选推荐, 校区只是一个位置预设. 携带位置时堂食只推荐 3 km 内的店, 外卖只推荐 5 km 内的店, 所以人离校区很远时改用校区坐标, 否则会按人所在的位置筛选.
/// 定位只在发起请求时读取, 不监听变化, 避免定位晚于首屏返回时重排已展示的转盘, 后续批次请求再自然带上定位.
GcjPoint? _near(Ref ref, CurrentPlace place) {
  final me = ref.read(currentLocationProvider).point;
  final center = place.campus?.center;
  if (me == null) return center;
  if (center != null &&
      GeoRules.distance(me, center) > GeoRules.maxDistanceFromCampus) {
    return center;
  }
  return me;
}

/// 发现页转盘队列状态, 当地点, 饭点或场景变化时重新请求推荐美食店.
///
/// 抽屉分类切换不影响转盘, 转盘固定推荐美食 ([ShopKind.food]).
@Riverpod(keepAlive: true)
class TurntableQueue extends _$TurntableQueue {
  /// 一批的家数, 即舞台左下角的圆点数.
  static const batchSize = 8;

  /// 剩余店铺不多于该数量时预取下一批.
  static const _prefetch = 3;

  /// 队列版本号, 每次重置首屏请求时递增; 若预取完成时版本号已变化, 则丢弃过期的预取结果.
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
  /// 换到另一家时记一次 `dish_shuffle`.
  void select(int index) {
    final feed = state.value;
    if (feed == null || feed.shops.isEmpty) return;
    final wrapped = index >= feed.shops.length
        ? 0
        : index.clamp(0, feed.shops.length - 1);
    if (wrapped != feed.index) {
      ref.read(analyticsProvider).track(const DishShuffleEvent());
    }
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

  /// 从队列中移除指定店铺 (用于 "不想去这家" 操作), 若移除后队列为空则重新请求首屏批次.
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
      // 请求期间队列可能发生过移除操作, 因此基于当前最新列表追加.
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

  /// 从当前列表中移除指定店铺, 用于 "不想去这家" 操作.
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

/// 标记屏蔽 [shopId], 30 天内不再推荐, 成功后将其从转盘与抽屉列表中移除.
///
/// 请求失败时抛出 [AppFailure], 由调用页面负责提示.
Future<void> dismissShop(WidgetRef ref, int shopId) async {
  await ref.read(recommendRepositoryProvider).dismiss(shopId);
  ref.read(turntableQueueProvider.notifier).remove(shopId);
  for (final kind in ShopKind.values) {
    final list = discoverShopsProvider(kind);
    if (ref.exists(list)) ref.read(list.notifier).remove(shopId);
  }
}
