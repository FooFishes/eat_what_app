import 'package:dio/dio.dart';
import 'package:eat_what_app/core/constant/biz_code.dart';
import 'package:eat_what_app/core/error/platform_exception.dart';

import 'api_exception.dart';

const String kDefaultErrorMessage = '操作失败，请稍后重试';

extension ApiExceptionExt on ApiException {
  /// 用户友好的错误消息
  String get userMessage => switch (this) {
    BusinessException e =>
      e.message.isNotEmpty ? e.message : kDefaultErrorMessage,
    NetworkException e => e.message,
    ServerException e => e.message,
    ParseException _ => '数据解析异常，请稍后重试',
  };

  /// 是否可重试
  bool get isRetryable => switch (this) {
    NetworkException e => e.dioExceptionType != DioExceptionType.cancel,
    ServerException e => e.statusCode >= 500,
    _ => false,
  };

  /// 是否需要重新登录
  bool get needsReLogin =>
      this is BusinessException &&
      BizCode.requireReLogin((this as BusinessException).code!);
}

String resolveUserMessage(
  Object error, {
  String fallback = kDefaultErrorMessage,
}) {
  if (error is ApiException) {
    return error.userMessage;
  }
  if (error is PlatformException) {
    return error.message;
  }
  return fallback;
}
