import 'package:eat_what_app/shared/food/data/models/food_tag_summary_vo.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_food_state.freezed.dart';

@freezed
abstract class AddFoodState with _$AddFoodState {
  const factory AddFoodState({
    @Default(true) bool isLoadingTags,
    @Default(false) bool isSubmitting,
    @Default([]) List<FoodTagSummaryVO> systemTags,
  }) = _AddFoodState;
}
