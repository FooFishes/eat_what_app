import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_activity_food_dto.freezed.dart';
part 'create_activity_food_dto.g.dart';

@freezed
abstract class CreateActivityFoodDTO with _$CreateActivityFoodDTO {
  const factory CreateActivityFoodDTO({
    required String foodName,
    String? description,
    required int provinceId,
    required int cityId,
    required List<String> pictureUrl,
  }) = _CreateActivityFoodDTO;

  factory CreateActivityFoodDTO.fromJson(Map<String, dynamic> json) =>
      _$CreateActivityFoodDTOFromJson(json);
}
