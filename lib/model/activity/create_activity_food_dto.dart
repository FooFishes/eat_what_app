import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_activity_food_dto.freezed.dart';
part 'create_activity_food_dto.g.dart';

@freezed
abstract class CreateActivityFoodDto with _$CreateActivityFoodDto {
  const factory CreateActivityFoodDto({
    required String foodName,
    String? description,
    required int provinceId,
    required int cityId,
    required List<String> pictureUrl,
  }) = _CreateActivityFoodDto;

  factory CreateActivityFoodDto.fromJson(Map<String, dynamic> json) =>
      _$CreateActivityFoodDtoFromJson(json);
}