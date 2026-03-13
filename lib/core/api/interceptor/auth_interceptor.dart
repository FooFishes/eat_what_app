import 'package:dio/dio.dart';
import '../../constant/urls.dart';

class AuthInterceptor extends Interceptor {
  final Future<String?> Function() getToken;

  AuthInterceptor({required this.getToken});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (Urls.isNoAuth(options.path)) {
      return handler.next(options);
    }
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['satoken'] = 'Bearer $token';
    }
    return handler.next(options);
  }
}
