/// GCJ-02 坐标系中的点. 接口参数和返回值, 导航链接都使用该坐标系, 距离也只按该坐标系计算.
///
/// 与 [WgsPoint] 是不同类型. 两种坐标混用会产生数百米的偏差.
class const GcjPoint(final double lat, final double lng) {
  @override
  bool operator ==(Object other) =>
      other is GcjPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GcjPoint($lat, $lng)';
}

/// WGS-84 坐标系中的点. 设备定位, 天地图瓦片和接口中的 GeoJSON 使用该坐标系.
class const WgsPoint(final double lat, final double lng) {
  @override
  bool operator ==(Object other) =>
      other is WgsPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'WgsPoint($lat, $lng)';
}
