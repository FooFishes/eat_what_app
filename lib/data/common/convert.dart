import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/domain/models/paged.dart';

/// 把接口的 `PageResult` (`items`, `currentPage`, `hasNext`) 转换为 [Paged].
Paged<T> decodePage<T>(
  Object? data,
  T Function(Map<String, dynamic> json) item,
) {
  try {
    return switch (data) {
      null => const Paged.empty(),
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

/// 逐项解析数组形式的 `data`. `null` 视为空数组.
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

/// 把接口中的 Unix 毫秒时间戳转换为本地时间. 缺失或不大于 0 时返回 null.
DateTime? dateFromMillis(int? millis) => millis == null || millis <= 0
    ? null
    : DateTime.fromMillisecondsSinceEpoch(millis);

/// 把接口中的 ISO 8601 时间转换为本地时间. 缺失或无法解析时返回 null.
DateTime? dateFromIso(String? value) =>
    value == null ? null : DateTime.tryParse(value)?.toLocal();

/// 图片字段. 空串视为没有图片, 返回 null.
///
/// `avatar`, `pictureUrl` 和 `coverUrl` 都是可直接展示的完整地址, 为有时效的预签名 URL.
/// 后端对空的存储 key 原样返回空串, 不返回 null.
String? imageUrl(String? value) =>
    value == null || value.isEmpty ? null : value;

/// 解析新增类接口返回的 `{id}`.
int decodeCreatedId(Object? data) {
  final id = data is Map ? data['id'] : null;
  if (id is num) return id.toInt();
  throw const AppFailure(FailureKind.unknown, serverMessage: 'no id');
}
