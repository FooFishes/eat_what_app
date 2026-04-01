import 'package:eat_what_app/features/restaurant/data/models/restaurant.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'restaurant_search_state.freezed.dart';

@freezed
abstract class RestaurantSearchState with _$RestaurantSearchState {
  const factory RestaurantSearchState({
    @Default(false) bool isLoadingHint,
    @Default(false) bool shouldShowIntroHint,
    @Default(false) bool isSearching,
    @Default('') String keyword,
    @Default([]) List<Restaurant> results,
    @Default(false) bool hasSearched,
  }) = _RestaurantSearchState;
}
