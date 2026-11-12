/// 登录设备的类型.
enum DevicePlatform {
  web('网页版'),
  ios('iPhone'),
  android('安卓'),
  unknown('其他设备');

  const new(this.label);

  final String label;
}

/// 一台已登录的设备. [current] 表示本机. [signedInAt] 是登录时间, 服务端不提供最近使用时间.
class const DeviceSession({
  required final String id,
  required final DevicePlatform platform,
  final DateTime? signedInAt,
  final bool current = false,
});
