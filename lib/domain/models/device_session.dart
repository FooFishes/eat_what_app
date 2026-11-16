/// 登录设备的类型.
enum DevicePlatform {
  web('网页版'),
  ios('iPhone'),
  android('安卓'),
  unknown('其他设备');

  const new(this.label);

  final String label;
}

/// 已登录设备的会话信息, [current] 表示是否为当前设备.
///
/// [name] 为设备名称 (如 "Pixel 8", "Chrome · macOS"), 服务端未识别时为 null.
/// [signedInAt] 为登录时间, [lastActiveAt] 为最近活跃时间.
class const DeviceSession({
  required final String id,
  required final DevicePlatform platform,
  final String? name,
  final DateTime? signedInAt,
  final DateTime? lastActiveAt,
  final bool current = false,
});
