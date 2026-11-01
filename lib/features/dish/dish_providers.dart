import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/state/dish_interactions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dish_providers.g.dart';

/// 菜品详情。拿到最新的就清掉赞和收藏的本地覆盖；拿不到时用 7 天内看过的缓存（技术架构 10.1）。
@riverpod
Future<Dish> dishDetail(Ref ref, int dishId) async {
  ref.cacheFor(const Duration(minutes: 5));
  final repo = ref.watch(foodRepositoryProvider);
  try {
    final dish = await repo.detail(dishId, cancelToken: ref.cancelToken());
    ref.read(dishInteractionsProvider.notifier).forget(dishId);
    return dish;
  } on AppFailure catch (e) {
    if (e.kind != FailureKind.network) rethrow;
    final cached = await repo.cachedDetail(dishId);
    if (cached == null) rethrow;
    return cached;
  }
}

/// 一道菜的口味标签和我的标签，打标签、撤回时先改这里（乐观更新），失败退回。
class const DishTags({
  required final List<TasteTag> taste,
  required final List<MyTag> mine,
});

@riverpod
class DishTagsOf extends _$DishTagsOf {
  @override
  DishTags? build(int dishId) {
    final dish = ref.watch(dishDetailProvider(dishId)).value;
    if (dish == null) return null;
    return DishTags(taste: dish.tasteTags, mine: dish.myTags);
  }

  /// 点「大家怎么说」里的一个词：没打过就打上，打过就撤回。失败返回原因。
  Future<AppFailure?> toggleTaste(TasteTag tag) async {
    final before = state;
    if (before == null) return null;
    final mine = before.taste.any((t) => t.id == tag.id && t.mine);
    state = DishTags(
      taste: _withTaste(before.taste, tag, mine: !mine),
      mine: before.mine,
    );
    try {
      final repo = ref.read(foodRepositoryProvider);
      if (mine) {
        await repo.removeTag(dishId, tag.id);
      } else {
        await repo.addTasteTags(dishId, [tag.id]);
      }
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = before;
      return e;
    }
  }

  /// 加标签面板点「完成」：口味词按选中的增删，自己写的加进我的标签。改完从服务端拉一遍。
  Future<AppFailure?> apply({
    required Set<int> taste,
    required List<String> newMine,
  }) async {
    final before = state;
    if (before == null) return null;
    final had = {
      for (final t in before.taste)
        if (t.mine) t.id,
    };
    final add = taste.difference(had).toList();
    final remove = had.difference(taste);
    final repo = ref.read(foodRepositoryProvider);
    try {
      if (add.isNotEmpty) await repo.addTasteTags(dishId, add);
      for (final id in remove) {
        await repo.removeTag(dishId, id);
      }
      if (newMine.isNotEmpty) await repo.addMyTags(dishId, newMine);
      final fresh = await repo.tagsOf(dishId);
      if (ref.mounted) state = DishTags(taste: fresh.taste, mine: fresh.mine);
      return null;
    } on AppFailure catch (e) {
      return e;
    }
  }

  static List<TasteTag> _withTaste(
    List<TasteTag> tags,
    TasteTag tag, {
    required bool mine,
  }) {
    final result = <TasteTag>[];
    var found = false;
    for (final t in tags) {
      if (t.id == tag.id) {
        found = true;
        final count = (t.count + (mine ? 1 : -1)).clamp(0, 1 << 31);
        if (count > 0) {
          result.add(
            TasteTag(id: t.id, name: t.name, count: count, mine: mine),
          );
        }
      } else {
        result.add(t);
      }
    }
    if (!found && mine) {
      result.add(TasteTag(id: tag.id, name: tag.name, count: 1, mine: true));
    }
    return result..sort((a, b) => b.count.compareTo(a.count));
  }
}
