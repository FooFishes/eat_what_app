import 'package:eat/domain/models/dish_revision.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/taste.dart';

/// 校区, 即用户选择的 "在哪吃", 决定推荐和附近的范围. 只包含已开放的校区.
class const Campus({
  required final int id,
  required final String name,
  required final GcjPoint center,

  /// 是否为默认校区. 没有定位时选择默认校区.
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

/// 店铺类型. [api] 是接口中的取值. 能吃饱的都算美食.
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

/// 店铺品类.
///
/// [api] 是接口中的取值, 与界面文字相同. 后端按位存储, 只在末尾追加新值,
/// 所以 [fromApi] 遇到不认识的值返回 null, 由调用方忽略.
enum ShopCategory {
  rice('米饭炒菜'),
  noodles('粉面'),
  hotPot('火锅麻辣烫'),
  grill('烧烤炸串'),
  soup('汤粥'),
  fastFood('面点快餐');

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

/// 店铺价位. 由新建或编辑店铺的人填写, 可以不填.
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

/// 评价的场景: 在店里吃过, 或点过外卖. [api] 是接口中的取值.
enum RatingScene {
  dineIn('dine_in', '堂食'),
  delivery('delivery', '外卖');

  const new(this.api, this.label);

  final String api;
  final String label;
}

/// 对一家店在一个场景下的评价. [api] 是接口中的取值.
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

/// 一个场景的评价统计.
class const ShopStat({
  /// 推荐率, 0–1. 没有评价时为 null.
  final double? rate,
  final int count = 0,
});

/// 当前用户在两个场景的评价. 没评过的场景为 null.
class const MyShopRatings({
  final ShopRating? dineIn,
  final ShopRating? delivery,
}) {
  ShopRating? of(RatingScene scene) => switch (scene) {
    RatingScene.dineIn => dineIn,
    RatingScene.delivery => delivery,
  };

  /// 把 [scene] 的评价换成 [rating], 另一个场景不变.
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

/// 店里的一道菜的摘要, 用于推荐卡片的招牌菜.
///
/// 摘要不含封面取景, 舞台上的盘子按居中的短边内切圆显示.
class const ShopDish({
  required final int id,
  required final String name,
  final double? price,

  /// 第一张照片. 没有照片时为 null.
  final String? photo,
});

/// 新建店时可能重复的已有店. [distance] 是到新店位置的距离, 单位米.
///
/// [samePlace] 为 true 时是同一个地图地点上的店, 否则是附近同名的店.
class const ShopDuplicate({
  required final int id,
  required final String name,
  final String address = '',
  required final int distance,
  final bool closed = false,
  final bool samePlace = false,
});

/// 地图上的一个地点, 来自百度地点检索, 是新建店的候选. [uid] 提交时作为店的 `poi`.
class const MapPlace({
  required final String uid,
  required final String name,
  required final String address,
  required final GcjPoint point,
});

/// 店铺. 店铺接口和推荐卡片都转换为本类型.
///
/// - [address] 是地址描述, 如 "万达金街 1 层".
/// - [signatures] 和 [distance] 只有推荐卡片带. 店铺接口不返回招牌菜, 店铺页另行请求.
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

  /// 至多 2 个.
  final List<ShopCategory> categories = const [],

  /// 店铺的口味, 至多 3 个.
  final List<Taste> tastes = const [],

  /// 能点外卖.
  final bool deliveryEnabled = false,
  final ShopStat dineIn = const ShopStat(),
  final ShopStat delivery = const ShopStat(),

  /// 当前用户的评价. 游客为 null.
  final MyShopRatings? myRatings,

  /// 当前用户是否收藏. 游客为 null.
  final bool? favorite,

  /// 已关门. 不出现在附近和推荐里, 不能再加菜.
  final bool closed = false,
  final List<ShopDish> signatures = const [],

  /// 与请求坐标的距离, 单位米. 只有带坐标的推荐卡片有值.
  final int? distance,
});

/// 店铺中可以编辑, 会出现在修改记录里的字段.
enum ShopField {
  name('店名'),
  address('地址描述'),

  /// 坐标. 接口中经度 `gcjLng` 和纬度 `gcjLat` 是两个字段, 合并为一项.
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

  /// 不认识的字段返回 null, 由调用方忽略. 后端新增可编辑字段时客户端可能还不认识.
  static ShopField? fromApi(String? value) => switch (value) {
    'gcjLng' || 'gcjLat' => location,
    final value? => values.asNameMap()[value],
    null => null,
  };
}

/// 店铺的一条修改记录.
///
/// - [fields] 是这次改动的字段, 按后端顺序, 已去重并去掉不认识的字段.
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
