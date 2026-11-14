import 'package:json_annotation/json_annotation.dart';

part 'food_dto.g.dart';

/// 菜品接口返回的菜品 (后端 `FoodDtos.Food`).
///
/// 推荐的上一批和菜品详情会原样存入本地缓存, 因此需要支持转回 JSON.
/// 接口文档中同名的 `Food` 结构属于足迹模块, 字段以后端源码为准.
@JsonSerializable(includeIfNull: false)
class const FoodDto({
  final int? id,
  final int? restaurantId,
  final String? restaurantName,

  /// 首次发布者的账号. 账号已删除时为 null.
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

  /// 游客为 null.
  final bool? isLiked,
  final bool? isFavorite,
  final int? createdAt,
  final int? updatedAt,

  /// 舞台色和两个备选色, 取值是 `stage-*` 去掉前缀. 没有保存时 [stageColor] 为 null, [stageAlternates] 为空.
  final String? stageColor,
  final List<String>? stageAlternates,
  final CoverCropDto? coverCrop,
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

/// 发布菜品的请求体 (后端 `FoodDtos.UploadRequest`).
///
/// - [pictures] 是上传后获得的存储 key, 第一张为封面.
/// - [category] 和 [tags] 是中文原值.
/// - [stageColor] 和 [stageAlternates] 要么都传, 要么都不传. [coverCrop] 是封面的圆形取景, 有照片时才传.
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
}) {
  Map<String, dynamic> toJson() => _$CreateFoodDtoToJson(this);
}

/// 编辑菜品的请求体 (后端 `FoodDtos.EditRequest`). 值为 null 的字段不发送, 表示不修改.
///
/// - [description] 为空字符串表示清除.
/// - [pictures] 和 [tags] 为空数组表示清除.
///
/// 接口文档中同名的 `EditRequest` 结构属于店铺模块, 字段以后端源码为准.
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

  /// 舞台色和备选色要一起改. 换了封面而没传 [coverCrop] 时, 服务端把取景改回居中.
  final String? stageColor,
  final List<String>? stageAlternates,
  final CoverCropDto? coverCrop,
}) {
  Map<String, dynamic> toJson() => _$EditFoodDtoToJson(this);
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

/// 修改记录中一个字段的改动. 只读取字段名, 改动前后的值不展示.
@JsonSerializable(createToJson: false)
class const FoodFieldChangeDto({final String? field}) {
  factory FoodFieldChangeDto.fromJson(Map<String, dynamic> json) =>
      _$FoodFieldChangeDtoFromJson(json);
}
