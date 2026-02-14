import 'package:dio/dio.dart';
import '../../constant/no_auth_urls.dart';

class AuthInterceptor extends Interceptor {
  final Future<String?> Function() getToken;

  AuthInterceptor({required this.getToken});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (NoAuthUrls.contains(options.path)) {
      return handler.next(options);
    }
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['sa-token'] = token;
    }
    return handler.next(options);
  }
}
