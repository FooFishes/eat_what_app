// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreferencesDto _$PreferencesDtoFromJson(Map<String, dynamic> json) =>
    PreferencesDto(
      likedCategories: (json['likedCategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      likedTags: (json['likedTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      dislikedTags: (json['dislikedTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      priceBand: json['priceBand'] as String?,
      maxDistance: (json['maxDistance'] as num?)?.toInt(),
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PreferencesRequestDtoToJson(
  PreferencesRequestDto instance,
) => <String, dynamic>{
  'likedCategories': instance.likedCategories,
  'likedTags': instance.likedTags,
  'dislikedTags': instance.dislikedTags,
  'priceBand': ?instance.priceBand,
  'maxDistance': ?instance.maxDistance,
};

RecommendOptionsDto _$RecommendOptionsDtoFromJson(Map<String, dynamic> json) =>
    RecommendOptionsDto(
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      dislikableTags: (json['dislikableTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

TasteDto _$TasteDtoFromJson(Map<String, dynamic> json) => TasteDto(
  tags: (json['tags'] as List<dynamic>?)
      ?.map((e) => TasteScoreDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  categories: (json['categories'] as List<dynamic>?)
      ?.map((e) => TasteScoreDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  inferredTags: (json['inferredTags'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  inferredCategories: (json['inferredCategories'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

TasteScoreDto _$TasteScoreDtoFromJson(Map<String, dynamic> json) =>
    TasteScoreDto(
      name: json['name'] as String?,
      score: (json['score'] as num?)?.toDouble(),
    );
