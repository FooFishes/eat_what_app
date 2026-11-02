import 'dart:convert';
import 'dart:math';

/// 换发会话用的恢复凭据: 32 字节密码学随机值, 编码为不带填充的 Base64URL, 共 43 个字符.
///
/// 下线其他设备和换绑手机时生成, 只保存在内存中. 同一次操作重试时沿用, 不写入日志和 URL.
String newRecoveryCapability([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = [for (var i = 0; i < 32; i++) r.nextInt(256)];
  return base64Url.encode(bytes).replaceAll('=', '');
}
