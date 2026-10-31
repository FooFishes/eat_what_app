import 'package:eat/domain/models/geo.dart';

/// 校区：「在哪吃」，决定推荐和附近的范围（产品 4.1）。只列已开放的。
class const Campus({
  required final int id,
  required final String name,
  required final GcjPoint center,

  /// 没有定位时选它。
  final bool isDefault = false,
});

/// 商圈：校区周边一片有边界的店铺聚集区，食堂也算（产品 4.1）。
///
/// [boundary] 是接口 GeoJSON MultiPolygon 的外环，按 WGS-84 读（技术架构待确认 A3）。
class const Hub({
  required final int id,
  required final String name,
  required final GcjPoint center,
  final int? campusId,
  final List<List<WgsPoint>> boundary = const [],
});

/// 一家店（产品 4.2）。[address] 是地址描述，如「万达金街 1 层」。
class const Shop({
  required final int id,
  required final String name,
  final String? address,
  required final GcjPoint point,
  final int? hubId,
  final List<String> photos = const [],
});
