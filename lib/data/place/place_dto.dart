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

/// 商圈信息.
///
/// [boundary] 为 GeoJSON MultiPolygon, 与 [gcjLng], [gcjLat] 均采用 GCJ-02 坐标系; 无边界数据时为 null.
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

/// GeoJSON 几何对象; `Point` 的坐标格式为 `[经度, 纬度]`, `MultiPolygon` 按多边形, 环, 点三层嵌套.
@JsonSerializable(createToJson: false)
class const GeoJsonDto({final String? type, final List<dynamic>? coordinates}) {
  factory GeoJsonDto.fromJson(Map<String, dynamic> json) =>
      _$GeoJsonDtoFromJson(json);
}

/// 店铺数据结构 (`RestaurantDtos.Restaurant`), 同时用于解析推荐卡片 (`RecommendDtos.Card`).
///
/// 推荐卡片字段为店铺的子集并额外附带 [signatureFoods], 而普通店铺接口不返回该字段.
@JsonSerializable(createToJson: false)
class const RestaurantDto({
  final int? id,
  final String? name,
  final String? address,
  final double? gcjLng,
  final double? gcjLat,

  /// 百度地图地点的 uid, 手动创建的店铺为 null.
  final String? poi,

  /// 门头照片的地址.
  final String? pictureUrl,
  final bool? permanentlyClosed,
  final int? hubId,
  final String? hubName,
  final int? campusId,

  /// 与请求坐标的距离 (米), 仅在请求携带坐标时返回.
  final double? distanceMeters,

  /// 游客状态下为 null.
  final bool? isFavorite,

  /// 是否有可外卖的菜品 (不限饭点), 由服务端按菜品汇总, 只读. 外卖在菜品上设置.
  final bool? deliveryEnabled,

  /// `food` 或 `drink`.
  final String? kind,
  final List<String>? mealTimes,

  /// 人均价格区间 (`UNDER_15`, `FROM_15_TO_30` 或 `OVER_30`), 未设置时为 null.
  final String? priceBand,
  final List<String>? categories,

  /// 口味标签.
  final List<String>? tags,
  final StatDto? dineIn,
  final StatDto? delivery,

  /// 游客状态下为 null.
  final MyRatingsDto? myRatings,
  final List<SignatureFoodDto>? signatureFoods,

  /// 搜索时因菜名命中的代表菜品; 若非搜索请求或仅命中店名与地址则为 null.
  final MatchedFoodDto? matchedFood,
}) {
  factory RestaurantDto.fromJson(Map<String, dynamic> json) =>
      _$RestaurantDtoFromJson(json);
}

/// 单个消费场景的评价统计; [rate] 为 0–1 之间的推荐率, 尚无评价时为 null.
@JsonSerializable(createToJson: false)
class const StatDto({final double? rate, final int? count}) {
  factory StatDto.fromJson(Map<String, dynamic> json) =>
      _$StatDtoFromJson(json);
}

/// 当前用户在堂食与外卖场景下的评价 (`RECOMMEND` 或 `NOT_RECOMMEND`), 未评价的场景为 null.
@JsonSerializable(createToJson: false)
class const MyRatingsDto({final String? dineIn, final String? delivery}) {
  factory MyRatingsDto.fromJson(Map<String, dynamic> json) =>
      _$MyRatingsDtoFromJson(json);
}

/// 推荐卡片中的代表菜摘要 (后端 `RecommendDtos.SignatureFood`), [pictureUrl] 为其首张照片地址.
///
/// 代表菜是当前场景和饭点供应的菜里评分最高的几道, 不一定是招牌菜, 字段名沿用旧的. [signature] 表示被标为招牌菜.
@JsonSerializable(createToJson: false)
class const SignatureFoodDto({
  final int? id,
  final String? name,
  final double? price,
  final String? pictureUrl,

  /// 封面的圆形取景参数, 缺失时默认按居中的短边内切圆裁剪.
  ///
  /// 店铺舞台色由店铺类型与品类决定, 不受招牌菜影响, 因此不读取菜品的 `stageColor`.
  final CoverCropDto? coverCrop,
  final bool? signature,
  final DishRatingDto? rating,
}) {
  factory SignatureFoodDto.fromJson(Map<String, dynamic> json) =>
      _$SignatureFoodDtoFromJson(json);
}

