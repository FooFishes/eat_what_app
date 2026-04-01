import 'package:eat_what_app/core/network/models/api_response.dart';
import 'package:eat_what_app/features/restaurant/data/models/restaurant.dart';
import 'package:eat_what_app/features/restaurant/presentation/view_models/restaurant_detail_state.dart';
import 'package:eat_what_app/features/restaurant/providers.dart';
import 'package:eat_what_app/shared/food/data/models/food_vo.dart';
import 'package:eat_what_app/shared/food/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restaurant_detail_view_model.g.dart';

@riverpod
class RestaurantDetailViewModel extends _$RestaurantDetailViewModel {
  @override
  RestaurantDetailState build(int restaurantId) {
    Future<void>.microtask(loadInitial);
    return const RestaurantDetailState();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait<Object?>([
        ref
            .read(restaurantRepositoryProvider)
            .getRestaurantDetail(restaurantId),
        ref
            .read(foodRepositoryProvider)
            .getFoodsByRestaurant(restaurantId, page: 1, pageSize: 20),
      ]);
      final restaurant = results[0] as Restaurant;
      final foodsPage = results[1] as PaginatedData<FoodVO>;
      state = state.copyWith(
        restaurant: restaurant,
        foods: foodsPage.items,
        hasNext: foodsPage.hasNext,
        currentPage: 1,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasNext) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final foodsPage = await ref
          .read(foodRepositoryProvider)
          .getFoodsByRestaurant(restaurantId, page: nextPage, pageSize: 20);
      state = state.copyWith(
        foods: [...state.foods, ...foodsPage.items],
        currentPage: nextPage,
        hasNext: foodsPage.hasNext,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false);
      rethrow;
    }
  }

  Future<void> toggleFavorite(FoodVO food) async {
    final original = food;
    final nextFavorite = !food.isFavorite;
    final nextLikes = nextFavorite ? food.likesCount + 1 : food.likesCount - 1;

    state = state.copyWith(
      foods: state.foods.map((item) {
        if (item.id != food.id) {
          return item;
        }
        return _copyFood(
          item,
          isFavorite: nextFavorite,
          likesCount: nextLikes < 0 ? 0 : nextLikes,
        );
      }).toList(),
    );

    try {
      if (nextFavorite) {
        await ref.read(foodRepositoryProvider).favoriteFood(food.id);
      } else {
        await ref.read(foodRepositoryProvider).unfavoriteFood(food.id);
      }
    } catch (error) {
      state = state.copyWith(
        foods: state.foods.map((item) {
          if (item.id != food.id) {
            return item;
          }
          return original;
        }).toList(),
      );
      rethrow;
    }
  }

  FoodVO _copyFood(FoodVO food, {bool? isFavorite, int? likesCount}) {
    return FoodVO(
      id: food.id,
      accountId: food.accountId,
      uploaderName: food.uploaderName,
      restaurantId: food.restaurantId,
      name: food.name,
      description: food.description,
      price: food.price,
      category: food.category,
      pictureUrl: food.pictureUrl,
      systemTags: food.systemTags,
      myCustomTags: food.myCustomTags,
      isFavorite: isFavorite ?? food.isFavorite,
      likesCount: likesCount ?? food.likesCount,
      createdAt: food.createdAt,
      updatedAt: food.updatedAt,
    );
  }
}
