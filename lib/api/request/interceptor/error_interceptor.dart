import 'package:dio/dio.dart';
import 'package:eat_what_app/core/constant/biz_code.dart';
import '../../exception/business_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final code = data['code'] as int? ?? 0;

      if (code != BizCode.success.code) {
        final message = data['message'] as String? ?? '业务错误';
        // 直接抛出 BusinessException
        throw BusinessException(
          code: code,
          message: message,
          uri: response.requestOptions.uri.toString(),
          timestamp:
              data['timestamp'] as int? ??
              DateTime.now().millisecondsSinceEpoch,
        );
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 插入错误原因以及访问链接
    switch (err.type) {
      case DioExceptionType.cancel:
        err = err.copyWith(error: RequestError.cancel(err));
        break;
      case DioExceptionType.connectionTimeout:
        err = err.copyWith(error: RequestError.connectionTimeout(err));
        break;
      case DioExceptionType.sendTimeout:
        err = err.copyWith(error: RequestError.sendTimeout(err));
        break;
      case DioExceptionType.receiveTimeout:
        err = err.copyWith(error: RequestError.receiveTimeout(err));
        break;
      case DioExceptionType.badResponse:
        err = err.copyWith(error: RequestError.badResponse(err));
        break;
      default:
        break;
    }
    super.onError(err, handler);
  }
}

/// 请求异常
class RequestError {
  final int code;
  final String message;
  final int timestamp;

  RequestError({
    required this.code,
    required this.message,
    required this.timestamp,
  });

  factory RequestError.cancel(DioException error) {
    return RequestError(
      code: -1,
      message: '用户取消',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory RequestError.connectionTimeout(DioException error) {
    return RequestError(
      code: -2,
      message: '连接超时 at ${error.requestOptions.uri}',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory RequestError.sendTimeout(DioException error) {
    return RequestError(
      code: -3,
      message: '发送数据超时 at ${error.requestOptions.uri}',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory RequestError.receiveTimeout(DioException error) {
    return RequestError(
      code: -4,
      message: '接收数据超时 at ${error.requestOptions.uri}',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory RequestError.badResponse(DioException error) {
    return RequestError(
      code: -5,
      message:
          '错误码${error.response?.statusCode ?? 500}'
          ' at ${error.requestOptions.uri}',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  String toString() {
    return '$code: $message at $timestamp';
  }
}
