import 'package:dio/dio.dart';
import 'interceptor/auth_interceptor.dart';
import 'interceptor/error_interceptor.dart';

class RequestClient {
  final String baseUrl = 'https://api.example.com';
  late final Dio _dio;
  String? token;

  static RequestClient? _instance;
  static RequestClient get instance => _instance ??= RequestClient._internal();

  
  RequestClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl, 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(AuthInterceptor(token: token));
    _dio.interceptors.add(ErrorInterceptor());
    _dio.interceptors.add(LogInterceptor(
      request: true,
      responseBody: true,
      responseHeader: true,
      requestHeader: true,
    ));
  }

  Future<T?> get<T> (String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get<T>(baseUrl + path, queryParameters: queryParameters);
    return response.data;
  }
  Future<T?> post<T> (String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.post<T>(baseUrl + path, data: data, queryParameters: queryParameters);
    return response.data;
  }
  Future<T?> put<T> (String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.put<T>(baseUrl + path, data: data, queryParameters: queryParameters);
    return response.data;
  }
  Future<T?> delete<T> (String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.delete<T>(baseUrl + path, queryParameters: queryParameters);
    return response.data;
  }
}
