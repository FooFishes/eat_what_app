import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/topic/topic_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/topic.dart';
import 'package:eat/state/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discover_providers.g.dart';

/// 转盘数据: 按批次追加的推荐队列, 以及当前所在的位置.
class const TurntableFeed({
  required final List<Dish> dishes,
  final int index = 0,

  /// 每一批在队列中的起始下标, 用于计算舞台左下角的批次圆点.
  final List<int> batchStarts = const [0],

  /// 是否还有下一批. 获取到空批次即视为没有.
  ///
  /// 没有下一批时, 在最后一道点击 "换一个" 回到第一道.
  final bool hasMore = true,

  /// 推荐请求失败, 当前显示的是该校区和饭点上一次获取的批次.
  final bool stale = false,
}) {
  Dish? get current => dishes.isEmpty ? null : dishes[index];

  /// 当前菜品所在批次的范围.
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

/// 发现页的转盘队列. 地点或饭点变化时重新请求.
@Riverpod(keepAlive: true)
class TurntableQueue extends _$TurntableQueue {
  /// 剩余菜品不多于该数量时预取下一批.
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

  /// 转到第 [index] 道. 拖动松手和点击 "换一个" 都调用此方法.
  ///
  /// [index] 超过最后一道时回到第一道.
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
      // 预取失败不中断浏览: 转到最后一道时回到第一道, 之后切换菜品时再次预取.
    } finally {
      _loading = false;
    }
  }
}

/// 当前校区的当期专题, 没有时为 null. 切换校区后重新请求, 回到前台时由页面刷新.
///
/// 分类栏只在有当期专题时显示专题. 请求失败时页面按没有专题处理, 不影响推荐.
@Riverpod(keepAlive: true)
Future<Topic?> currentTopic(Ref ref) async {
  final (:campusId, :ready) = ref.watch(
    currentPlaceProvider.select(
      (p) => (campusId: p.campus?.id, ready: p.ready),
    ),
  );
  if (!ready) return Completer<Topic?>().future;
  if (campusId == null) return null;
  return ref
      .watch(topicRepositoryProvider)
      .current(campusId, cancelToken: ref.cancelToken());
}

/// 分类栏选中专题时抽屉中的专题详情. 专题已撤下或尚未开始时为 null.
@riverpod
Future<TopicDetail?> discoverTopic(Ref ref, int topicId) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    return await ref
        .watch(topicRepositoryProvider)
        .detail(topicId, cancelToken: ref.cancelToken());
  } on AppFailure catch (e) {
    if (e.code == BizCodes.stateNotAllowed) return null;
    rethrow;
  }
}

/// 抽屉中一个分类的推荐流, 向下滚动时按批次追加. 分类为 `null` 表示 "今日推荐".
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
