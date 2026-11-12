// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendFeedDto _$RecommendFeedDtoFromJson(Map<String, dynamic> json) =>
    RecommendFeedDto(
      mealTime: json['mealTime'] as String?,
      currentPage: (json['currentPage'] as num?)?.toInt(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      hasNext: json['hasNext'] as bool?,
      totalItems: (json['totalItems'] as num?)?.toInt(),
    );
