import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/state/place.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discover_providers.g.dart';

/// 转盘：一批一批往后接的推荐队列，和当前转到第几道。
class const TurntableFeed({
  required final List<Dish> dishes,
  final int index = 0,

  /// 每一批从队列的第几道开始，算舞台左下的小圆点用。
  final List<int> batchStarts = const [0],

  /// 后面还有没有新的一批。拿到空的一批就算没有了，转到最后一道再「换一个」回到第一道。
  final bool hasMore = true,

  /// 推荐拿不到，显示的是这个校区和饭点上一次的那批（产品 12.6）。
  final bool stale = false,
}) {
  Dish? get current => dishes.isEmpty ? null : dishes[index];

  /// 当前这道所在那一批的范围。
  ({int start, int length}) get batch {
    var start = 0;
    var end = dishes.length;
    for (final (i, s) in batchStarts.indexed) {
      if (s <= index) {
        start = s;
        end = i + 1 < batchStarts.length ? batchStarts[i + 1] : dishes.length;
      }
    }
    return (start: start, length: end - start);
  }
}

/// 发现页的转盘。地点或饭点一变就重新拉（产品 6.4「选完立即刷新转盘和列表」）。
@Riverpod(keepAlive: true)
class TurntableQueue extends _$TurntableQueue {
  /// 剩下不到这么多道时预取下一批。
  static const _prefetch = 3;

  @override
  Future<TurntableFeed> build() async {
    final place = ref.watch(currentPlaceProvider);
    if (!place.ready) return Completer<TurntableFeed>().future;
    final repo = ref.watch(foodRepositoryProvider);
    try {
      final dishes = await repo.recommend(
        campusId: place.campus?.id,
        meal: place.meal,
        cancelToken: ref.cancelToken(),
      );
      return TurntableFeed(dishes: dishes, hasMore: dishes.isNotEmpty);
    } on AppFailure catch (e) {
      if (e.kind == FailureKind.cancelled) rethrow;
      final last = await repo.lastBatch(
        campusId: place.campus?.id,
        meal: place.meal,
      );
      if (last.isEmpty) rethrow;
      return TurntableFeed(dishes: last, hasMore: false, stale: true);
    }
  }

  var _loading = false;

  /// 转到第 [index] 道（拖动松手、「换一个」都走这里）。越过最后一道回到第一道。
  void select(int index) {
    final feed = state.value;
    if (feed == null || feed.dishes.isEmpty) return;
    final wrapped = index >= feed.dishes.length
        ? 0
        : index.clamp(0, feed.dishes.length - 1);
    state = AsyncData(
      TurntableFeed(
        dishes: feed.dishes,
        index: wrapped,
        batchStarts: feed.batchStarts,
        hasMore: feed.hasMore,
        stale: feed.stale,
      ),
    );
    if (feed.hasMore && feed.dishes.length - wrapped <= _prefetch) {
      _loadMore();
    }
  }

  void next() {
    final feed = state.value;
    if (feed != null) select(feed.index + 1);
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    _loading = true;
    final place = ref.read(currentPlaceProvider);
    try {
      final more = await ref
          .read(foodRepositoryProvider)
          .recommend(campusId: place.campus?.id, meal: place.meal);
      final feed = state.value;
      if (!ref.mounted || feed == null) return;
      final known = {for (final d in feed.dishes) d.id};
      final fresh = [
        for (final d in more)
          if (!known.contains(d.id)) d,
      ];
      state = AsyncData(
        TurntableFeed(
          dishes: [...feed.dishes, ...fresh],
          index: feed.index,
          batchStarts: fresh.isEmpty
              ? feed.batchStarts
              : [...feed.batchStarts, feed.dishes.length],
          hasMore: fresh.isNotEmpty,
          stale: feed.stale,
        ),
      );
    } on AppFailure {
      // 预取失败不打断，转到最后一道时回到第一道；下次再试。
    } finally {
      _loading = false;
    }
  }
}

/// 抽屉里一个分类的推荐流：往下滑一批一批地接（`null` 是「今日推荐」）。
class const DishFeed({
  required final List<Dish> dishes,
  final bool hasMore = true,
  final bool loadingMore = false,
  final AppFailure? moreError,
});

@riverpod
class DiscoverList extends _$DiscoverList {
  @override
  Future<DishFeed> build(DishCategory? category) async {
    final place = ref.watch(currentPlaceProvider);
    if (!place.ready) return Completer<DishFeed>().future;
    final dishes = await ref
        .watch(foodRepositoryProvider)
        .recommend(
          campusId: place.campus?.id,
          meal: place.meal,
          category: category,
          cancelToken: ref.cancelToken(),
        );
    return DishFeed(dishes: dishes, hasMore: dishes.isNotEmpty);
  }

  Future<void> loadMore() async {
    final feed = state.value;
    if (feed == null || !feed.hasMore || feed.loadingMore) return;
    state = AsyncData(DishFeed(dishes: feed.dishes, loadingMore: true));
    final place = ref.read(currentPlaceProvider);
    try {
      final more = await ref
          .read(foodRepositoryProvider)
          .recommend(
            campusId: place.campus?.id,
            meal: place.meal,
            category: category,
          );
      if (!ref.mounted) return;
      final known = {for (final d in feed.dishes) d.id};
      final fresh = [
        for (final d in more)
          if (!known.contains(d.id)) d,
      ];
      state = AsyncData(
        DishFeed(dishes: [...feed.dishes, ...fresh], hasMore: fresh.isNotEmpty),
      );
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(DishFeed(dishes: feed.dishes, moreError: e));
    }
  }
}
