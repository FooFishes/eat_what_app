import 'package:json_annotation/json_annotation.dart';

part 'food_dto.g.dart';

/// 菜品接口返回的菜品 (后端 `FoodDtos.FoodView`).
///
/// 推荐的上一批和菜品详情会原样存入本地缓存, 因此需要支持转回 JSON.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class const FoodDto({
  final int? id,
  final int? restaurantId,
  final String? restaurantName,

  /// 首次发布者的账号 id, 账号已注销删除时为 null.
  final int? accountId,
  final String? name,

  /// 分类的中文原值, 如 "主食".
  final String? category,
  final double? price,
  final String? description,

  /// 图片的公开地址, 第一张是封面. 响应不带存储 key.
  final List<String>? pictureUrls,

  /// 口味的中文原值, 如 "辣", 最多 3 个.
  final List<String>? tags,
  final bool? signature,
  final int? likeCount,
  final int? favoriteCount,

  /// 当前用户是否已点赞, 游客为 null.
  final bool? isLiked,
  final bool? isFavorite,
  final int? createdAt,
  final int? updatedAt,

  /// 舞台色和两个备选色, 取值是 `stage-*` 去掉前缀. 若未保存过, [stageColor] 为 null 且 [stageAlternates] 为空.
  final String? stageColor,
  final List<String>? stageAlternates,
  final CoverCropDto? coverCrop,

  /// 菜品自己设置的饭点, 空数组表示沿用店铺的饭点. [effectiveMealTimes] 是实际供应的饭点.
  final List<String>? mealTimes,
  final List<String>? effectiveMealTimes,
  final bool? deliveryEnabled,
  final DishRatingDto? rating,

  /// 当前用户打的分 (1–5), 游客或没打过分时为 null.
  final int? myRating,
}) {
  factory FoodDto.fromJson(Map<String, dynamic> json) =>
      _$FoodDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FoodDtoToJson(this);
}

/// 菜品上的投票标签. 后端 v2 已删除标签接口, 只有保留的待接入页面使用.
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

/// 菜品的评分统计 (后端 `FoodDtos.Rating` 和 `RecommendDtos.DishRating`, 两者字段相同).
///
/// [score] 是 1–5 分的平均分, 保留一位小数, 没有人评分时为 null. [count] 是评分人数.
@JsonSerializable(includeIfNull: false)
class const DishRatingDto({final double? score, final int? count}) {
  factory DishRatingDto.fromJson(Map<String, dynamic> json) =>
      _$DishRatingDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DishRatingDtoToJson(this);
}

/// 给菜品评分的请求体 (后端 `FoodDtos.RatingRequest`). [score] 是 1–5 的整数.
///
/// openapi 中的同名结构被店铺评价的 `{scene, rating}` 覆盖, 字段以后端源码为准.
@JsonSerializable(createFactory: false)
class const RateFoodDto({required final int score}) {
  Map<String, dynamic> toJson() => _$RateFoodDtoToJson(this);
}

