import 'package:eat/data/food/food_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'place_dto.g.dart';

/// `/campus/list` 的一项.
@JsonSerializable(createToJson: false)
class const CampusDto({
  final int? id,
  final String? name,
  final double? gcjLng,
  final double? gcjLat,
  final bool? isDefault,
  final int? sort,
}) {
  factory CampusDto.fromJson(Map<String, dynamic> json) =>
      _$CampusDtoFromJson(json);
}

/// 商圈.
///
/// [boundary] 为 GeoJSON MultiPolygon, 坐标系与 [gcjLng] 和 [gcjLat] 相同, 都是 GCJ-02. 没有边界时为 null.
@JsonSerializable(createToJson: false)
class const HubDto({
  final int? id,
  final String? name,
  final double? gcjLng,
  final double? gcjLat,
  final int? campusId,
  final GeoJsonDto? boundary,
}) {
  factory HubDto.fromJson(Map<String, dynamic> json) => _$HubDtoFromJson(json);
}

/// GeoJSON 几何. `Point` 的坐标为 `[经度, 纬度]`, `MultiPolygon` 按多边形, 环, 点三层嵌套.
@JsonSerializable(createToJson: false)
class const GeoJsonDto({final String? type, final List<dynamic>? coordinates}) {
  factory GeoJsonDto.fromJson(Map<String, dynamic> json) =>
      _$GeoJsonDtoFromJson(json);
}

/// 店铺 (`RestaurantDtos.Restaurant`), 也用于解析推荐卡片 (`RecommendDtos.Card`).
///
/// 推荐卡片是店铺的子集, 另带 [signatureFoods]. 店铺接口不返回 [signatureFoods].
@JsonSerializable(createToJson: false)
class const RestaurantDto({
  final int? id,
  final String? name,
  final String? address,
  final double? gcjLng,
  final double? gcjLat,

  /// 百度地点的 uid. 手动添加的店为 null.
  final String? poi,

  /// 门头照片的地址.
  final String? pictureUrl,
  final bool? permanentlyClosed,
  final int? hubId,
  final String? hubName,
  final int? campusId,

  /// 与请求坐标的距离. 只在请求带坐标时返回.
  final double? distanceMeters,

  /// 游客为 null.
  final bool? isFavorite,
  final bool? deliveryEnabled,

  /// `food` 或 `drink`.
  final String? kind,
  final List<String>? mealTimes,

  /// `UNDER_15`, `FROM_15_TO_30` 或 `OVER_30`. 没填时为 null.
  final String? priceBand,
  final List<String>? categories,

  /// 口味.
  final List<String>? tags,
  final StatDto? dineIn,
  final StatDto? delivery,

  /// 游客为 null.
  final MyRatingsDto? myRatings,
  final List<SignatureFoodDto>? signatureFoods,

  /// 搜店时因菜名命中的一道菜. 按店名或地址命中, 或不是搜索时为 null.
  final MatchedFoodDto? matchedFood,
}) {
  factory RestaurantDto.fromJson(Map<String, dynamic> json) =>
      _$RestaurantDtoFromJson(json);
}

/// 一个场景的评价统计. [rate] 为 0–1 的推荐率, 没有评价时为 null.
@JsonSerializable(createToJson: false)
class const StatDto({final double? rate, final int? count}) {
  factory StatDto.fromJson(Map<String, dynamic> json) =>
      _$StatDtoFromJson(json);
}

/// 当前用户在两个场景的评价: `RECOMMEND` 或 `NOT_RECOMMEND`, 没评过为 null.
@JsonSerializable(createToJson: false)
class const MyRatingsDto({final String? dineIn, final String? delivery}) {
  factory MyRatingsDto.fromJson(Map<String, dynamic> json) =>
      _$MyRatingsDtoFromJson(json);
}

/// 推荐卡片的招牌菜摘要. [pictureUrl] 是第一张照片.
@JsonSerializable(createToJson: false)
class const SignatureFoodDto({
  final int? id,
  final String? name,
  final double? price,
  final String? pictureUrl,

  /// 封面的圆形取景. 没有时按居中的短边内切圆显示.
  ///
  /// 菜的舞台色 `stageColor` 不读: 店的舞台色按类型和品类定, 招牌菜不改变它 (产品 4.7).
  final CoverCropDto? coverCrop,
}) {
  factory SignatureFoodDto.fromJson(Map<String, dynamic> json) =>
      _$SignatureFoodDtoFromJson(json);
}

