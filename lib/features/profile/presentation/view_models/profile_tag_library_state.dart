import 'package:eat_what_app/shared/food/data/models/food_tag_summary_vo.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_tag_library_state.freezed.dart';

@freezed
abstract class ProfileTagLibraryState with _$ProfileTagLibraryState {
  const factory ProfileTagLibraryState({
    @Default(true) bool isLoading,
    @Default([]) List<FoodTagSummaryVO> systemTags,
    @Default([]) List<FoodTagSummaryVO> customTags,
    Object? error,
  }) = _ProfileTagLibraryState;
}
