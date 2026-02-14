import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eat_what_app/core/constant/biz_code.dart';
import 'package:eat_what_app/core/error/api_error_handler.dart';
import 'package:eat_what_app/core/error/api_exception.dart';

class ErrorInterceptor extends Interceptor {
  static const Duration _reLoginCooldown = Duration(seconds: 1);
  static const String _sentryReportedKey = '_network_error_reported';

  final void Function() _onRequireReLogin;
  DateTime? _lastReLoginAt;

  ErrorInterceptor({required void Function() onRequireReLogin})
    : _onRequireReLogin = onRequireReLogin;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      handler.next(response);
      return;
    }

    final code = _readBusinessCode(payload);
    if (code == null) {
      final exception = ParseException(
        message: '响应格式错误：缺少业务码 code',
        originalError: payload,
      );
      _captureAndReject(
        exception: exception,
        phase: 'response_parse',
        requestOptions: response.requestOptions,
        response: response,
        handler: handler,
      );
      return;
    }

    if (code == BizCode.success.code) {
      handler.next(response);
      return;
    }

    final exception = BusinessException(
      code: code,
      message: _readBusinessMessage(payload),
      category: BizCode.getErrorCategory(code),
      originalError: payload,
    );

    _handleReLogin(code);

    _captureAndReject(
      exception: exception,
      phase: 'business_error',
      requestOptions: response.requestOptions,
      response: response,
      handler: handler,
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = ApiErrorHandler.fromDioException(err);
    final alreadyReported = _wasReported(err.requestOptions);

    if (!alreadyReported) {
      ApiErrorHandler.addNetworkBreadcrumb(
        phase: 'transport_error',
        exception: exception,
        requestOptions: err.requestOptions,
        response: err.response,
        dioException: err,
      );

      if (ApiErrorHandler.shouldReport(exception)) {
        _markAsReported(err.requestOptions);
        ApiErrorHandler.report(
          exception,
          phase: 'transport_error',
          requestOptions: err.requestOptions,
          response: err.response,
          dioException: err,
        ).ignore();
      }
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: exception,
        type: err.type,
        stackTrace: err.stackTrace,
      ),
    );
  }

  int? _readBusinessCode(Map<String, dynamic> payload) {
    final rawCode = payload['code'];
    if (rawCode is int) {
      return rawCode;
    }
    return null;
  }

  String _readBusinessMessage(Map<String, dynamic> payload) {
    final rawMessage = payload['msg'];
    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      return rawMessage;
    }
    return '请求失败，请稍后重试';
  }

  void _handleReLogin(int code) {
    if (!BizCode.requireReLogin(code)) {
      return;
    }

    final now = DateTime.now();
    final last = _lastReLoginAt;
    if (last != null && now.difference(last) < _reLoginCooldown) {
      return;
    }

    _lastReLoginAt = now;
    _onRequireReLogin();
  }

  void _captureAndReject({
    required ApiException exception,
    required String phase,
    required RequestOptions requestOptions,
    required Response<dynamic> response,
    required ResponseInterceptorHandler handler,
  }) {
    ApiErrorHandler.addNetworkBreadcrumb(
      phase: phase,
      exception: exception,
      requestOptions: requestOptions,
      response: response,
    );

    if (ApiErrorHandler.shouldReport(exception)) {
      _markAsReported(requestOptions);
      ApiErrorHandler.report(
        exception,
        phase: phase,
        requestOptions: requestOptions,
        response: response,
      ).ignore();
    }

    handler.reject(
      DioException(
        requestOptions: requestOptions,
        response: response,
        error: exception,
        type: DioExceptionType.badResponse,
        stackTrace: exception.stackTrace,
      ),
    );
  }

  bool _wasReported(RequestOptions requestOptions) {
    return requestOptions.extra[_sentryReportedKey] == true;
  }

  void _markAsReported(RequestOptions requestOptions) {
    requestOptions.extra[_sentryReportedKey] = true;
  }
}
