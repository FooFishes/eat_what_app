import 'dart:math' as math;

import 'package:eat/core/platform/map/eat_map.dart';

/// GCJ-02 与百度 BD-09 的互转. 只有 Web 的 JS API GL 用 BD-09, App 的 SDK 直接收 GCJ-02.
///
/// 公式是百度公开的 bd_encrypt / bd_decrypt. 正算精确; 反算是近似, 误差在米级以下.
abstract final class Bd09 {
  static const _xPi = math.pi * 3000 / 180;

  static MapLatLng fromGcj(MapLatLng p) {
    final x = p.lng;
    final y = p.lat;
    final z = math.sqrt(x * x + y * y) + 0.00002 * math.sin(y * _xPi);
    final theta = math.atan2(y, x) + 0.000003 * math.cos(x * _xPi);
    return MapLatLng(z * math.sin(theta) + 0.006, z * math.cos(theta) + 0.0065);
  }

  static MapLatLng toGcj(MapLatLng p) {
    final x = p.lng - 0.0065;
    final y = p.lat - 0.006;
    final z = math.sqrt(x * x + y * y) - 0.00002 * math.sin(y * _xPi);
    final theta = math.atan2(y, x) - 0.000003 * math.cos(x * _xPi);
    return MapLatLng(z * math.sin(theta), z * math.cos(theta));
  }
}
