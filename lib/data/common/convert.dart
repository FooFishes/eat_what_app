import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/domain/models/paged.dart';

// TODO: /foods/recommend 文档声明返回 `PageResult`, 实际返回数组. 后端统一格式后删除数组分支.
/// 把接口的 `PageResult` (`items`, `currentPage`, `hasNext`) 转换为 [Paged].
///
/// 也接受数组, 视为只有一页.
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

// TODO: 后端未确认图片字段是完整 URL 还是存储 key. 确认后只保留对应的一种处理.
/// 把图片字段解析为可加载的地址. 空串视为没有图片, 返回 null.
///
/// 图片字段可能是完整 URL, 也可能是存储 key.
/// 是 key 时拼接 [assetBaseUrl]; 未配置 [assetBaseUrl] 时原样返回.
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

/// 解析新增类接口返回的 `{id}`.
int decodeCreatedId(Object? data) {
  final id = data is Map ? data['id'] : null;
  if (id is num) return id.toInt();
  throw const AppFailure(FailureKind.unknown, serverMessage: 'no id');
}
