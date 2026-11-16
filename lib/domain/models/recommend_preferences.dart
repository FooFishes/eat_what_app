import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/taste.dart';

/// 用户自己填的推荐偏好. 喜欢的品类和口味只给店铺加分, 忌口的店铺不会被推荐.
///
/// 同一个口味不能既喜欢又忌口, [toggleLiked] 和 [toggleDisliked] 选中一边时会从另一边移除.
/// 价位和最远距离为 null 表示不限; 最远距离只影响堂食推荐.
class const RecommendPreferences({
  final Set<ShopCategory> likedCategories = const {},
  final Set<Taste> likedTastes = const {},
  final Set<Taste> dislikedTastes = const {},
  final PriceBand? priceBand,
  final int? maxDistance,
}) {
  /// 后端接受的最远距离范围, 单位为米.
  static const minDistance = 100;
  static const maxDistanceLimit = 20000;

  /// 页面上可选的最远距离, 单位为米.
  static const distanceChoices = [500, 1000, 2000, 3000, 5000];

  bool get isEmpty =>
      likedCategories.isEmpty &&
      likedTastes.isEmpty &&
      dislikedTastes.isEmpty &&
      priceBand == null &&
      maxDistance == null;

  RecommendPreferences toggleCategory(ShopCategory category) =>
      _copy(likedCategories: _toggle(likedCategories, category));

  RecommendPreferences toggleLiked(Taste taste) {
    final liked = _toggle(likedTastes, taste);
    return _copy(
      likedTastes: liked,
      dislikedTastes: liked.contains(taste)
          ? ({...dislikedTastes}..remove(taste))
          : dislikedTastes,
    );
  }

  RecommendPreferences toggleDisliked(Taste taste) {
    final disliked = _toggle(dislikedTastes, taste);
    return _copy(
      dislikedTastes: disliked,
      likedTastes: disliked.contains(taste)
          ? ({...likedTastes}..remove(taste))
          : likedTastes,
    );
  }

  RecommendPreferences withPriceBand(PriceBand? band) => RecommendPreferences(
    likedCategories: likedCategories,
    likedTastes: likedTastes,
    dislikedTastes: dislikedTastes,
    priceBand: band,
    maxDistance: maxDistance,
  );

  RecommendPreferences withMaxDistance(int? meters) => RecommendPreferences(
    likedCategories: likedCategories,
    likedTastes: likedTastes,
    dislikedTastes: dislikedTastes,
    priceBand: priceBand,
    maxDistance: meters,
  );

  RecommendPreferences _copy({
    Set<ShopCategory>? likedCategories,
    Set<Taste>? likedTastes,
    Set<Taste>? dislikedTastes,
  }) => RecommendPreferences(
    likedCategories: likedCategories ?? this.likedCategories,
    likedTastes: likedTastes ?? this.likedTastes,
    dislikedTastes: dislikedTastes ?? this.dislikedTastes,
    priceBand: priceBand,
    maxDistance: maxDistance,
  );

  static Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  bool operator ==(Object other) =>
      other is RecommendPreferences &&
      _sameSet(other.likedCategories, likedCategories) &&
      _sameSet(other.likedTastes, likedTastes) &&
      _sameSet(other.dislikedTastes, dislikedTastes) &&
      other.priceBand == priceBand &&
      other.maxDistance == maxDistance;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(likedCategories),
    Object.hashAllUnordered(likedTastes),
    Object.hashAllUnordered(dislikedTastes),
    priceBand,
    maxDistance,
  );

  static bool _sameSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}

/// 推荐偏好里可选的品类, 口味和可设为忌口的口味, 按服务端给出的顺序排列, 客户端不认识的值已丢弃.
class const RecommendOptions({
  required final List<ShopCategory> categories,
  required final List<Taste> tastes,
  required final List<Taste> dislikable,
}) {
  /// 取不到服务端可选值时使用的客户端枚举.
  static final fallback = RecommendOptions(
    categories: ShopCategory.values,
    tastes: Taste.values,
    dislikable: [
      for (final taste in Taste.values)
        if (Taste.dislikable.contains(taste)) taste,
    ],
  );
}

/// 服务端从点赞, 收藏和店铺评价里推断出的偏爱口味和品类, 推荐时与用户自己填的喜欢一起加分.
///
/// 只读, 用户不能直接修改; 忌口的口味不会被推断为喜欢.
class const TasteProfile({
  final List<Taste> inferredTastes = const [],
  final List<ShopCategory> inferredCategories = const [],
}) {
  bool get isEmpty => inferredTastes.isEmpty && inferredCategories.isEmpty;
}
