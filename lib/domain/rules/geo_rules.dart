import 'dart:math' as math;

import 'package:eat/domain/models/geo.dart';

/// 坐标转换, 距离计算与距离文本格式化工具.
///
/// - WGS-84 转 GCJ-02 使用公开的偏移算法. 境外坐标不做偏移, 原样返回.
/// - 接口的坐标都是 GCJ-02, 不需要反向转换.
abstract final class GeoRules {
  static const _a = 6378245.0;
  static const _ee = 0.00669342162296594323;
  static const _earthRadius = 6371008.8;

  static GcjPoint toGcj(WgsPoint p) {
    if (_outOfChina(p.lat, p.lng)) return GcjPoint(p.lat, p.lng);
    final (dLat, dLng) = _offset(p.lat, p.lng);
    return GcjPoint(p.lat + dLat, p.lng + dLng);
  }

  /// 两点之间的球面距离, 单位为米.
  static double distance(GcjPoint a, GcjPoint b) {
    final dLat = _rad(b.lat - a.lat);
    final dLng = _rad(b.lng - a.lng);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.lat)) *
            math.cos(_rad(b.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadius * math.asin(math.min(1, math.sqrt(h)));
  }

  /// 距离的显示文字, 如 "320 m" "1.2 km".
  ///
  /// 1 km 以内按 10 米取整. 1–10 km 保留一位小数. 10 km 及以上取整.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      final rounded = math.max(10, (meters / 10).round() * 10);
      return rounded >= 1000 ? '1 km' : '$rounded m';
    }
    final km = meters / 1000;
    if (km >= 10) return '${km.round()} km';
    final text = km.toStringAsFixed(1);
    return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text} km';
  }

  /// 算作在校区附近的距离上限, 单位为米.
  ///
  /// 用户离校区中心超过该值时不显示距离, 改为显示商圈名, 推荐也改用校区的坐标; 附近页只显示中心在该范围内的商圈.
  static const maxDistanceFromCampus = 5000.0;

  /// 从 [me] 到 [target] 的距离文字. 没有定位或用户离 [campusCenter] 过远时返回 null.
  static String? distanceLabel({
    required GcjPoint? me,
    required GcjPoint? target,
    GcjPoint? campusCenter,
  }) {
    if (me == null || target == null) return null;
    return meterLabel(distance(me, target), me: me, campusCenter: campusCenter);
  }

  /// 接口计算的距离 [meters] 的显示文字. 规则与 [distanceLabel] 相同.
  static String? meterLabel(
    double? meters, {
    required GcjPoint? me,
    GcjPoint? campusCenter,
  }) {
    if (meters == null || me == null) return null;
    if (campusCenter != null &&
        distance(me, campusCenter) > maxDistanceFromCampus) {
      return null;
    }
    return formatDistance(meters);
  }

  static double _rad(double degrees) => degrees * math.pi / 180;

  static bool _outOfChina(double lat, double lng) =>
      lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271;

  static (double, double) _offset(double lat, double lng) {
    final x = lng - 105;
    final y = lat - 35;
    var dLat =
        -100 +
        2 * x +
        3 * y +
        0.2 * y * y +
        0.1 * x * y +
        0.2 * math.sqrt(x.abs());
    dLat +=
        (20 * math.sin(6 * x * math.pi) + 20 * math.sin(2 * x * math.pi)) *
        2 /
        3;
    dLat +=
        (20 * math.sin(y * math.pi) + 40 * math.sin(y / 3 * math.pi)) * 2 / 3;
    dLat +=
        (160 * math.sin(y / 12 * math.pi) + 320 * math.sin(y * math.pi / 30)) *
        2 /
        3;
    var dLng =
        300 + x + 2 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(x.abs());
    dLng +=
        (20 * math.sin(6 * x * math.pi) + 20 * math.sin(2 * x * math.pi)) *
        2 /
        3;
    dLng +=
        (20 * math.sin(x * math.pi) + 40 * math.sin(x / 3 * math.pi)) * 2 / 3;
    dLng +=
        (150 * math.sin(x / 12 * math.pi) + 300 * math.sin(x / 30 * math.pi)) *
        2 /
        3;
    final radLat = _rad(lat);
    var magic = math.sin(radLat);
    magic = 1 - _ee * magic * magic;
    final sqrtMagic = math.sqrt(magic);
    dLat = (dLat * 180) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * math.pi);
    dLng = (dLng * 180) / (_a / sqrtMagic * math.cos(radLat) * math.pi);
    return (dLat, dLng);
  }
}
