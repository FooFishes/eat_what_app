import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dish_interactions.g.dart';

/// 一道菜当前的赞, 收藏和评分状态.
class const DishInteraction({
  required final bool liked,
  required final int likes,
  required final bool favorite,
  final DishRating rating = const DishRating(),

  /// 当前用户打的分 (1–5), 没打过分时为 null.
  final int? myRating,
}) {
  factory DishInteraction.of(Dish dish) => DishInteraction(
    liked: dish.liked,
    likes: dish.likes,
    favorite: dish.favorite,
    rating: dish.rating,
    myRating: dish.myRating,
  );
}

/// 赞, 收藏和评分的本地覆盖值, 以菜品 id 为键, 用于乐观更新.
///
/// - 点击后先修改覆盖值, 转盘, 方块和详情中的同一道菜同步变化.
/// - 请求失败时恢复原值, 由页面显示提示.
/// - 获取到该菜的最新详情时清除覆盖值.
/// - 切换账号时全部清空.
@Riverpod(keepAlive: true)
class DishInteractions extends _$DishInteractions {
  @override
  Map<int, DishInteraction> build() {
    ref.watch(sessionProvider.select((s) => s is SignedIn));
    return const {};
  }

  DishInteraction of(Dish dish) => state[dish.id] ?? DishInteraction.of(dish);

  /// 切换赞的状态. 成功返回 null; 失败时恢复原值并返回失败原因.
  Future<AppFailure?> toggleLike(Dish dish) async {
    final before = of(dish);
    final liked = !before.liked;
    _set(
      dish.id,
      DishInteraction(
        liked: liked,
        likes: (before.likes + (liked ? 1 : -1)).clamp(0, 1 << 31),
        favorite: before.favorite,
        rating: before.rating,
        myRating: before.myRating,
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
        rating: before.rating,
        myRating: before.myRating,
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

  /// 给菜打 [score] 分, [score] 为 null 时撤销. 成功返回 null; 失败时恢复原值并返回失败原因.
  ///
  /// 先改本地的 "我的评分", 平均分和人数等服务端返回后再更新.
  Future<AppFailure?> rate(Dish dish, int? score) async {
    final before = of(dish);
    _set(dish.id, _withRating(before, before.rating, score));
    try {
      final rated = await ref.read(foodRepositoryProvider).rate(dish.id, score);
      if (ref.mounted) {
        _set(dish.id, _withRating(of(dish), rated.rating, rated.myRating));
      }
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) _set(dish.id, before);
      return e;
    }
  }

  static DishInteraction _withRating(
    DishInteraction value,
    DishRating rating,
    int? myRating,
  ) => DishInteraction(
    liked: value.liked,
    likes: value.likes,
    favorite: value.favorite,
    rating: rating,
    myRating: myRating,
  );

  /// 清除 [dishId] 的覆盖值. 获取到服务端的最新数据后调用.
  void forget(int dishId) {
    if (!state.containsKey(dishId)) return;
    state = {...state}..remove(dishId);
  }

  void _set(int id, DishInteraction value) => state = {...state, id: value};
}
