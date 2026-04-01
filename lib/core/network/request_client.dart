import 'package:dio/dio.dart';
import 'package:eat_what_app/core/network/api_parser.dart';
import 'package:eat_what_app/core/network/interceptors/auth_interceptor.dart';
import 'package:eat_what_app/core/network/interceptors/error_interceptor.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_error_handler.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:flutter/foundation.dart';

/// data 部分的解析器, 入参已经是 {code, msg, data} 中的 data
typedef DataParser<T> = T Function(Object? data);

class RequestClient {
  final Dio _dio;
  final Future<void> Function()? _clearSession;

  RequestClient._(this._dio, this._clearSession);

  factory RequestClient({
    required Future<String?> Function() getToken,
    required Future<void> Function() clearSession,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Urls.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(AuthInterceptor(getToken: getToken));
    dio.interceptors.add(ErrorInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
        ),
      );
    }

    return RequestClient._(dio, clearSession);
  }

  factory RequestClient.raw({BaseOptions? options}) {
    final dio = Dio(
      options ??
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
          ),
    );

    dio.interceptors.add(ErrorInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
        ),
      );
    }

    return RequestClient._(dio, null);
  }

  // ── 标准业务接口 (自动解析 code/msg/data) ──────────────

  Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required DataParser<T> parser,
    Options? options,
  }) async {
    return _request<T>(
      () => _dio.get(path, queryParameters: queryParameters, options: options),
      parser: parser,
    );
  }

  Future<T?> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required DataParser<T> parser,
    Options? options,
  }) async {
    return _request<T>(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      parser: parser,
    );
  }

  Future<T?> put<T>(
    String path, {
    dynamic data,
    required DataParser<T> parser,
    Options? options,
  }) async {
    return _request<T>(
      () => _dio.put(path, data: data, options: options),
      parser: parser,
    );
  }

  Future<T?> delete<T>(
    String path, {
    dynamic data,
    required DataParser<T> parser,
    Options? options,
  }) async {
    return _request<T>(
      () => _dio.delete(path, data: data, options: options),
      parser: parser,
    );
  }

  /// 不关心返回值, 只确认业务码成功
  Future<void> postVoid(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _request<Object?>(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      parser: (_) => null,
    );
  }

  Future<void> deleteVoid(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _request<Object?>(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      parser: (_) => null,
    );
  }

  // ── Raw 接口 (不经过 code/msg/data 解析) ──────────────

  Future<void> putRaw(String url, {dynamic data, Options? options}) async {
    try {
      await _dio.put(url, data: data, options: options);
    } on DioException catch (error) {
      throw ApiErrorHandler.fromDioException(error);
    }
  }

  // ── 内部实现 ──────────────────────────────────────────

  Future<T?> _request<T>(
    Future<Response<dynamic>> Function() send, {
    required DataParser<T> parser,
  }) async {
    Response<dynamic>? response;
    try {
      response = await send();
      return ApiParser.unwrap<T>(response.data, parser: parser);
    } on AuthException {
      await _clearSession?.call();
      rethrow;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiErrorHandler.fromDioException(error);
    } catch (error, stackTrace) {
      throw ParseException(
        message: '网络响应解析失败，请稍后重试',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }
}
