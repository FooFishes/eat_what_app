import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/dish_revision.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/taste.dart';

/// 校区, 即用户选择的 "在哪吃", 决定推荐和附近的范围. 只包含已开放的校区.
class const Campus({
  required final int id,
  required final String name,
  required final GcjPoint center,

  /// 是否为默认校区, 无法获取定位时将选用该校区.
  final bool isDefault = false,
});

/// 商圈: 校区周边有边界的店铺聚集区, 食堂也算作商圈.
///
/// [boundary] 是接口中 GeoJSON MultiPolygon 每个多边形的外环, 坐标系为 GCJ-02.
class const Hub({
  required final int id,
  required final String name,
  required final GcjPoint center,
  final int? campusId,
  final List<List<GcjPoint>> boundary = const [],
});

/// 店铺类型, [api] 为接口字段值, 正餐饱腹类店铺均归为美食.
enum ShopKind {
  food('food', '美食'),
  drink('drink', '甜点饮品');

  const new(this.api, this.label);

  final String api;
  final String label;

  static ShopKind? fromApi(String? value) {
    for (final kind in values) {
      if (kind.api == value) return kind;
    }
    return null;
  }
}

/// 店铺品类, [api] 为接口字段值且与界面文字一致.
///
/// 因后端按位存储且仅在末尾追加新值, [fromApi] 遇到未知值时返回 null 并由调用方忽略.
enum ShopCategory {
  rice('米饭炒菜'),
  noodles('粉面'),
  hotPot('火锅麻辣烫'),
  grill('烧烤炸串'),
  soup('汤粥'),
  fastFood('面点快餐'),
  japaneseKorean('日韩料理');

  const new(this.api);

  final String api;

  String get label => api;

  static ShopCategory? fromApi(String? value) {
    for (final category in values) {
      if (category.api == value) return category;
    }
    return null;
  }
}

/// 店铺人均价位区间, 由创建或编辑店铺的用户选填.
enum PriceBand {
  under15('UNDER_15', '¥15 以下'),
  from15To30('FROM_15_TO_30', '¥15–30'),
  over30('OVER_30', '¥30 以上');

  const new(this.api, this.label);

  final String api;
  final String label;

  static PriceBand? fromApi(String? value) {
    for (final band in values) {
      if (band.api == value) return band;
    }
    return null;
  }
}

/// 店铺评价场景 (堂食或外卖), [api] 为接口字段值.
enum RatingScene {
  dineIn('dine_in', '堂食'),
  delivery('delivery', '外卖');

  const new(this.api, this.label);

  final String api;
  final String label;
}

/// 用户对店铺在单一场景下的评价结果, [api] 为接口字段值.
enum ShopRating {
  recommend('RECOMMEND', '推荐'),
  notRecommend('NOT_RECOMMEND', '不推荐');

  const new(this.api, this.label);

  final String api;
  final String label;

  static ShopRating? fromApi(String? value) {
    for (final rating in values) {
      if (rating.api == value) return rating;
    }
    return null;
  }
}

/// 单一评价场景的统计数据.
class const ShopStat({
  /// 推荐率 (取值 0–1), 暂无评价时为 null.
  final double? rate,
  final int count = 0,
});

/// 当前用户在堂食与外卖两个场景下的评价, 未评价的场景为 null.
class const MyShopRatings({
  final ShopRating? dineIn,
  final ShopRating? delivery,
}) {
  ShopRating? of(RatingScene scene) => switch (scene) {
    RatingScene.dineIn => dineIn,
    RatingScene.delivery => delivery,
  };

  /// 仅替换 [scene] 对应的评价为 [rating], 保持另一场景不变.
  MyShopRatings withRating(RatingScene scene, ShopRating? rating) =>
      switch (scene) {
        RatingScene.dineIn => MyShopRatings(dineIn: rating, delivery: delivery),
        RatingScene.delivery => MyShopRatings(dineIn: dineIn, delivery: rating),
      };

  @override
  bool operator ==(Object other) =>
      other is MyShopRatings &&
      other.dineIn == dineIn &&
      other.delivery == delivery;

  @override
  int get hashCode => Object.hash(dineIn, delivery);
}

