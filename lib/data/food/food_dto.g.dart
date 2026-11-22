// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodDto _$FoodDtoFromJson(Map<String, dynamic> json) => FoodDto(
  id: (json['id'] as num?)?.toInt(),
  restaurantId: (json['restaurantId'] as num?)?.toInt(),
  restaurantName: json['restaurantName'] as String?,
  accountId: (json['accountId'] as num?)?.toInt(),
  name: json['name'] as String?,
  category: json['category'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  description: json['description'] as String?,
  pictureUrls: (json['pictureUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  pictureKeys: (json['pictureKeys'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  signature: json['signature'] as bool?,
  likeCount: (json['likeCount'] as num?)?.toInt(),
  favoriteCount: (json['favoriteCount'] as num?)?.toInt(),
  isLiked: json['isLiked'] as bool?,
  isFavorite: json['isFavorite'] as bool?,
  createdAt: (json['createdAt'] as num?)?.toInt(),
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
  stageColor: json['stageColor'] as String?,
  stageAlternates: (json['stageAlternates'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  coverCrop: json['coverCrop'] == null
      ? null
      : CoverCropDto.fromJson(json['coverCrop'] as Map<String, dynamic>),
  mealTimes: (json['mealTimes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  effectiveMealTimes: (json['effectiveMealTimes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  deliveryEnabled: json['deliveryEnabled'] as bool?,
  rating: json['rating'] == null
      ? null
      : DishRatingDto.fromJson(json['rating'] as Map<String, dynamic>),
  myRating: (json['myRating'] as num?)?.toInt(),
);

Map<String, dynamic> _$FoodDtoToJson(FoodDto instance) => <String, dynamic>{
  'id': ?instance.id,
  'restaurantId': ?instance.restaurantId,
  'restaurantName': ?instance.restaurantName,
  'accountId': ?instance.accountId,
  'name': ?instance.name,
  'category': ?instance.category,
  'price': ?instance.price,
  'description': ?instance.description,
  'pictureUrls': ?instance.pictureUrls,
  'pictureKeys': ?instance.pictureKeys,
  'tags': ?instance.tags,
  'signature': ?instance.signature,
  'likeCount': ?instance.likeCount,
  'favoriteCount': ?instance.favoriteCount,
  'isLiked': ?instance.isLiked,
  'isFavorite': ?instance.isFavorite,
  'createdAt': ?instance.createdAt,
  'updatedAt': ?instance.updatedAt,
  'stageColor': ?instance.stageColor,
  'stageAlternates': ?instance.stageAlternates,
  'coverCrop': ?instance.coverCrop?.toJson(),
  'mealTimes': ?instance.mealTimes,
  'effectiveMealTimes': ?instance.effectiveMealTimes,
  'deliveryEnabled': ?instance.deliveryEnabled,
  'rating': ?instance.rating?.toJson(),
  'myRating': ?instance.myRating,
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

DishRatingDto _$DishRatingDtoFromJson(Map<String, dynamic> json) =>
    DishRatingDto(
      score: (json['score'] as num?)?.toDouble(),
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DishRatingDtoToJson(DishRatingDto instance) =>
    <String, dynamic>{'score': ?instance.score, 'count': ?instance.count};

Map<String, dynamic> _$RateFoodDtoToJson(RateFoodDto instance) =>
    <String, dynamic>{'score': instance.score};

FoodRatedDto _$FoodRatedDtoFromJson(Map<String, dynamic> json) => FoodRatedDto(
  myRating: (json['myRating'] as num?)?.toInt(),
  rating: json['rating'] == null
      ? null
      : DishRatingDto.fromJson(json['rating'] as Map<String, dynamic>),
);

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
      'category': instance.category,
      'price': ?instance.price,
      'description': ?instance.description,
      'pictures': ?instance.pictures,
      'tags': ?instance.tags,
      'signature': ?instance.signature,
      'stageColor': ?instance.stageColor,
      'stageAlternates': ?instance.stageAlternates,
      'coverCrop': ?instance.coverCrop?.toJson(),
      'mealTimes': ?instance.mealTimes,
      'deliveryEnabled': ?instance.deliveryEnabled,
    };

Map<String, dynamic> _$EditFoodDtoToJson(EditFoodDto instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'category': ?instance.category,
      'price': ?instance.price,
      'description': ?instance.description,
      'pictures': ?instance.pictures,
      'tags': ?instance.tags,
      'signature': ?instance.signature,
      'stageColor': ?instance.stageColor,
      'stageAlternates': ?instance.stageAlternates,
      'coverCrop': ?instance.coverCrop?.toJson(),
      'mealTimes': ?instance.mealTimes,
      'deliveryEnabled': ?instance.deliveryEnabled,
    };

FoodEditResultDto _$FoodEditResultDtoFromJson(Map<String, dynamic> json) =>
    FoodEditResultDto(
      id: (json['id'] as num?)?.toInt(),
      revisionId: (json['revisionId'] as num?)?.toInt(),
      pictureKeys: (json['pictureKeys'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

FoodOptionsDto _$FoodOptionsDtoFromJson(Map<String, dynamic> json) =>
    FoodOptionsDto(
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      stageColors: (json['stageColors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      maxPictures: (json['maxPictures'] as num?)?.toInt(),
      maxTags: (json['maxTags'] as num?)?.toInt(),
      maxSignatures: (json['maxSignatures'] as num?)?.toInt(),
      mealTimes: (json['mealTimes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

DishDuplicateDto _$DishDuplicateDtoFromJson(Map<String, dynamic> json) =>
    DishDuplicateDto(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      category: json['category'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      pictureUrl: json['pictureUrl'] as String?,
      sameName: json['sameName'] as bool?,
    );

Map<String, dynamic> _$SuggestFoodDtoToJson(SuggestFoodDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'restaurantId': ?instance.restaurantId,
      'description': ?instance.description,
      'pictures': ?instance.pictures,
    };

FoodSuggestionDto _$FoodSuggestionDtoFromJson(Map<String, dynamic> json) =>
    FoodSuggestionDto(
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

FoodRevisionDto _$FoodRevisionDtoFromJson(Map<String, dynamic> json) =>
    FoodRevisionDto(
      id: (json['id'] as num?)?.toInt(),
      action: json['action'] as String?,
      editor: json['editor'] == null
          ? null
          : FoodEditorDto.fromJson(json['editor'] as Map<String, dynamic>),
      restoredFrom: (json['restoredFrom'] as num?)?.toInt(),
      changes: (json['changes'] as List<dynamic>?)
          ?.map((e) => FoodFieldChangeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: (json['createdAt'] as num?)?.toInt(),
    );

FoodEditorDto _$FoodEditorDtoFromJson(Map<String, dynamic> json) =>
    FoodEditorDto(
      id: (json['id'] as num?)?.toInt(),
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
    );

FoodFieldChangeDto _$FoodFieldChangeDtoFromJson(Map<String, dynamic> json) =>
    FoodFieldChangeDto(field: json['field'] as String?);
