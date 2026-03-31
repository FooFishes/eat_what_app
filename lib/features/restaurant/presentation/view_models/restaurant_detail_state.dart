import 'package:eat_what_app/features/restaurant/data/models/restaurant.dart';
import 'package:eat_what_app/shared/food/data/models/food_vo.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'restaurant_detail_state.freezed.dart';

@freezed
abstract class RestaurantDetailState with _$RestaurantDetailState {
  const factory RestaurantDetailState({
    Restaurant? restaurant,
    @Default([]) List<FoodVO> foods,
    @Default(true) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasNext,
    @Default(1) int currentPage,
    Object? error,
  }) = _RestaurantDetailState;
}
