/// GCJ-02（火星坐标系）的一个点：接口参数和返回、导航链接都用它，距离也只按它算。
///
/// 和 [WgsPoint] 是两个类型，混用会差几百米（技术架构 14.1）。
class const GcjPoint(final double lat, final double lng) {
  @override
  bool operator ==(Object other) =>
      other is GcjPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GcjPoint($lat, $lng)';
}

/// WGS-84 的一个点：设备定位、天地图瓦片、接口里的 GeoJSON 用它。
class const WgsPoint(final double lat, final double lng) {
  @override
  bool operator ==(Object other) =>
      other is WgsPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'WgsPoint($lat, $lng)';
}
