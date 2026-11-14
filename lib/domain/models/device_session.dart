/// 登录设备的类型.
enum DevicePlatform {
  web('网页版'),
  ios('iPhone'),
  android('安卓'),
  unknown('其他设备');

  const new(this.label);

  final String label;
}

/// 一台已登录的设备. [current] 表示本机.
///
/// [name] 是设备名, 如 "Pixel 8", "Chrome · macOS", 服务端不知道时为 null.
/// [signedInAt] 是登录时间, [lastActiveAt] 是最近使用时间.
class const DeviceSession({
  required final String id,
  required final DevicePlatform platform,
  final String? name,
  final DateTime? signedInAt,
  final DateTime? lastActiveAt,
  final bool current = false,
});