/// 搜店时因菜名命中的菜 (`RestaurantDtos.MatchedFood`). [price] 可能为 null.
@JsonSerializable(createToJson: false)
class const MatchedFoodDto({
  final int? id,
  final String? name,
  final double? price,
}) {
  factory MatchedFoodDto.fromJson(Map<String, dynamic> json) =>
      _$MatchedFoodDtoFromJson(json);
}

/// 评价的请求体. [scene] 为 `dine_in` 或 `delivery`.
@JsonSerializable(createFactory: false)
class const RatingRequestDto({
  required final String scene,
  required final String rating,
}) {
  Map<String, dynamic> toJson() => _$RatingRequestDtoToJson(this);
}

/// 新建店铺的请求体. 所属商圈由后端按坐标计算.
///
/// - [picture] 是门头照片上传后的存储 key.
/// - 省略 [mealTimes] 时后端按午饭和晚饭处理.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const CreateRestaurantDto({
  required final String name,
  required final String address,
  required final double gcjLng,
  required final double gcjLat,

  /// 从地图候选里选的店带百度地点的 uid, 手动添加的不带.
  final String? poi,
  final String? picture,
  required final String kind,
  final List<String>? mealTimes,
  final String? priceBand,
  final List<String>? categories,
  final List<String>? tags,
  final bool? deliveryEnabled,

  /// 用户确认不是同一家后为 true, 跳过查重.
  final bool? force,
}) {
  Map<String, dynamic> toJson() => _$CreateRestaurantDtoToJson(this);
}

/// 新建店时可能重复的店 (`RestaurantDtos.Duplicate`).
///
/// [reason] 为 `poi` (同一个地图地点) 或 `name` (200 m 内同名, 忽略空白和大小写).
/// [distanceMeters] 是到新店位置的距离.
@JsonSerializable(createToJson: false)
class const ShopDuplicateDto({
  final int? id,
  final String? name,
  final String? address,
  final double? distanceMeters,
  final bool? permanentlyClosed,
  final String? reason,
}) {
  factory ShopDuplicateDto.fromJson(Map<String, dynamic> json) =>
      _$ShopDuplicateDtoFromJson(json);
}

/// 修改店铺的请求体. 省略的字段不修改.
///
/// 清除时 [poi], [picture], [priceBand] 传空串, [categories], [tags] 传空数组.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const EditRestaurantDto({
  final String? name,
  final String? address,
  final double? gcjLng,
  final double? gcjLat,
  final String? poi,
  final String? picture,
  final bool? permanentlyClosed,
  final String? kind,
  final List<String>? mealTimes,
  final String? priceBand,
  final List<String>? categories,
  final List<String>? tags,
  final bool? deliveryEnabled,
}) {
  Map<String, dynamic> toJson() => _$EditRestaurantDtoToJson(this);
}

/// 修改和恢复的结果. 内容没有变化时 [revisionId] 为 null.
@JsonSerializable(createToJson: false)
class const EditedRestaurantDto({final int? id, final int? revisionId}) {
  factory EditedRestaurantDto.fromJson(Map<String, dynamic> json) =>
      _$EditedRestaurantDtoFromJson(json);
}

/// 店铺的一条修改记录.
///
/// - [action] 为 `create`, `edit` 或 `restore`.
/// - [restoredFrom] 是恢复到的修改记录 id, 只有 `restore` 有值.
@JsonSerializable(createToJson: false)
class const RevisionDto({
  final int? id,
  final String? action,
  final RevisionEditorDto? editor,
  final int? restoredFrom,
  final List<FieldChangeDto>? changes,
  final int? createdAt,
}) {
  factory RevisionDto.fromJson(Map<String, dynamic> json) =>
      _$RevisionDtoFromJson(json);
}

/// 修改记录的编辑者. [avatar] 是头像地址.
@JsonSerializable(createToJson: false)
class const RevisionEditorDto({
  final int? id,
  final String? displayName,
  final String? avatar,
}) {
  factory RevisionEditorDto.fromJson(Map<String, dynamic> json) =>
      _$RevisionEditorDtoFromJson(json);
}

/// 一个字段的改动. `picture` 的 [from] 和 [to] 是图片地址, 其余是字段原值.
@JsonSerializable(createToJson: false)
class const FieldChangeDto({
  final String? field,
  final Object? from,
  final Object? to,
}) {
  factory FieldChangeDto.fromJson(Map<String, dynamic> json) =>
      _$FieldChangeDtoFromJson(json);
}
