// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampusDto _$CampusDtoFromJson(Map<String, dynamic> json) => CampusDto(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  gcjLng: (json['gcjLng'] as num?)?.toDouble(),
  gcjLat: (json['gcjLat'] as num?)?.toDouble(),
  isDefault: json['isDefault'] as bool?,
  sort: (json['sort'] as num?)?.toInt(),
);

HubDto _$HubDtoFromJson(Map<String, dynamic> json) => HubDto(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  gcjLng: (json['gcjLng'] as num?)?.toDouble(),
  gcjLat: (json['gcjLat'] as num?)?.toDouble(),
  campusId: (json['campusId'] as num?)?.toInt(),
  boundary: json['boundary'] == null
      ? null
      : GeoJsonDto.fromJson(json['boundary'] as Map<String, dynamic>),
);

GeoJsonDto _$GeoJsonDtoFromJson(Map<String, dynamic> json) => GeoJsonDto(
  type: json['type'] as String?,
  coordinates: json['coordinates'] as List<dynamic>?,
);

RestaurantDto _$RestaurantDtoFromJson(Map<String, dynamic> json) =>
    RestaurantDto(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      address: json['address'] as String?,
      gcjLng: (json['gcjLng'] as num?)?.toDouble(),
      gcjLat: (json['gcjLat'] as num?)?.toDouble(),
      hubId: (json['hubId'] as num?)?.toInt(),
      pictureUrl: (json['pictureUrl'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      operatingStatus: json['operatingStatus'] as String,
      permanentlyClosed: json['permanentlyClosed'] as bool?,
      visibleFoodCount: (json['visibleFoodCount'] as num).toInt(),
      priceBand: json['priceBand'] as String?,
      ratingCount: (json['ratingCount'] as num?)?.toInt(),
      recommendationRate: (json['recommendationRate'] as num?)?.toInt(),
      signatureFoods: (json['signatureFoods'] as List<dynamic>)
          .map((e) => RestaurantFoodDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      matchedFoods: (json['matchedFoods'] as List<dynamic>)
          .map((e) => RestaurantFoodDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      publicTastes: (json['publicTastes'] as List<dynamic>)
          .map((e) => RestaurantTasteDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      coverUrl: json['coverUrl'] as String?,
      myRating: json['myRating'] as String?,
      isFavorite: json['isFavorite'] as bool?,
    );

RestaurantFoodDto _$RestaurantFoodDtoFromJson(Map<String, dynamic> json) =>
    RestaurantFoodDto(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      coverUrl: json['coverUrl'] as String?,
      stageColor: json['stageColor'] as String?,
      likesCount: (json['likesCount'] as num?)?.toInt(),
    );

RestaurantTasteDto _$RestaurantTasteDtoFromJson(Map<String, dynamic> json) =>
    RestaurantTasteDto(
      tagId: (json['tagId'] as num?)?.toInt(),
      name: json['name'] as String?,
      taggerCount: (json['taggerCount'] as num?)?.toInt(),
    );

RestaurantRatingDto _$RestaurantRatingDtoFromJson(Map<String, dynamic> json) =>
    RestaurantRatingDto(rating: json['rating'] as String?);

Map<String, dynamic> _$RestaurantRatingDtoToJson(
  RestaurantRatingDto instance,
) => <String, dynamic>{'rating': ?instance.rating};

CreatedRestaurantDto _$CreatedRestaurantDtoFromJson(
  Map<String, dynamic> json,
) => CreatedRestaurantDto(
  id: (json['id'] as num?)?.toInt(),
  moderationStatus: json['moderationStatus'] as String?,
);

Map<String, dynamic> _$CreateRestaurantDtoToJson(
  CreateRestaurantDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'gcjLng': instance.gcjLng,
  'gcjLat': instance.gcjLat,
  'hubId': ?instance.hubId,
  'pictureUrl': ?instance.pictureUrl,
};
