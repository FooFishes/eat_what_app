import 'package:eat_what_app/model/activity/activity_food_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_result_activity_food_dto.freezed.dart';
part 'page_result_activity_food_dto.g.dart';

@freezed
abstract class PageResultActivityFoodDto with _$PageResultActivityFoodDto {
  const factory PageResultActivityFoodDto({
    required int currentPage,
    required List<ActivityFoodDto> items,
    required int totalPages,
    required int totalItems,
    required bool hasNext,
  }) = _PageResultActivityFoodDto;

  factory PageResultActivityFoodDto.fromJson(Map<String, dynamic> json) =>
      _$PageResultActivityFoodDtoFromJson(json);
}
