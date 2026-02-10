import 'package:dio/dio.dart';
import 'package:eat_what_app/core/api/model/result.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../error/api_exception.dart';
import 'interceptor/auth_interceptor.dart';
import 'interceptor/error_interceptor.dart';

class RequestClient {
  final String baseUrl = 'https://api.example.com';
  late final Dio _dio;

  RequestClient({
    required Future<String?> Function() getToken,
    required void Function() onRequireReLogin,
  }) : _dio = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 10),
           sendTimeout: const Duration(seconds: 10),
         ),
       ) {
    _setupInterceptors(getToken: getToken, onRequireReLogin: onRequireReLogin);
  }

  void _setupInterceptors({
    required Future<String?> Function() getToken,
    required void Function() onRequireReLogin,
  }) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true,
        ),
      );
    }
    _dio.interceptors.add(AuthInterceptor(getToken: getToken));
    _dio.interceptors.add(ErrorInterceptor(onRequireReLogin: onRequireReLogin));

    // Sentry 最后添加，防止被其他配置覆盖
    _dio.addSentry(
      captureFailedRequests: true,
      failedRequestStatusCodes: [
        SentryStatusCode.range(400, 404),
        SentryStatusCode.range(500, 599),
      ],
    );
  }

  // ========== 请求方法（返回 Result，不抛异常）==========

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) => _safeRequest(
    () =>
        getOrThrow(path, queryParameters: queryParameters, fromJson: fromJson),
  );

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
  }) => _safeRequest(() => postOrThrow(path, data: data, fromJson: fromJson));

  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
  }) => _safeRequest(() => putOrThrow(path, data: data, fromJson: fromJson));

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
  }) => _safeRequest(() => deleteOrThrow(path, data: data, fromJson: fromJson));

  // ========== 请求方法（抛异常）==========

  Future<T> getOrThrow<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) => _request(
    () => _dio.get(path, queryParameters: queryParameters, options: options),
    fromJson: fromJson,
  );

  Future<T> postOrThrow<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) => _request(
    () => _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ),
    fromJson: fromJson,
  );

  Future<T> putOrThrow<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) => _request(
    () => _dio.put(path, data: data, options: options),
    fromJson: fromJson,
  );

  Future<T> deleteOrThrow<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) => _request(
    () => _dio.delete(path, data: data, options: options),
    fromJson: fromJson,
  );

  // ========== 内部方法 ==========

  Future<T> _request<T>(
    Future<Response> Function() request, {
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await request();
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];
        if (fromJson != null && data != null) {
          return fromJson(data);
        }
        return data as T;
      }

      return responseData as T;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      throw ParseException(
        message: '数据解析失败: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Result<T>> _safeRequest<T>(Future<T> Function() request) async {
    try {
      return Success(await request());
    } on ApiException catch (e) {
      return Failure(e);
    }
  }
}
