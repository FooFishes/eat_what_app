import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/auth/auth_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_api.g.dart';

/// 接口分组 Auth：登录、发验证码、人机验证参数、学生认证。
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// 这个类调用的接口，契约测试逐个检查它们都在 `docs/api.openapi.yml` 里。
  static const endpoints = [
    'GET /auth/captcha/config',
    'POST /auth/phone/code',
    'POST /auth/phone/login',
    'POST /auth/login',
    'POST /auth/logout',
    'GET /auth/sdu',
    'GET /auth/sendEmail',
  ];

  /// 每次人机验证前重新拿，接口要求不缓存。
  Future<CaptchaConfigDto> captchaConfig() async => decodeJson(
    await _client.get(
      '/auth/captcha/config',
      headers: const {'Cache-Control': 'no-store'},
    ),
    CaptchaConfigDto.fromJson,
  );

  /// [captchaHeaders] 是人机验证票据的两个请求头；人机验证关闭时为空。
  Future<void> sendLoginCode(
    String mobile, {
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(
    '/auth/phone/code',
    body: {'mobile': mobile},
    headers: captchaHeaders,
  );

  Future<LoginReplyDto> phoneLogin(PhoneLoginRequestDto request) async =>
      decodeJson(
        await _client.post('/auth/phone/login', body: request.toJson()),
        LoginReplyDto.fromJson,
      );

  Future<LoginReplyDto> passwordLogin(PasswordLoginRequestDto request) async =>
      decodeJson(
        await _client.post('/auth/login', body: request.toJson()),
        LoginReplyDto.fromJson,
      );

  Future<void> logout() => _client.post('/auth/logout');

  Future<SsoStartDto> startSso() async =>
      decodeJson(await _client.get('/auth/sdu'), SsoStartDto.fromJson);

  Future<void> sendVerifyEmail(
    String email, {
    Map<String, String> captchaHeaders = const {},
  }) => _client.get(
    '/auth/sendEmail',
    query: {'email': email},
    headers: captchaHeaders,
  );
}

@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) => AuthApi(ref.watch(apiClientProvider));
