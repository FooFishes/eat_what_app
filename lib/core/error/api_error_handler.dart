import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'api_exception.dart';

final class ApiErrorHandler {
  static const Set<DioExceptionType> _ignoredNetworkTypes = {
    DioExceptionType.cancel,
  };

  static ApiException fromDioException(DioException error) {
    final original = error.error;
    if (original is ApiException) {
      return original;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.cancel) {
      return NetworkException.fromDioException(error);
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return ServerException(
        statusCode: statusCode,
        message: httpStatusMessage(statusCode),
        originalError: error,
        stackTrace: error.stackTrace,
      );
    }

    return NetworkException(
      message: error.message ?? '网络异常，请稍后重试',
      dioExceptionType: error.type,
      originalError: error,
      stackTrace: error.stackTrace,
    );
  }

  static String httpStatusMessage(int statusCode) => switch (statusCode) {
    400 => '请求参数错误，请稍后重试',
    401 => '登录状态已失效，请重新登录',
    403 => '当前操作无权限',
    404 => '请求资源不存在',
    408 => '请求超时，请重试',
    429 => '请求过于频繁，请稍后再试',
    500 => '服务器开小差了，请稍后重试',
    502 => '网关异常，请稍后重试',
    503 => '服务暂不可用，请稍后重试',
    504 => '服务响应超时，请稍后重试',
    _ => '服务异常($statusCode)，请稍后重试',
  };

  static bool shouldReport(ApiException error) {
    if (error is NetworkException &&
        error.dioExceptionType != null &&
        _ignoredNetworkTypes.contains(error.dioExceptionType)) {
      return false;
    }
    return true;
  }

  static void addNetworkBreadcrumb({
    required String phase,
    required ApiException exception,
    RequestOptions? requestOptions,
    Response<dynamic>? response,
    DioException? dioException,
  }) {
    final payload = _buildPayload(
      phase: phase,
      exception: exception,
      requestOptions: requestOptions,
      response: response,
      dioException: dioException,
    );

    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'http',
        category: 'network',
        message:
            '[${payload['error_layer']}] ${payload['method'] ?? '--'} ${payload['path'] ?? '--'}',
        level: exception is BusinessException
            ? SentryLevel.warning
            : SentryLevel.error,
        data: payload,
      ),
    );
  }

  static Future<void> report(
    ApiException exception, {
    required String phase,
    RequestOptions? requestOptions,
    Response<dynamic>? response,
    DioException? dioException,
  }) async {
    if (!shouldReport(exception)) {
      return;
    }

    final payload = _buildPayload(
      phase: phase,
      exception: exception,
      requestOptions: requestOptions,
      response: response,
      dioException: dioException,
    );

    await Sentry.captureException(
      exception,
      stackTrace: exception.stackTrace ?? dioException?.stackTrace,
      withScope: (scope) {
        scope.level = exception is BusinessException
            ? SentryLevel.warning
            : SentryLevel.error;
        scope.setTag('error_layer', payload['error_layer'].toString());
        scope.setTag('error_phase', phase);
        scope.setTag(
          'api_exception_type',
          payload['exception_type'].toString(),
        );

        if (payload['biz_code'] != null) {
          scope.setTag('biz_code', payload['biz_code'].toString());
        }
        if (payload['status_code'] != null) {
          scope.setTag('status_code', payload['status_code'].toString());
        }
        if (payload['trace_id'] != null) {
          scope.setTag('trace_id', payload['trace_id'].toString());
        }
        if (payload['endpoint_group'] != null) {
          scope.setTag('endpoint_group', payload['endpoint_group'].toString());
        }

        scope.setContexts('network_error', payload);
      },
    );
  }

  static Map<String, dynamic> _buildPayload({
    required String phase,
    required ApiException exception,
    RequestOptions? requestOptions,
    Response<dynamic>? response,
    DioException? dioException,
  }) {
    final RequestOptions? resolvedRequest =
        requestOptions ??
        response?.requestOptions ??
        dioException?.requestOptions;
    final int? statusCode =
        response?.statusCode ?? dioException?.response?.statusCode;

    final payload = <String, dynamic>{
      'phase': phase,
      'error_layer': _errorLayer(exception),
      'exception_type': exception.runtimeType.toString(),
      'message': exception.message,
      'biz_code': exception.code,
      'status_code': statusCode,
      'dio_type': dioException?.type.name,
      'request_id': _resolveRequestId(resolvedRequest, response),
      'trace_id': _resolveTraceId(resolvedRequest, response),
      'is_offline':
          exception is NetworkException &&
          exception.dioExceptionType == DioExceptionType.connectionError,
    };

    if (exception is BusinessException) {
      payload['error_category'] = exception.category.name;
      payload['biz_message'] = exception.message;
    }

    if (resolvedRequest != null) {
      payload['method'] = resolvedRequest.method;
      payload['path'] = resolvedRequest.path;
      payload['url'] = resolvedRequest.uri.toString();
      payload['endpoint_group'] = _resolveEndpointGroup(resolvedRequest.path);
      payload['retry_count'] = resolvedRequest.extra['retry_count'] ?? 0;
    }

    final dioMessage = dioException?.message;
    if (dioMessage != null && dioMessage.isNotEmpty) {
      payload['dio_message'] = dioMessage;
    }

    payload.removeWhere((_, value) => value == null);
    return payload;
  }

  static String _errorLayer(ApiException exception) => switch (exception) {
    BusinessException _ => 'business',
    ParseException _ => 'client_parse',
    _ => 'transport',
  };

  static String? _resolveRequestId(
    RequestOptions? request,
    Response<dynamic>? response,
  ) {
    return _headerByPriority(response?.headers, request, const [
      'x-request-id',
      'request-id',
      'requestid',
    ]);
  }

  static String? _resolveTraceId(
    RequestOptions? request,
    Response<dynamic>? response,
  ) {
    return _headerByPriority(response?.headers, request, const [
      'x-trace-id',
      'trace-id',
      'traceid',
    ]);
  }

  static String? _headerByPriority(
    Headers? responseHeaders,
    RequestOptions? request,
    List<String> keys,
  ) {
    for (final key in keys) {
      final responseValue = responseHeaders?.value(key);
      if (responseValue != null && responseValue.isNotEmpty) {
        return responseValue;
      }

      if (request == null) {
        continue;
      }
      final requestValue = _readHeader(request.headers, key);
      if (requestValue != null && requestValue.isNotEmpty) {
        return requestValue;
      }
    }
    return null;
  }

  static String? _readHeader(Map<String, dynamic> headers, String key) {
    final lowerCaseKey = key.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() != lowerCaseKey) {
        continue;
      }
      final value = entry.value;
      if (value == null) {
        return null;
      }
      return value.toString();
    }
    return null;
  }

  static String _resolveEndpointGroup(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    if (normalized.isEmpty) {
      return 'root';
    }
    final index = normalized.indexOf('/');
    if (index < 0) {
      return normalized;
    }
    return normalized.substring(0, index);
  }
}
