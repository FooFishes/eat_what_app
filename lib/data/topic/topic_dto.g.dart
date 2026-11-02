// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopicSummaryDto _$TopicSummaryDtoFromJson(Map<String, dynamic> json) =>
    TopicSummaryDto(
      id: (json['id'] as num?)?.toInt(),
      campusId: (json['campusId'] as num?)?.toInt(),
      name: json['name'] as String?,
      introduction: json['introduction'] as String?,
      startsAt: json['startsAt'] as String?,
      endsAt: json['endsAt'] as String?,
      coverFoodId: (json['coverFoodId'] as num?)?.toInt(),
      visibleFoodCount: (json['visibleFoodCount'] as num?)?.toInt(),
    );

TopicFoodDto _$TopicFoodDtoFromJson(Map<String, dynamic> json) => TopicFoodDto(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  description: json['description'] as String?,
  restaurantId: (json['restaurantId'] as num?)?.toInt(),
  restaurantName: json['restaurantName'] as String?,
  uploaderName: json['uploaderName'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  category: json['category'] as String?,
  pictureUrl: (json['pictureUrl'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  likesCount: (json['likesCount'] as num?)?.toInt(),
  mealTimes: (json['mealTimes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  stageColor: json['stageColor'] as String?,
  stageAlternates: (json['stageAlternates'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  coverCenterX: (json['coverCenterX'] as num?)?.toDouble(),
  coverCenterY: (json['coverCenterY'] as num?)?.toDouble(),
  coverDiameter: (json['coverDiameter'] as num?)?.toDouble(),
  position: (json['position'] as num?)?.toInt(),
);

TopicDetailDto _$TopicDetailDtoFromJson(Map<String, dynamic> json) =>
    TopicDetailDto(
      topic: json['topic'] == null
          ? null
          : TopicSummaryDto.fromJson(json['topic'] as Map<String, dynamic>),
      foods: (json['foods'] as List<dynamic>?)
          ?.map((e) => TopicFoodDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
