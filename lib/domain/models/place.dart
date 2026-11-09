import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/geo.dart';

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
/// [boundary] 是接口中 GeoJSON MultiPolygon 每个多边形的外环, 已从 WGS-84 转成 GCJ-02.
class const Hub({
  required final int id,
  required final String name,
  required final GcjPoint center,
  final int? campusId,
  final List<List<GcjPoint>> boundary = const [],
});

/// 店铺的营业状态.
enum ShopStatus {
  open,

  /// 运营确认已关门. 不出现在附近和推荐里, 不能再加菜.
  closed,

  /// 运营决定尚未同步完成. 不当作正常营业, 也不标为已关门.
  pending,
}

/// 店铺价位, 按可见菜价格的中位数分档.
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

/// 店铺评价的四档. [api] 是接口中的取值.
enum ShopRating {
  recommend('RECOMMEND', '推荐'),
  good('GOOD', '还不错'),
  average('AVERAGE', '一般'),
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

/// 店铺响应中的菜品摘要: 招牌菜或按菜名搜索匹配到的菜.
///
/// 摘要不含封面取景, 舞台上的盘子按居中的短边内切圆显示.
class const ShopDish({
  required final int id,
  required final String name,
  final double? price,
  final String? cover,

  /// 菜品保存的舞台色. 未保存时为 null.
  final StageColor? stage,
  final int likes = 0,
});

/// 店里的口味标签及标过的人数.
class const ShopTaste({
  required final int id,
  required final String name,
  required final int count,
});

/// 店铺. [address] 是地址描述, 如 "万达金街 1 层".
class const Shop({
  required final int id,
  required final String name,
  final String? address,
  required final GcjPoint point,
  final int? hubId,
  final List<String> photos = const [],
  required final ShopStatus status,

  /// 可见菜数.
  required final int dishCount,

  /// 没有可见菜时为 null.
  final PriceBand? priceBand,

  /// 评价人数. 汇总未就绪时为 null.
  final int? ratingCount,

  /// 推荐率, 整数百分比. 评价不满 5 人或汇总未就绪时为 null.
  final int? recommendRate,

  /// 获赞最多的至多 3 道菜, 按赞数降序.
  final List<ShopDish> signatures = const [],

  /// 按关键词搜索时, 菜名匹配的至多 3 道菜.
  final List<ShopDish> matched = const [],

  /// 口味标签汇总, 按人数降序, 至多 6 个.
  final List<ShopTaste> tastes = const [],

  /// 第一道招牌菜的封面.
  final String? cover,

  /// 当前用户的评价. 未评价, 未登录或个人状态未就绪时为 null.
  final ShopRating? myRating,

  /// 当前用户是否收藏. 未登录或个人状态未就绪时为 false.
  final bool favorite = false,
}) {
  bool get closed => status == ShopStatus.closed;
}
