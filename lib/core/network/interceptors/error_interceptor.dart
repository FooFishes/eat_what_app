import 'package:dio/dio.dart';
import 'package:eat_what_app/core/error/api_error_handler.dart';

class ErrorInterceptor extends Interceptor {
  // 标记是否已经上报
  static const String _sentryReportedKey = '_error_reported';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = ApiErrorHandler.fromDioException(err);
    final alreadyReported =
        err.requestOptions.extra[_sentryReportedKey] ?? false;

    if (!alreadyReported) {
      ApiErrorHandler.addNetworkBreadcrumb(
        phase: 'transport_error',
        exception: exception,
        requestOptions: err.requestOptions,
        response: err.response,
        dioException: err,
      );
    }

    if (ApiErrorHandler.shouldReport(exception)) {
      err.requestOptions.extra[_sentryReportedKey] = true;
      ApiErrorHandler.report(
        exception,
        phase: 'transport_error',
        requestOptions: err.requestOptions,
        response: err.response,
        dioException: err,
      ).ignore(); // 使用 ignore 明确标识忽略 Future 及其返回值
    }

    handler.next(err);
  }
}
