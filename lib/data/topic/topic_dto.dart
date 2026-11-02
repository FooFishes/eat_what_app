import 'package:json_annotation/json_annotation.dart';

part 'topic_dto.g.dart';

/// 专题摘要.
///
/// - [startsAt] 和 [endsAt] 是带时区的 ISO 8601 时间, 区间包含开始时刻, 不包含结束时刻.
/// - [coverFoodId] 在封面菜不可见时为 null.
/// - [visibleFoodCount] 是当前仍可见的菜数. 菜被删除后会少于发布时的数量.
@JsonSerializable(createToJson: false)
class const TopicSummaryDto({
  final int? id,
  final int? campusId,
  final String? name,
  final String? introduction,
  final String? startsAt,
  final String? endsAt,
  final int? coverFoodId,
  final int? visibleFoodCount,
}) {
  factory TopicSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$TopicSummaryDtoFromJson(json);
}

/// 专题里的一道菜, 已包含菜品方块和舞台所需的字段.
///
/// 圆形取景是平铺的三个字段, 不同于 `FoodDto` 的 `coverCrop` 对象.
@JsonSerializable(createToJson: false)
class const TopicFoodDto({
  final int? id,
  final String? name,
  final String? description,
  final int? restaurantId,
  final String? restaurantName,
  final String? uploaderName,
  final double? price,
  final String? category,
  final List<String>? pictureUrl,
  final int? likesCount,
  final List<String>? mealTimes,
  final String? stageColor,
  final List<String>? stageAlternates,
  final double? coverCenterX,
  final double? coverCenterY,
  final double? coverDiameter,
  final int? position,
}) {
  factory TopicFoodDto.fromJson(Map<String, dynamic> json) =>
      _$TopicFoodDtoFromJson(json);
}

/// 专题详情: 摘要和按位置排好的菜.
@JsonSerializable(createToJson: false)
class const TopicDetailDto({
  final TopicSummaryDto? topic,
  final List<TopicFoodDto>? foods,
}) {
  factory TopicDetailDto.fromJson(Map<String, dynamic> json) =>
      _$TopicDetailDtoFromJson(json);
}
