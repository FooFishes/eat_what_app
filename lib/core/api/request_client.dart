import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eat_what_app/core/api/model/result.dart';
import 'package:flutter/foundation.dart';

import '../constant/urls.dart';
import '../error/api_error_handler.dart';
import '../error/api_exception.dart';
import 'interceptor/auth_interceptor.dart';
import 'interceptor/error_interceptor.dart';

class RequestClient {
  late final Dio _dio;

  RequestClient({
    required Future<String?> Function() getToken,
    required void Function() onRequireReLogin,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: Urls.baseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 10),
           sendTimeout: kIsWeb ? null : const Duration(seconds: 10),
         ),
       ) {
    _setupInterceptors(getToken: getToken, onRequireReLogin: onRequireReLogin);
  }

  void _setupInterceptors({
    required Future<String?> Function() getToken,
    required void Function() onRequireReLogin,
  }) {
    _dio.interceptors.add(AuthInterceptor(getToken: getToken));
    _dio.interceptors.add(ErrorInterceptor(onRequireReLogin: onRequireReLogin));

    if (kDebugMode) {
      // Put logger at the end so request headers include auth headers set by interceptors.
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true,
        ),
      );
    }
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
    Future<Response<dynamic>> Function() request, {
    T Function(dynamic json)? fromJson,
  }) async {
    Response<dynamic>? response;
    try {
      response = await request();
      return _parseResponseData(response.data, fromJson: fromJson);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiErrorHandler.fromDioException(error);
    } catch (error, stackTrace) {
      final parseException = ParseException(
        message: '数据解析失败，请稍后重试',
        originalError: error,
        stackTrace: stackTrace,
      );

      ApiErrorHandler.addNetworkBreadcrumb(
        phase: 'response_parse',
        exception: parseException,
        requestOptions: response?.requestOptions,
        response: response,
      );
      ApiErrorHandler.report(
        parseException,
        phase: 'response_parse',
        requestOptions: response?.requestOptions,
        response: response,
      ).ignore();

      throw parseException;
    }
  }

  T _parseResponseData<T>(
    dynamic responseData, {
    T Function(dynamic json)? fromJson,
  }) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (fromJson != null && data != null) {
        return fromJson(data);
      }
      return data as T;
    }

    return responseData as T;
  }

  Future<Result<T>> _safeRequest<T>(Future<T> Function() request) async {
    try {
      return Success(await request());
    } on ApiException catch (error) {
      return Failure(error);
    }
  }
}
