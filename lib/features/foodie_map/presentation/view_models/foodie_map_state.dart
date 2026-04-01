import 'package:eat_what_app/features/foodie_map/data/models/regional_food.dart';
import 'package:eat_what_app/shared/location/data/models/province_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'foodie_map_state.freezed.dart';

enum FoodieMapFeedbackKind { warning, error }

@freezed
abstract class FoodieMapFeedback with _$FoodieMapFeedback {
  const factory FoodieMapFeedback({
    required int id,
    required FoodieMapFeedbackKind kind,
    required String content,
  }) = _FoodieMapFeedback;
}

@freezed
abstract class FoodieMapPageState with _$FoodieMapPageState {
  const factory FoodieMapPageState({
    @Default(true) bool isInitialLoading,
    @Default(false) bool isLoadingProvinces,
    @Default(false) bool hasProvincesError,
    int? localProvinceId,
    @Default([]) List<ProvinceResponse> provinces,
    int? selectedProvinceId,
    int? committedProvinceId,
    FoodieMapFeedback? feedback,
  }) = _FoodieMapPageState;
}

@freezed
abstract class FoodieMapFoodListState with _$FoodieMapFoodListState {
  const factory FoodieMapFoodListState({
    @Default([]) List<RegionalFood> foods,
    @Default(true) bool isLoading,
    @Default(false) bool hasError,
    @Default(true) bool hasNext,
    @Default(0) int currentPage,
    @Default({}) Set<int> pendingLikeIds,
    FoodieMapFeedback? feedback,
  }) = _FoodieMapFoodListState;
}
