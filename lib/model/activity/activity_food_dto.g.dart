// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_food_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityFoodDto _$ActivityFoodDtoFromJson(Map<String, dynamic> json) =>
    _ActivityFoodDto(
      id: (json['id'] as num).toInt(),
      accountId: (json['accountId'] as num).toInt(),
      foodName: json['foodName'] as String,
      description: json['description'] as String,
      provinceId: (json['provinceId'] as num).toInt(),
      cityId: (json['cityId'] as num).toInt(),
      pictureUrl: (json['pictureUrl'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      likesCount: (json['likesCount'] as num).toInt(),
      isLiked: json['isLiked'] as bool,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
      uploaderName: json['uploaderName'] as String,
    );

Map<String, dynamic> _$ActivityFoodDtoToJson(_ActivityFoodDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountId': instance.accountId,
      'foodName': instance.foodName,
      'description': instance.description,
      'provinceId': instance.provinceId,
      'cityId': instance.cityId,
      'pictureUrl': instance.pictureUrl,
      'likesCount': instance.likesCount,
      'isLiked': instance.isLiked,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'uploaderName': instance.uploaderName,
    };
