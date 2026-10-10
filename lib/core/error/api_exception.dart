// API 异常基类

import 'package:dio/dio.dart';
import 'package:eat_what_app/core/constant/biz_code.dart';

sealed class ApiException implements Exception {
  final String message;
  final int? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const new({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });
}

class BusinessException extends ApiException {
  final ErrorCategory category;

  const new({
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

  const new({
    required super.message,
    this.dioExceptionType,
    super.originalError,
    super.stackTrace,
  });

  factory fromDioException(DioException e) {
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout => '连接超时，请稍后重试',
      DioExceptionType.sendTimeout => '请求发送超时，请稍后重试',
      DioExceptionType.receiveTimeout => '响应超时，请稍后重试',
      DioExceptionType.connectionError => '网络连接失败，请检查网络',
      DioExceptionType.cancel => '请求已取消',
      _ => '网络异常，请稍后重试',
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

  const new({
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
  const new({required super.message, super.originalError, super.stackTrace});

  @override
  String toString() => 'ParseException(message: $message)';
}

class AuthException extends BusinessException {
  const new({
    required super.code,
    required super.message,
    required super.category,
    super.originalError,
    super.stackTrace,
  });
}
