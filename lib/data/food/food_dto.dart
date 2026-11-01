import 'package:json_annotation/json_annotation.dart';

part 'food_dto.g.dart';

/// 菜品接口返回的菜品 (`FoodVO`, `FoodRecommendationVO`). 字段按接口声明均为可空.
///
/// 推荐的上一批和菜品详情会原样存入本地缓存, 因此需要支持转回 JSON.
@JsonSerializable(includeIfNull: false)
class const FoodDto({
  final int? id,
  final int? accountId,
  final String? uploaderName,
  final int? restaurantId,
  final String? restaurantName,
  final String? restaurantAddress,
  final double? restaurantGcjLng,
  final double? restaurantGcjLat,
  final int? hubId,
  final String? hubName,
  final String? name,
  final String? description,
  final double? price,
  final String? category,
  final List<String>? pictureUrl,
  final List<FoodTagDto>? systemTags,
  final List<FoodTagDto>? myCustomTags,
  final bool? isLiked,
  final bool? isFavorite,
  final int? likesCount,
  final List<String>? mealTimes,
  final String? stageColor,
  final List<String>? stageAlternates,
  final CoverCropDto? coverCrop,
  final int? createdAt,
}) {
  factory FoodDto.fromJson(Map<String, dynamic> json) =>
      _$FoodDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FoodDtoToJson(this);
}

/// 菜品上的标签.
///
/// - 系统标签带 [count] 和 [taggedByMe].
/// - 个人标签只有名称.
/// - "我的标签" 列表中的标签带 [usageCount].
@JsonSerializable(includeIfNull: false)
class const FoodTagDto({
  final int? id,
  final String? name,
  final int? count,
  final bool? taggedByMe,
  final int? usageCount,
}) {
  factory FoodTagDto.fromJson(Map<String, dynamic> json) =>
      _$FoodTagDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FoodTagDtoToJson(this);
}

@JsonSerializable(includeIfNull: false)
class const CoverCropDto({
  final double? centerX,
  final double? centerY,
  final double? diameter,
}) {
  factory CoverCropDto.fromJson(Map<String, dynamic> json) =>
      _$CoverCropDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CoverCropDtoToJson(this);
}

/// `/foods/{id}/tags` 的 `data`: 该菜品的系统标签和我的标签.
@JsonSerializable(createToJson: false)
class const FoodTagsDto({
  final List<FoodTagDto>? systemTags,
  final List<FoodTagDto>? myCustomTags,
}) {
  factory FoodTagsDto.fromJson(Map<String, dynamic> json) =>
      _$FoodTagsDtoFromJson(json);
}

/// 发布菜品的请求体 (`CreateFoodDTO`). [pictureUrl] 为上传后获得的存储 key, 第一张为封面.
@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class const CreateFoodDto({
  required final int restaurantId,
  required final String name,
  required final List<String> pictureUrl,
  final double? price,
  final String? category,
  final List<String>? mealTimes,
  final String? description,
  final List<int>? systemTagIds,
  final List<String>? myCustomTagNames,
  final String? stageColor,
  final List<String>? stageAlternates,
  final CoverCropDto? coverCrop,
  final bool? removeBackground,
}) {
  Map<String, dynamic> toJson() => _$CreateFoodDtoToJson(this);
}
