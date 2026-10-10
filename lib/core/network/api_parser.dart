import 'package:eat_what_app/core/constant/biz_code.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/core/network/models/api_response.dart';

/// 负责解析所有 {code, msg, data} 结构的接口响应
final class ApiParser {
  const new _();

  /// 解析公共外壳 {code, msg, data}, 返回 data 部分
  /// 仅供 RequestClient 内部调用
  static T? unwrap<T>(dynamic raw, {required T Function(Object? data) parser}) {
    // 判断 JSON 的 Fast Fail
    if (raw is! Map<String, dynamic>) {
      throw ParseException(message: "无效的返回格式", originalError: raw);
    }

    // 判断 业务码 的 Fast Fail
    final rawCode = raw['code'];
    if (rawCode is! int) {
      throw ParseException(message: "响应中不包含业务码", originalError: raw);
    }

    // 判断 返回信息, 添加默认值
    final message = (raw['msg'] as String?)?.trim() ?? '请求失败，请稍后重试';

    // 判断 业务是否成功 的 Fast Fail
    if (rawCode != BizCode.success.code) {
      if (BizCode.requireReLogin(rawCode)) {
        throw AuthException(
          code: rawCode,
          message: message,
          category: BizCode.getErrorCategory(rawCode),
          originalError: raw,
        );
      }
      throw BusinessException(
        code: rawCode,
        message: message,
        category: BizCode.getErrorCategory(rawCode),
        originalError: raw,
      );
    }

    // 解析 Response
    try {
      final response = ApiResponse<T>.fromJson(raw, parser);
      return response.data;
    } on Exception catch (e, stackTrace) {
      if (e is ApiException) rethrow;
      throw ParseException(
        message: "数据解析失败",
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ── data 部分的转换工具 ──────────────────────────────

  /// 将 data 解析为一个 Object (`Map<String, dynamic>` -> T)
  static T parseObject<T>(
    Object? data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return fromJson(requireMap(data));
  }

  /// 将 data 解析为 `List<T>`
  static List<T> parseList<T>(
    Object? data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (data is! List) {
      throw ParseException(message: '响应格式错误：期望 List', originalError: data);
    }
    return data.map((item) => fromJson(requireMap(item))).toList();
  }

  /// 将 data 解析为分页数据
  static PaginatedData<T> parsePage<T>(
    Object? data, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    final json = requireMap(data);

    final currentPage = json['currentPage'];
    final totalPages = json['totalPages'];
    final totalItems = json['totalItems'];
    final hasNext = json['hasNext'];

    if (currentPage is! int ||
        totalPages is! int ||
        totalItems is! int ||
        hasNext is! bool) {
      throw ParseException(message: '分页响应格式错误', originalError: json);
    }

    final itemsRaw = json['items'];
    if (itemsRaw is! List) {
      throw ParseException(
        message: '分页响应格式错误：items 期望 List',
        originalError: itemsRaw,
      );
    }

    final items = itemsRaw.map((item) => fromJson(requireMap(item))).toList();

    return PaginatedData<T>(
      currentPage: currentPage,
      items: items,
      totalPages: totalPages,
      totalItems: totalItems,
      hasNext: hasNext,
    );
  }

  /// 确保 data 是 `Map<String, dynamic>`
  static Map<String, dynamic> requireMap(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw ParseException(
        message: '数据格式错误：期望 Map<String, dynamic>',
        originalError: raw,
      );
    }
    return raw;
  }
}
