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
/// [boundary] 是接口中 GeoJSON MultiPolygon 每个多边形的外环.
class const Hub({
  required final int id,
  required final String name,
  required final GcjPoint center,
  final int? campusId,
  final List<List<WgsPoint>> boundary = const [],
});

/// 店铺. [address] 是地址描述, 如 "万达金街 1 层".
class const Shop({
  required final int id,
  required final String name,
  final String? address,
  required final GcjPoint point,
  final int? hubId,
  final List<String> photos = const [],
});
