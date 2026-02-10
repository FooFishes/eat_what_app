import 'package:dio/dio.dart';
import 'package:eat_what_app/core/constant/biz_code.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorInterceptor extends Interceptor {
  final void Function() _onRequireReLogin;

  ErrorInterceptor({required void Function() onRequireReLogin})
    : _onRequireReLogin = onRequireReLogin;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      handler.next(response);
      return;
    }

    final code = data['code'] as int?;

    if (code == null || code == BizCode.success.code) {
      handler.next(response);
      return;
    }

    final message = data['msg'] as String? ?? '';
    final category = BizCode.getErrorCategory(code);
    final exception = BusinessException(
      code: code,
      message: message,
      category: category,
    );

    if (BizCode.requireReLogin(code)) {
      _onRequireReLogin();
    }

    if (_shouldReportToSentry(code)) {
      // fire-and-forget 
      // 使用 .ignore() 忽略结果
      _reportBusinessError(exception, response).ignore();
    }

    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: exception,
        type: DioExceptionType.badResponse,
      ),
    );
    return;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = _convertToApiException(err);

    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        message: 'Request failed: ${err.requestOptions.path}',
        level: SentryLevel.error,
        data: {
          'method': err.requestOptions.method,
          'url': err.requestOptions.uri.toString(),
          'error_type': apiException.runtimeType.toString(),
        },
      ),
    );

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: apiException,
        type: err.type,
        stackTrace: err.stackTrace,
      ),
    );
  }

  ApiException _convertToApiException(DioException err) {
    if (err.error is ApiException) {
      return err.error as ApiException;
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return NetworkException.fromDioException(err);
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      return ServerException(
        statusCode: statusCode,
        message: _getHttpErrorMessage(statusCode),
        originalError: err,
        stackTrace: err.stackTrace,
      );
    }

    return NetworkException(
      message: err.message ?? '未知网络错误',
      originalError: err,
      stackTrace: err.stackTrace,
    );
  }

  String _getHttpErrorMessage(int statusCode) => switch (statusCode) {
    400 => '请求参数错误',
    401 => '未授权，请重新登录',
    403 => '拒绝访问',
    404 => '请求的资源不存在',
    500 => '服务器内部错误',
    502 => '网关错误',
    503 => '服务暂不可用',
    504 => '网关超时',
    _ => '服务器错误 ($statusCode)',
  };

  bool _shouldReportToSentry(int code) {
    final ignoredCodes = [];
    return !ignoredCodes.contains(code);
  }

  Future<void> _reportBusinessError(
    BusinessException e,
    Response response,
  ) async {
    await Sentry.captureException(
      e,
      withScope: (scope) {
        scope.setTag('business_code', e.code.toString());
        scope.setTag('error_category', e.category.name);
        scope.setContexts('request', {
          'url': response.requestOptions.uri.toString(),
          'method': response.requestOptions.method,
        });
      },
    );
  }
}
