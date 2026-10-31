import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dish_interactions.g.dart';

/// 一道菜的赞和收藏现在是什么样。
class const DishInteraction({
  required final bool liked,
  required final int likes,
  required final bool favorite,
}) {
  factory DishInteraction.of(Dish dish) => DishInteraction(
    liked: dish.liked,
    likes: dish.likes,
    favorite: dish.favorite,
  );
}

/// 赞和收藏的本地覆盖值，按菜 id（技术架构 4.3 乐观更新）。
///
/// 点了先改这里，转盘、方块、详情里同一道菜一起变；请求失败退回原值，由页面给一句提示。
/// 拉到这道菜的最新详情时清掉覆盖值，换了账号全部清空。
@Riverpod(keepAlive: true)
class DishInteractions extends _$DishInteractions {
  @override
  Map<int, DishInteraction> build() {
    ref.watch(sessionProvider.select((s) => s is SignedIn));
    return const {};
  }

  DishInteraction of(Dish dish) => state[dish.id] ?? DishInteraction.of(dish);

  /// 赞或取消赞。失败时退回，返回失败原因；成功返回 null。
  Future<AppFailure?> toggleLike(Dish dish) async {
    final before = of(dish);
    final liked = !before.liked;
    _set(
      dish.id,
      DishInteraction(
        liked: liked,
        likes: (before.likes + (liked ? 1 : -1)).clamp(0, 1 << 31),
        favorite: before.favorite,
      ),
    );
    try {
      await ref.read(foodRepositoryProvider).setLiked(dish.id, liked: liked);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) _set(dish.id, before);
      return e;
    }
  }

  Future<AppFailure?> toggleFavorite(Dish dish) async {
    final before = of(dish);
    final favorite = !before.favorite;
    _set(
      dish.id,
      DishInteraction(
        liked: before.liked,
        likes: before.likes,
        favorite: favorite,
      ),
    );
    try {
      await ref
          .read(foodRepositoryProvider)
          .setFavorite(dish.id, favorite: favorite);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) _set(dish.id, before);
      return e;
    }
  }

  /// 拿到了服务端的最新数据，不再需要覆盖。
  void forget(int dishId) {
    if (!state.containsKey(dishId)) return;
    state = {...state}..remove(dishId);
  }

  void _set(int id, DishInteraction value) => state = {...state, id: value};
}
