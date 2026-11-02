import 'dart:math';

/// 生成 `Idempotency-Key` 请求头的值: 随机的 UUID v4.
///
/// 后端要求键为 UUID, 并拒绝同一个键对应不同请求正文的请求.
/// 因此同一份草稿重试时沿用原键, 内容变化后生成新键.
String newIdempotencyKey([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = [for (var i = 0; i < 16; i++) r.nextInt(256)];
  bytes[6] = bytes[6] & 0x0f | 0x40;
  bytes[8] = bytes[8] & 0x3f | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')]
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