/// 搜索店铺时因菜名命中的菜品摘要 (`RestaurantDtos.MatchedFood`), [price] 可能为 null.
@JsonSerializable(createToJson: false)
class const MatchedFoodDto({
  final int? id,
  final String? name,
  final double? price,
}) {
  factory MatchedFoodDto.fromJson(Map<String, dynamic> json) =>
      _$MatchedFoodDtoFromJson(json);
}

/// 店铺评价请求体, [scene] 取值为 `dine_in` 或 `delivery`.
@JsonSerializable(createFactory: false)
class const RatingRequestDto({
  required final String scene,
  required final String rating,
}) {
  Map<String, dynamic> toJson() => _$RatingRequestDtoToJson(this);
}

/// 新建店铺的请求体, 所属商圈由服务端根据坐标自动计算.
///
/// - [picture] 为门头照片上传后得到的存储 key.
/// - 若省略 [mealTimes], 服务端默认视为覆盖午饭与晚饭时段.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const CreateRestaurantDto({
  required final String name,
  required final String address,
  required final double gcjLng,
  required final double gcjLat,

  /// 从地图候选列表中选择的店铺需携带百度地点 uid, 手动创建时为 null.
  final String? poi,
  final String? picture,
  required final String kind,
  final List<String>? mealTimes,
  final String? priceBand,
  final List<String>? categories,
  final List<String>? tags,

  /// 用户确认与查重结果并非同一店铺后置为 true, 以跳过重复校验.
  final bool? force,
}) {
  Map<String, dynamic> toJson() => _$CreateRestaurantDtoToJson(this);
}

/// 查重返回的疑似重复店铺 (`RestaurantDtos.Duplicate`).
///
/// [reason] 为 `poi` (同一地图地点) 或 `name` (200 m 内同名, 忽略空白与大小写); [distanceMeters] 为其与新建位置的距离 (米).
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

/// 修改店铺的请求体, 省略的字段保持原值不变.
///
/// 需清空字段时, [poi], [picture], [priceBand] 传入空字符串, [categories], [tags] 传入空列表.
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
}) {
  Map<String, dynamic> toJson() => _$EditRestaurantDtoToJson(this);
}

/// 店铺修改或恢复操作的结果; 若内容未发生实际变更, [revisionId] 为 null.
@JsonSerializable(createToJson: false)
class const EditedRestaurantDto({final int? id, final int? revisionId}) {
  factory EditedRestaurantDto.fromJson(Map<String, dynamic> json) =>
      _$EditedRestaurantDtoFromJson(json);
}

/// 店铺单条修改记录.
///
/// - [action] 取值为 `create`, `edit` 或 `restore`.
/// - [restoredFrom] 为恢复目标版本的记录 id, 仅当 [action] 为 `restore` 时有值.
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

/// 修改记录的编辑者信息, [avatar] 为头像 URL.
@JsonSerializable(createToJson: false)
class const RevisionEditorDto({
  final int? id,
  final String? displayName,
  final String? avatar,
}) {
  factory RevisionEditorDto.fromJson(Map<String, dynamic> json) =>
      _$RevisionEditorDtoFromJson(json);
}

/// 单个字段的变更记录; 当字段为 `picture` 时 [from] 和 [to] 为图片 URL, 其余字段为原值.
@JsonSerializable(createToJson: false)
class const FieldChangeDto({
  final String? field,
  final Object? from,
  final Object? to,
}) {
  factory FieldChangeDto.fromJson(Map<String, dynamic> json) =>
      _$FieldChangeDtoFromJson(json);
}
