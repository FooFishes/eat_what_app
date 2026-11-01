import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/domain/models/paged.dart';

/// 接口的 `PageResult`（`items`、`currentPage`、`hasNext`）转成 [Paged]。
///
/// 也接受直接返回的数组：`/foods/recommend` 文档写的是分页，实际返回数组（要反馈给后端）。
Paged<T> decodePage<T>(
  Object? data,
  T Function(Map<String, dynamic> json) item,
) {
  try {
    return switch (data) {
      null => const Paged.empty(),
      final List<dynamic> list => Paged(items: _items(list, item)),
      final Map<String, dynamic> page => Paged(
        items: _items(page['items'] as List<dynamic>? ?? const [], item),
        page: (page['currentPage'] as num?)?.toInt() ?? 1,
        hasNext: page['hasNext'] as bool? ?? false,
      ),
      _ => throw const FormatException('not a page'),
    };
  } on AppFailure {
    rethrow;
  } on Object catch (e) {
    throw AppFailure(FailureKind.unknown, serverMessage: '$e');
  }
}

/// `data` 是数组时逐项解析；`null` 当作空数组。
List<T> decodeList<T>(
  Object? data,
  T Function(Map<String, dynamic> json) item,
) {
  if (data == null) return const [];
  if (data is! List<dynamic>) {
    throw const AppFailure(FailureKind.unknown, serverMessage: 'not a list');
  }
  try {
    return _items(data, item);
  } on Object catch (e) {
    throw AppFailure(FailureKind.unknown, serverMessage: '$e');
  }
}

List<T> _items<T>(List<dynamic> list, T Function(Map<String, dynamic>) item) =>
    [for (final e in list) item(e as Map<String, dynamic>)];

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

/// 新增类接口返回的 `{id}`。
int decodeCreatedId(Object? data) {
  final id = data is Map ? data['id'] : null;
  if (id is num) return id.toInt();
  throw const AppFailure(FailureKind.unknown, serverMessage: 'no id');
}
