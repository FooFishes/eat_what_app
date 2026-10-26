/// 接口里的 Unix 毫秒转成本地时间；没有值或者是 0 时为 null。
DateTime? dateFromMillis(int? millis) => millis == null || millis <= 0
    ? null
    : DateTime.fromMillisecondsSinceEpoch(millis);

/// 图片字段可能是完整地址，也可能只是存储的 key（技术架构待确认 A3）：是 key 时拼上
/// [assetBaseUrl]，没配前缀就原样返回。空串当作没有图片。
String? resolveImageUrl(String? value, String assetBaseUrl) {
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('http://') ||
      value.startsWith('https://') ||
      assetBaseUrl.isEmpty) {
    return value;
  }
  final base = assetBaseUrl.endsWith('/')
      ? assetBaseUrl.substring(0, assetBaseUrl.length - 1)
      : assetBaseUrl;
  return value.startsWith('/') ? '$base$value' : '$base/$value';
}
