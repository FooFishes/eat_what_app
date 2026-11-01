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
