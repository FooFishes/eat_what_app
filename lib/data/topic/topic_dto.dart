import 'package:json_annotation/json_annotation.dart';

part 'topic_dto.g.dart';

/// 专题摘要信息.
///
/// - [startsAt] 与 [endsAt] 为带时区的 ISO 8601 时间, 生效区间为左闭右开 `[startsAt, endsAt)`.
/// - [coverFoodId] 在封面菜品不可见时为 null.
/// - [visibleFoodCount] 为当前仍可见的菜品数, 若菜品后续被删除则会少于发布时的总数.
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

/// 专题内的菜品条目, 已包含菜品方块与舞台展示所需的全部字段.
///
/// 其圆形取景参数以三个平铺字段返回, 不同于 `FoodDto` 中的嵌套 `coverCrop` 对象.
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

/// 专题详情数据结构, 包含专题摘要以及按展示顺序排列的菜品列表.
@JsonSerializable(createToJson: false)
class const TopicDetailDto({
  final TopicSummaryDto? topic,
  final List<TopicFoodDto>? foods,
}) {
  factory TopicDetailDto.fromJson(Map<String, dynamic> json) =>
      _$TopicDetailDtoFromJson(json);
}
