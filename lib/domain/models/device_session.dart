/// 登录设备的类型.
enum DevicePlatform {
  web('网页版'),
  ios('苹果'),
  android('安卓'),
  unknown('其他设备');

  const new(this.label);

  final String label;
}

/// 已登录设备的会话信息, [current] 表示是否为当前设备.
///
/// [name] 为服务端登记的设备型号 (如 "Pixel 8"). 服务端返回 "未知设备" 或空白时, 数据层的 deviceNameOf 将其转为 null, 界面改用平台名.
/// [signedInAt] 为登录时间, [lastActiveAt] 为最近活跃时间.
class const DeviceSession({
  required final String id,
  required final DevicePlatform platform,
  final String? name,
  final DateTime? signedInAt,
  final DateTime? lastActiveAt,
  final bool current = false,
});