/// 店铺内的菜品摘要, 用于推荐卡片展示招牌菜.
///
/// [crop] 为封面的圆形取景区域, 服务端未保存时默认居中.
class const ShopDish({
  required final int id,
  required final String name,
  final double? price,

  /// 第一张照片. 没有照片时为 null.
  final String? photo,
  final CoverCrop crop = const CoverCrop(),
});

/// 新建店铺时检测到的潜在重复店铺, [distance] 为其与新店位置的距离 (单位为米).
///
/// [samePlace] 为 true 时表示位于同一地图地点, 否则表示附近同名店铺.
class const ShopDuplicate({
  required final int id,
  required final String name,
  final String address = '',
  required final int distance,
  final bool closed = false,
  final bool samePlace = false,
});

/// 来自百度地点检索的地图候选地点, 用于新建店铺, 提交时将 [uid] 作为店铺的 `poi`.
class const MapPlace({
  required final String uid,
  required final String name,
  required final String address,
  required final GcjPoint point,
});

/// 店铺信息, 店铺接口与推荐卡片均统一转换为该模型.
///
/// - [address] 为详细地址描述, 如 "万达金街 1 层".
/// - [signatures] 与 [distance] 仅推荐卡片返回, 店铺详情接口不返回招牌菜, 需由店铺页另行请求.
/// - [matchedDish] 仅在搜店结果中返回.
class const Shop({
  required final int id,
  required final String name,
  final String? address,
  required final GcjPoint point,

  /// 百度地点的 uid. 手动添加的店为 null.
  final String? poi,

  /// 门头照片.
  final String? photo,

  /// 所属商圈, 由后端按坐标计算. 不在任何商圈内时为 null.
  final int? hubId,
  final String? hubName,

  /// 所属商圈的校区. 不属于商圈或商圈没有校区时为 null.
  final int? campusId,
  required final ShopKind kind,
  final List<MealTime> mealTimes = const [],
  final PriceBand? priceBand,

  /// 店铺品类列表, 至多 2 个.
  final List<ShopCategory> categories = const [],

  /// 店铺口味标签列表, 至多 3 个.
  final List<Taste> tastes = const [],

  /// 是否有能点外卖的菜, 由服务端按菜品汇总, 不能直接修改.
  final bool deliveryEnabled = false,
  final ShopStat dineIn = const ShopStat(),
  final ShopStat delivery = const ShopStat(),

  /// 当前用户的评价. 游客为 null.
  final MyShopRatings? myRatings,

  /// 当前用户是否收藏. 游客为 null.
  final bool? favorite,

  /// 是否已关门, 已关门的店铺不会出现在附近和推荐中, 也不能继续添加菜品.
  final bool closed = false,
  final List<ShopDish> signatures = const [],

  /// 搜店时因菜名匹配命中的菜品摘要, 仅搜店结果可能有值且不包含照片.
  final ShopDish? matchedDish,

  /// 与请求坐标的距离 (单位为米), 仅在传入坐标的推荐卡片中返回.
  final int? distance,
});

/// 店铺中支持编辑且会记录在修改历史中的字段.
enum ShopField {
  name('店名'),
  address('地址描述'),

  /// 店铺坐标, 合并了接口中的经度 `gcjLng` 与纬度 `gcjLat` 两个字段.
  location('位置'),
  poi('地图地点'),
  picture('门头照片'),
  permanentlyClosed('是否关门'),
  deliveryEnabled('外卖'),
  kind('类型'),
  mealTimes('饭点'),
  priceBand('价位'),
  categories('品类'),
  tags('口味');

  const new(this.label);

  final String label;

  /// 未知字段返回 null 并由调用方忽略, 以兼容后端后续新增的可编辑字段.
  static ShopField? fromApi(String? value) => switch (value) {
    'gcjLng' || 'gcjLat' => location,
    final value? => values.asNameMap()[value],
    null => null,
  };
}

/// 店铺的一条修改记录.
///
/// - [fields] 为本次改动的字段列表, 保持后端顺序, 已去重并过滤未知字段.
/// - [restoredFrom] 是 [RevisionAction.restore] 恢复到的记录 id.
/// - 编辑者账号已删除时 [editorId] 和 [editorName] 为 null.
class const ShopRevision({
  required final int id,
  required final RevisionAction action,
  final int? editorId,
  final String? editorName,
  final String? editorAvatar,
  final int? restoredFrom,
  final List<ShopField> fields = const [],
  final DateTime? createdAt,
});
