import 'api_exception.dart';
import '/core/constant/biz_code.dart';

extension ApiExceptionExt on ApiException {
  /// 用户友好的错误消息
  String get userMessage => switch (this) {
    BusinessException e => e.message,
    NetworkException _ => '网络连接失败，请检查网络',
    ServerException e =>
      e.statusCode >= 500 ? '服务器开小差了，请稍后重试' : '请求失败 (${e.statusCode})',
    ParseException _ => '数据异常，请联系客服',
  };

  /// 是否可重试
  bool get isRetryable =>
      this is NetworkException ||
      (this is ServerException && (this as ServerException).statusCode >= 500);

  /// 是否需要重新登录
  bool get needsReLogin =>
      this is BusinessException &&
      BizCode.requireReLogin((this as BusinessException).code!);
}
