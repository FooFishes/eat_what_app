// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodDto _$FoodDtoFromJson(Map<String, dynamic> json) => FoodDto(
  id: (json['id'] as num?)?.toInt(),
  accountId: (json['accountId'] as num?)?.toInt(),
  uploaderName: json['uploaderName'] as String?,
  restaurantId: (json['restaurantId'] as num?)?.toInt(),
  restaurantName: json['restaurantName'] as String?,
  distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
  restaurantAddress: json['restaurantAddress'] as String?,
  restaurantGcjLng: (json['restaurantGcjLng'] as num?)?.toDouble(),
  restaurantGcjLat: (json['restaurantGcjLat'] as num?)?.toDouble(),
  hubId: (json['hubId'] as num?)?.toInt(),
  hubName: json['hubName'] as String?,
  name: json['name'] as String?,
  description: json['description'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  category: json['category'] as String?,
  pictureUrl: (json['pictureUrl'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  pictureKeys: (json['pictureKeys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  systemTags: (json['systemTags'] as List<dynamic>?)
      ?.map((e) => FoodTagDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  myCustomTags: (json['myCustomTags'] as List<dynamic>?)
      ?.map((e) => FoodTagDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  isLiked: json['isLiked'] as bool?,
  isFavorite: json['isFavorite'] as bool?,
  likesCount: (json['likesCount'] as num?)?.toInt(),
  mealTimes: (json['mealTimes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  stageColor: json['stageColor'] as String?,
  stageAlternates: (json['stageAlternates'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  coverCrop: json['coverCrop'] == null
      ? null
      : CoverCropDto.fromJson(json['coverCrop'] as Map<String, dynamic>),
  createdAt: (json['createdAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$FoodDtoToJson(FoodDto instance) => <String, dynamic>{
  'id': ?instance.id,
  'accountId': ?instance.accountId,
  'uploaderName': ?instance.uploaderName,
  'restaurantId': ?instance.restaurantId,
  'restaurantName': ?instance.restaurantName,
  'distanceMeters': ?instance.distanceMeters,
  'restaurantAddress': ?instance.restaurantAddress,
  'restaurantGcjLng': ?instance.restaurantGcjLng,
  'restaurantGcjLat': ?instance.restaurantGcjLat,
  'hubId': ?instance.hubId,
  'hubName': ?instance.hubName,
  'name': ?instance.name,
  'description': ?instance.description,
  'price': ?instance.price,
  'category': ?instance.category,
  'pictureUrl': ?instance.pictureUrl,
  'pictureKeys': instance.pictureKeys,
  'systemTags': ?instance.systemTags,
  'myCustomTags': ?instance.myCustomTags,
  'isLiked': ?instance.isLiked,
  'isFavorite': ?instance.isFavorite,
  'likesCount': ?instance.likesCount,
  'mealTimes': ?instance.mealTimes,
  'stageColor': ?instance.stageColor,
  'stageAlternates': ?instance.stageAlternates,
  'coverCrop': ?instance.coverCrop,
  'createdAt': ?instance.createdAt,
};

FoodTagDto _$FoodTagDtoFromJson(Map<String, dynamic> json) => FoodTagDto(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  count: (json['count'] as num?)?.toInt(),
  taggedByMe: json['taggedByMe'] as bool?,
  usageCount: (json['usageCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$FoodTagDtoToJson(FoodTagDto instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'name': ?instance.name,
      'count': ?instance.count,
      'taggedByMe': ?instance.taggedByMe,
      'usageCount': ?instance.usageCount,
    };

CoverCropDto _$CoverCropDtoFromJson(Map<String, dynamic> json) => CoverCropDto(
  centerX: (json['centerX'] as num?)?.toDouble(),
  centerY: (json['centerY'] as num?)?.toDouble(),
  diameter: (json['diameter'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CoverCropDtoToJson(CoverCropDto instance) =>
    <String, dynamic>{
      'centerX': ?instance.centerX,
      'centerY': ?instance.centerY,
      'diameter': ?instance.diameter,
    };

FoodTagsDto _$FoodTagsDtoFromJson(Map<String, dynamic> json) => FoodTagsDto(
  systemTags: (json['systemTags'] as List<dynamic>?)
      ?.map((e) => FoodTagDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  myCustomTags: (json['myCustomTags'] as List<dynamic>?)
      ?.map((e) => FoodTagDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CreateFoodDtoToJson(CreateFoodDto instance) =>
    <String, dynamic>{
      'restaurantId': instance.restaurantId,
      'name': instance.name,
      'pictureUrl': instance.pictureUrl,
      'price': ?instance.price,
      'category': ?instance.category,
      'mealTimes': ?instance.mealTimes,
      'description': ?instance.description,
      'systemTagIds': ?instance.systemTagIds,
      'myCustomTagNames': ?instance.myCustomTagNames,
      'stageColor': ?instance.stageColor,
      'stageAlternates': ?instance.stageAlternates,
      'coverCrop': ?instance.coverCrop?.toJson(),
      'removeBackground': ?instance.removeBackground,
    };
