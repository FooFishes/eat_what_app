import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/auth/auth_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_api.g.dart';

/// 接口分组 Auth: 登录, 发送验证码, 人机验证参数, 学生认证, 设置用户名和密码.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// 本类调用的接口. 契约测试逐个检查它们是否在 `docs/api.openapi.yml` 中.
  static const endpoints = [
    'GET /auth/captcha/config',
    'POST /auth/phone/code',
    'POST /auth/phone/login',
    'POST /auth/login',
    'POST /auth/logout',
    'GET /auth/sdu',
    'GET /auth/sendEmail',
    'POST /auth/checkUsername',
    'POST /auth/password/code',
    'POST /auth/password/reset',
    'POST /auth/changePassword',
    'POST /auth/username/set',
  ];

  /// 人机验证参数. 接口要求不缓存, 每次验证前重新请求.
  Future<CaptchaConfigDto> captchaConfig() async => decodeJson(
    await _client.get(
      '/auth/captcha/config',
      headers: const {'Cache-Control': 'no-store'},
    ),
    CaptchaConfigDto.fromJson,
  );

  /// [captchaHeaders] 为人机验证票据的两个请求头, 人机验证关闭时为空.
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

  /// [client] 决定学校认证页完成后的重定向目标: `app` 回到 App, `web` 回到网页.
  Future<SsoStartDto> startSso({required String client}) async => decodeJson(
    await _client.get('/auth/sdu', query: {'client': client}),
    SsoStartDto.fromJson,
  );

  Future<void> sendVerifyEmail(
    String email, {
    Map<String, String> captchaHeaders = const {},
  }) => _client.get(
    '/auth/sendEmail',
    query: {'email': email},
    headers: captchaHeaders,
  );

  /// 用户名是否可用. 已被占用时失败, 业务码为 `BizCodes.usernameTaken`.
  Future<void> checkUsername(String userName) =>
      _client.post('/auth/checkUsername', query: {'userName': userName});

  /// 向当前账号绑定的手机发送验证码, 供设置用户名和设置或修改密码使用.
  Future<void> sendAccountCode({
    Map<String, String> captchaHeaders = const {},
  }) => _client.post('/auth/password/code', headers: captchaHeaders);

  /// 用验证码设置或修改密码, 不需要旧密码.
  Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) => _client.post(
    '/auth/password/reset',
    body: {'code': code, 'newPassword': newPassword},
  );

  /// 用旧密码修改密码. 账号还没设过密码时失败, 业务码为 `BizCodes.passwordNotSet`.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) => _client.post(
    '/auth/changePassword',
    body: {'oldPassword': oldPassword, 'newPassword': newPassword},
  );

  /// 首次设置用户名. [newPassword] 为 null 时不设置密码. 成功后所有设备都要重新登录.
  Future<void> setUsername({
    required String userName,
    required String code,
    String? newPassword,
  }) => _client.post(
    '/auth/username/set',
    body: {'userName': userName, 'code': code, 'newPassword': ?newPassword},
  );
}

@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) => AuthApi(ref.watch(apiClientProvider));
