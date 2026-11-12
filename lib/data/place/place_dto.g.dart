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
      poi: json['poi'] as String?,
      pictureUrl: json['pictureUrl'] as String?,
      permanentlyClosed: json['permanentlyClosed'] as bool?,
      hubId: (json['hubId'] as num?)?.toInt(),
      hubName: json['hubName'] as String?,
      campusId: (json['campusId'] as num?)?.toInt(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      isFavorite: json['isFavorite'] as bool?,
      deliveryEnabled: json['deliveryEnabled'] as bool?,
      kind: json['kind'] as String?,
      mealTimes: (json['mealTimes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      priceBand: json['priceBand'] as String?,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      dineIn: json['dineIn'] == null
          ? null
          : StatDto.fromJson(json['dineIn'] as Map<String, dynamic>),
      delivery: json['delivery'] == null
          ? null
          : StatDto.fromJson(json['delivery'] as Map<String, dynamic>),
      myRatings: json['myRatings'] == null
          ? null
          : MyRatingsDto.fromJson(json['myRatings'] as Map<String, dynamic>),
      signatureFoods: (json['signatureFoods'] as List<dynamic>?)
          ?.map((e) => SignatureFoodDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

StatDto _$StatDtoFromJson(Map<String, dynamic> json) => StatDto(
  rate: (json['rate'] as num?)?.toDouble(),
  count: (json['count'] as num?)?.toInt(),
);

MyRatingsDto _$MyRatingsDtoFromJson(Map<String, dynamic> json) => MyRatingsDto(
  dineIn: json['dineIn'] as String?,
  delivery: json['delivery'] as String?,
);

SignatureFoodDto _$SignatureFoodDtoFromJson(Map<String, dynamic> json) =>
    SignatureFoodDto(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      pictureUrl: json['pictureUrl'] as String?,
    );

Map<String, dynamic> _$RatingRequestDtoToJson(RatingRequestDto instance) =>
    <String, dynamic>{'scene': instance.scene, 'rating': instance.rating};

Map<String, dynamic> _$CreateRestaurantDtoToJson(
  CreateRestaurantDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'gcjLng': instance.gcjLng,
  'gcjLat': instance.gcjLat,
  'poi': ?instance.poi,
  'picture': ?instance.picture,
  'kind': instance.kind,
  'mealTimes': ?instance.mealTimes,
  'priceBand': ?instance.priceBand,
  'categories': ?instance.categories,
  'tags': ?instance.tags,
  'deliveryEnabled': ?instance.deliveryEnabled,
};

Map<String, dynamic> _$EditRestaurantDtoToJson(EditRestaurantDto instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'address': ?instance.address,
      'gcjLng': ?instance.gcjLng,
      'gcjLat': ?instance.gcjLat,
      'poi': ?instance.poi,
      'picture': ?instance.picture,
      'permanentlyClosed': ?instance.permanentlyClosed,
      'kind': ?instance.kind,
      'mealTimes': ?instance.mealTimes,
      'priceBand': ?instance.priceBand,
      'categories': ?instance.categories,
      'tags': ?instance.tags,
      'deliveryEnabled': ?instance.deliveryEnabled,
    };

EditedRestaurantDto _$EditedRestaurantDtoFromJson(Map<String, dynamic> json) =>
    EditedRestaurantDto(
      id: (json['id'] as num?)?.toInt(),
      revisionId: (json['revisionId'] as num?)?.toInt(),
    );

RevisionDto _$RevisionDtoFromJson(Map<String, dynamic> json) => RevisionDto(
  id: (json['id'] as num?)?.toInt(),
  action: json['action'] as String?,
  editor: json['editor'] == null
      ? null
      : RevisionEditorDto.fromJson(json['editor'] as Map<String, dynamic>),
  restoredFrom: (json['restoredFrom'] as num?)?.toInt(),
  changes: (json['changes'] as List<dynamic>?)
      ?.map((e) => FieldChangeDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: (json['createdAt'] as num?)?.toInt(),
);

RevisionEditorDto _$RevisionEditorDtoFromJson(Map<String, dynamic> json) =>
    RevisionEditorDto(
      id: (json['id'] as num?)?.toInt(),
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
    );

FieldChangeDto _$FieldChangeDtoFromJson(Map<String, dynamic> json) =>
    FieldChangeDto(
      field: json['field'] as String?,
      from: json['from'],
      to: json['to'],
    );
