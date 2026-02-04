import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final String? token;

  AuthInterceptor({this.token});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: Implement read token from storage
    if (token != null) {
      options.headers['sa-token'] = '$token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data as Map<String, dynamic>;
    final code = data['code'] as int;
    if (code > 20000 && code < 30000) {
      return handler.next(response);
    }
    super.onResponse(response, handler);
  }
}