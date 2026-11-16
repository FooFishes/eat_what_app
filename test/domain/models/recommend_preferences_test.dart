import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/recommend_preferences.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('喜欢一个忌口的口味时从忌口里去掉，反过来也一样', () {
    const start = RecommendPreferences(dislikedTastes: {Taste.spicy});

    final liked = start.toggleLiked(Taste.spicy);
    expect(liked.likedTastes, {Taste.spicy});
    expect(liked.dislikedTastes, isEmpty);

    final disliked = liked.toggleDisliked(Taste.spicy);
    expect(disliked.dislikedTastes, {Taste.spicy});
    expect(disliked.likedTastes, isEmpty);
  });

  test('再点一次取消选中，不影响另一边', () {
    const start = RecommendPreferences(
      likedTastes: {Taste.sweet},
      dislikedTastes: {Taste.numbing},
    );

    final next = start.toggleLiked(Taste.sweet);
    expect(next.likedTastes, isEmpty);
    expect(next.dislikedTastes, {Taste.numbing});
    expect(start.toggleCategory(ShopCategory.soup).likedCategories, {
      ShopCategory.soup,
    });
  });

  test('价位和距离可以改回不限', () {
    const start = RecommendPreferences(
      priceBand: PriceBand.over30,
      maxDistance: 1000,
    );

    expect(start.withPriceBand(null).priceBand, isNull);
    expect(start.withMaxDistance(null).maxDistance, isNull);
    expect(start.withPriceBand(null).maxDistance, 1000);
    expect(start.withPriceBand(null).withMaxDistance(null).isEmpty, isTrue);
  });

  test('相等只看内容，不看集合顺序', () {
    const a = RecommendPreferences(
      likedCategories: {ShopCategory.rice, ShopCategory.noodles},
      maxDistance: 500,
    );
    const b = RecommendPreferences(
      likedCategories: {ShopCategory.noodles, ShopCategory.rice},
      maxDistance: 500,
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == a.withMaxDistance(1000), isFalse);
    expect(
      const RecommendPreferences()
          .toggleLiked(Taste.sour)
          .toggleLiked(Taste.sour),
      const RecommendPreferences(),
    );
  });
}
