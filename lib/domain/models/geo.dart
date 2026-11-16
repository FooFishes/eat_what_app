/// GCJ-02 坐标系坐标点. 接口出入参, 导航链接及距离计算均使用该坐标系.
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

/// WGS-84 坐标系坐标点. 设备定位使用该坐标系, 参与业务计算前需转换为 [GcjPoint].
class const WgsPoint(final double lat, final double lng) {
  @override
  bool operator ==(Object other) =>
      other is WgsPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'WgsPoint($lat, $lng)';
}
