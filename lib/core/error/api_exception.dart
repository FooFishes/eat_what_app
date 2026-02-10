// API 异常基类

import 'package:dio/dio.dart';
import 'package:eat_what_app/core/constant/biz_code.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

sealed class ApiException implements Exception {
  final String message;
  final int? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const ApiException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  Future<void> reportToSentry({Map<String, dynamic>? extra}) async {
    await Sentry.captureException(
      this,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('error_type', runtimeType.toString());
        if (code != null) {
          scope.setTag('business_code', code.toString());
        }
        if (extra != null && extra.isNotEmpty) {
          scope.setContexts('details', extra);
        }
      },
    );
  }
}

class BusinessException extends ApiException {
  final ErrorCategory category;

  const BusinessException({
    required int super.code,
    required super.message,
    required this.category,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() =>
      'BusinessException: $message (Code: $code, Category: $category)';
}

class NetworkException extends ApiException {
  final DioExceptionType? dioExceptionType;

  const NetworkException({
    required super.message,
    this.dioExceptionType,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.fromDioException(DioException e) {
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout => '连接超时',
      DioExceptionType.sendTimeout => '请求超时',
      DioExceptionType.receiveTimeout => '响应超时',
      DioExceptionType.connectionError => '网络连接失败',
      DioExceptionType.cancel => '请求已取消',
      _ => '网络异常',
    };
    return NetworkException(
      message: message,
      dioExceptionType: e.type,
      originalError: e,
      stackTrace: e.stackTrace,
    );
  }

  @override
  String toString() =>
      'NetworkException(type: $dioExceptionType, message: $message)';
}

class ServerException extends ApiException {
  final int statusCode;

  const ServerException({
    required super.message,
    required this.statusCode,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, message: $message)';
}

class ParseException extends ApiException {
  const ParseException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'ParseException(message: $message)';
}
