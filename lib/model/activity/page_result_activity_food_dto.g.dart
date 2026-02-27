// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_result_activity_food_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PageResultActivityFoodDto _$PageResultActivityFoodDtoFromJson(
  Map<String, dynamic> json,
) => _PageResultActivityFoodDto(
  currentPage: (json['currentPage'] as num).toInt(),
  items: (json['items'] as List<dynamic>)
      .map((e) => ActivityFoodDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalPages: (json['totalPages'] as num).toInt(),
  totalItems: (json['totalItems'] as num).toInt(),
  hasNext: json['hasNext'] as bool,
);

Map<String, dynamic> _$PageResultActivityFoodDtoToJson(
  _PageResultActivityFoodDto instance,
) => <String, dynamic>{
  'currentPage': instance.currentPage,
  'items': instance.items,
  'totalPages': instance.totalPages,
  'totalItems': instance.totalItems,
  'hasNext': instance.hasNext,
};
