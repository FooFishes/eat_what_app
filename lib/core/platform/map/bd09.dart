import 'dart:math' as math;

import 'package:eat/core/platform/map/eat_map.dart';

/// GCJ-02 与百度 BD-09 坐标系互转工具, 仅 Web 端 JS API GL 使用 BD-09, App 端原生 SDK 直接接收 GCJ-02.
///
/// 采用百度公开的 `bd_encrypt` / `bd_decrypt` 公式, 其中正算为精确映射, 反算为亚米级近似.
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