/// 评分或撤销评分的结果 (后端 `FoodDtos.Rated`).
///
/// [myRating] 是当前用户的分数, 撤销后为 null. [rating] 是这道菜最新的评分统计.
@JsonSerializable(createToJson: false)
class const FoodRatedDto({final int? myRating, final DishRatingDto? rating}) {
  factory FoodRatedDto.fromJson(Map<String, dynamic> json) =>
      _$FoodRatedDtoFromJson(json);
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

/// `/foods/{id}/tags` 的 `data`, 包含该菜品的系统标签与我的个人标签.
@JsonSerializable(createToJson: false)
class const FoodTagsDto({
  final List<FoodTagDto>? systemTags,
  final List<FoodTagDto>? myCustomTags,
}) {
  factory FoodTagsDto.fromJson(Map<String, dynamic> json) =>
      _$FoodTagsDtoFromJson(json);
}

/// 发布菜品的请求体 (后端 `FoodDtos.FoodUploadRequest`).
///
/// - [pictures] 是上传后获得的存储 key, 第一张为封面.
/// - [category] 和 [tags] 是中文原值.
/// - [stageColor] 和 [stageAlternates] 要么都传, 要么都不传. [coverCrop] 是封面的圆形取景, 有照片时才传.
/// - [mealTimes] 省略或为空数组时沿用店铺的饭点. [deliveryEnabled] 省略时为 false.
@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class const CreateFoodDto({
  required final int restaurantId,
  required final String name,
  required final String category,
  final double? price,
  final String? description,
  final List<String>? pictures,
  final List<String>? tags,
  final bool? signature,
  final String? stageColor,
  final List<String>? stageAlternates,
  final CoverCropDto? coverCrop,
  final List<String>? mealTimes,
  final bool? deliveryEnabled,
}) {
  Map<String, dynamic> toJson() => _$CreateFoodDtoToJson(this);
}

/// 编辑菜品的请求体 (后端 `FoodDtos.FoodEditRequest`). 值为 null 的字段不发送, 表示不修改.
///
/// - [description] 为空字符串表示清除.
/// - [pictures] 和 [tags] 为空数组表示清除.
/// - [mealTimes] 为空数组表示改回沿用店铺的饭点.
@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class const EditFoodDto({
  final String? name,
  final String? category,
  final double? price,
  final String? description,
  final List<String>? pictures,
  final List<String>? tags,
  final bool? signature,

  /// 舞台色与备选色需同步修改. 若更换了封面但未传 [coverCrop], 服务端会将取景重置为居中.
  final String? stageColor,
  final List<String>? stageAlternates,
  final CoverCropDto? coverCrop,
  final List<String>? mealTimes,
  final bool? deliveryEnabled,
}) {
  Map<String, dynamic> toJson() => _$EditFoodDtoToJson(this);
}

/// `/foods/options` 的 `data` (后端 `FoodDtos.FoodOptions`).
///
/// 分类按菜单顺序排列, 都是中文原值. [stageColors] 是 `stage-*` 去掉前缀.
@JsonSerializable(createToJson: false)
class const FoodOptionsDto({
  final List<String>? categories,
  final List<String>? tags,
  final List<String>? stageColors,
  final int? maxPictures,
  final int? maxTags,
  final int? maxSignatures,
  final List<String>? mealTimes,
}) {
  factory FoodOptionsDto.fromJson(Map<String, dynamic> json) =>
      _$FoodOptionsDtoFromJson(json);
}

/// 发布前查重的一项 (后端 `FoodDtos.DishDuplicate`).
///
/// [sameName] 表示与输入的菜名相同 (忽略空白和大小写), 这时发布会返回 `BizCodes.duplicateDish`. [pictureUrl] 是封面.
@JsonSerializable(createToJson: false)
class const DishDuplicateDto({
  final int? id,
  final String? name,
  final String? category,
  final double? price,
  final String? pictureUrl,
  final bool? sameName,
}) {
  factory DishDuplicateDto.fromJson(Map<String, dynamic> json) =>
      _$DishDuplicateDtoFromJson(json);
}

/// 请求识别分类和口味的请求体 (后端 `FoodDtos.SuggestRequest`).
///
/// [pictures] 是本人上传的存储 key, 最多 3 张.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const SuggestFoodDto({
  required final String name,
  final int? restaurantId,
  final String? description,
  final List<String>? pictures,
}) {
  Map<String, dynamic> toJson() => _$SuggestFoodDtoToJson(this);
}

/// 识别出的分类和口味 (后端 `FoodDtos.Suggestion`), 都是中文原值.
@JsonSerializable(createToJson: false)
class const FoodSuggestionDto({
  final String? category,
  final List<String>? tags,
}) {
  factory FoodSuggestionDto.fromJson(Map<String, dynamic> json) =>
      _$FoodSuggestionDtoFromJson(json);
}

/// 菜品的一条修改记录 (后端 `FoodDtos.Revision`).
///
/// [action] 为 `create`, `edit` 或 `restore`. [restoredFrom] 是恢复到的记录 id.
@JsonSerializable(createToJson: false)
class const FoodRevisionDto({
  final int? id,
  final String? action,
  final FoodEditorDto? editor,
  final int? restoredFrom,
  final List<FoodFieldChangeDto>? changes,
  final int? createdAt,
}) {
  factory FoodRevisionDto.fromJson(Map<String, dynamic> json) =>
      _$FoodRevisionDtoFromJson(json);
}

/// 修改记录的编辑者. 账号已删除时 [id] 和 [displayName] 为 null.
@JsonSerializable(createToJson: false)
class const FoodEditorDto({
  final int? id,
  final String? displayName,
  final String? avatar,
}) {
  factory FoodEditorDto.fromJson(Map<String, dynamic> json) =>
      _$FoodEditorDtoFromJson(json);
}

/// 修改记录中单个字段的变更信息, 仅读取字段名, 不展示改动前后的具体值.
@JsonSerializable(createToJson: false)
class const FoodFieldChangeDto({final String? field}) {
  factory FoodFieldChangeDto.fromJson(Map<String, dynamic> json) =>
      _$FoodFieldChangeDtoFromJson(json);
}
