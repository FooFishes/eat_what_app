import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_food_dto.freezed.dart';
part 'activity_food_dto.g.dart';

@freezed
abstract class ActivityFoodDto with _$ActivityFoodDto {
  const factory ActivityFoodDto({
    required int id,
    required int accountId,
    required String foodName,
    required String description,
    required int provinceId,
    required int cityId,
    required List<String> pictureUrl,
    required int likesCount,
    required bool isLiked,
    required int createdAt,
    required int updatedAt,
    required String uploaderName,
  }) = _ActivityFoodDto;

  factory ActivityFoodDto.fromJson(Map<String, dynamic> json) =>
      _$ActivityFoodDtoFromJson(json);
}
