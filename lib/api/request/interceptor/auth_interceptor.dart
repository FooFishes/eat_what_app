import 'package:dio/dio.dart';
import '../../../core/constant/no_auth_urls.dart';
import '../../../util/token_util.dart';
import '../../../core/constant/biz_code.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (NoAuthUrls.contains(options.path)) {
      return handler.next(options);
    }
    final token = await TokenUtil.getToken();
    if (token != null) {
      options.headers['sa-token'] = token;
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final code = data['code'] as int? ?? 0;
      // 如果是认证相关错误，清除 Token
      final bizCode = BizCode.fromCode(code);
      if (bizCode != null && bizCode.isAuthError) {
        TokenUtil.deleteToken();
      }
    }
    // 继续传递给下一个拦截器（ErrorInterceptor 会统一处理业务异常）
    handler.next(response);
  }
}
