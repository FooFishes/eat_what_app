// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_activity_food_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateActivityFoodDTO _$CreateActivityFoodDTOFromJson(
  Map<String, dynamic> json,
) => _CreateActivityFoodDTO(
  foodName: json['foodName'] as String,
  description: json['description'] as String?,
  provinceId: (json['provinceId'] as num).toInt(),
  cityId: (json['cityId'] as num).toInt(),
  pictureUrl: (json['pictureUrl'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CreateActivityFoodDTOToJson(
  _CreateActivityFoodDTO instance,
) => <String, dynamic>{
  'foodName': instance.foodName,
  'description': instance.description,
  'provinceId': instance.provinceId,
  'cityId': instance.cityId,
  'pictureUrl': instance.pictureUrl,
};
