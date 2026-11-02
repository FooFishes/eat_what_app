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

/// 商圈 (`HubVO`).
///
/// [boundary] 为 GeoJSON, 坐标系是 WGS-84, 与 [gcjLng] 和 [gcjLat] 的 GCJ-02 不同. 接口契约如此规定.
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

/// 餐厅 (`RestaurantVO`).
@JsonSerializable(createToJson: false)
class const RestaurantDto({
  final int? id,
  final String? name,
  final String? address,
  final double? gcjLng,
  final double? gcjLat,
  final int? hubId,
  final List<String>? pictureUrl,

  /// `OPEN`, `CLOSED` 或 `SYNC_PENDING`.
  required final String operatingStatus,

  /// 运营确认已关门时为 true. [operatingStatus] 为 `SYNC_PENDING` 时为 null.
  final bool? permanentlyClosed,
  required final int visibleFoodCount,

  /// `UNDER_15`, `FROM_15_TO_30` 或 `OVER_30`. 没有可见菜时为 null.
  final String? priceBand,

  /// 评价人数. 汇总缺失或过期时为 null.
  final int? ratingCount,

  /// 推荐率, 整数百分比. 评价不满 5 人或汇总未就绪时为 null.
  final int? recommendationRate,

  /// 获赞最多的至多 3 道菜.
  required final List<RestaurantFoodDto> signatureFoods,

  /// 带关键词搜索时, 菜名匹配的至多 3 道菜. 不带关键词时为空.
  required final List<RestaurantFoodDto> matchedFoods,

  /// 口味标签按人数汇总的至多 6 个.
  required final List<RestaurantTasteDto> publicTastes,

  /// 第一道招牌菜的封面. 没有招牌菜时为 null.
  final String? coverUrl,

  /// 当前用户的评价: `RECOMMEND`, `GOOD`, `AVERAGE` 或 `NOT_RECOMMEND`. 未评价或个人状态未就绪时为 null.
  final String? myRating,

  /// 当前用户是否收藏. 未登录或个人状态未就绪时为 null.
  final bool? isFavorite,
}) {
  factory RestaurantDto.fromJson(Map<String, dynamic> json) =>
      _$RestaurantDtoFromJson(json);
}

/// 餐厅响应中的菜品摘要 (`RestaurantFoodSummary`).
@JsonSerializable(createToJson: false)
class const RestaurantFoodDto({
  final int? id,
  final String? name,
  final double? price,
  final String? coverUrl,
  final String? stageColor,
  final int? likesCount,
}) {
  factory RestaurantFoodDto.fromJson(Map<String, dynamic> json) =>
      _$RestaurantFoodDtoFromJson(json);
}

/// 餐厅响应中的口味标签汇总 (`RestaurantTasteSummary`).
@JsonSerializable(createToJson: false)
class const RestaurantTasteDto({
  final int? tagId,
  final String? name,
  final int? taggerCount,
}) {
  factory RestaurantTasteDto.fromJson(Map<String, dynamic> json) =>
      _$RestaurantTasteDtoFromJson(json);
}

/// 店铺评价的请求体和响应 (`RestaurantRatingDTO`, `RestaurantRatingView`). 撤回后响应中的 [rating] 为 null.
@JsonSerializable(includeIfNull: false)
class const RestaurantRatingDto({final String? rating}) {
  factory RestaurantRatingDto.fromJson(Map<String, dynamic> json) =>
      _$RestaurantRatingDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantRatingDtoToJson(this);
}

/// 新增餐厅的结果 (`CreatedResourceVO`).
@JsonSerializable(createToJson: false)
class const CreatedRestaurantDto({
  final int? id,

  /// 审核状态, 如 `PENDING`. 服务端未启用内容审核时不返回, 店铺直接公开.
  final String? moderationStatus,
}) {
  factory CreatedRestaurantDto.fromJson(Map<String, dynamic> json) =>
      _$CreatedRestaurantDtoFromJson(json);
}

/// 新增餐厅的请求体 (`RestaurantDTO`). [address] 为地址描述, 如 "万达金街 1 层".
@JsonSerializable(createFactory: false, includeIfNull: false)
class const CreateRestaurantDto({
  required final String name,
  required final String address,
  required final double gcjLng,
  required final double gcjLat,
  final int? hubId,
  final List<String>? pictureUrl,
}) {
  Map<String, dynamic> toJson() => _$CreateRestaurantDtoToJson(this);
}
