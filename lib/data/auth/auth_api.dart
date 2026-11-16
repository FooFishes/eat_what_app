import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/auth/auth_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_api.g.dart';

/// AuthApi 调用的接口路径, 相对于业务接口地址.
abstract final class AuthEndpoints {
  static const captchaConfig = '/auth/captcha/config';
  static const phoneCode = '/auth/phone/code';
  static const phoneLogin = '/auth/phone/login';
  static const oneClickConfig = '/auth/phone/one-click/config';
  static const oneClickLogin = '/auth/phone/one-click/login';
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const sdu = '/auth/sdu';
  static const sduConfirm = '/auth/sdu/confirm';
  static const sendEmail = '/auth/sendEmail';
  static const verifyEmail = '/auth/verifyEmail';
  static const checkUsername = '/auth/checkUsername';
  static const passwordCode = '/auth/password/code';
  static const passwordReset = '/auth/password/reset';
  static const changePassword = '/auth/changePassword';
  static const setUsername = '/auth/username/set';
}

/// 接口分组 Auth 和 OneClickAuth: 登录, 发送验证码, 人机验证参数, 学生认证, 设置用户名和密码.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// 人机验证参数. 接口要求不缓存, 每次验证前重新请求.
  Future<CaptchaConfigDto> captchaConfig() async => decodeJson(
    await _client.get(
      AuthEndpoints.captchaConfig,
      headers: const {'Cache-Control': 'no-store'},
    ),
    CaptchaConfigDto.fromJson,
  );

  /// [captchaHeaders] 为人机验证票据的两个请求头, 人机验证关闭时为空.
  Future<void> sendLoginCode(
    String mobile, {
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(
    AuthEndpoints.phoneCode,
    body: {'mobile': mobile},
    headers: captchaHeaders,
  );

  Future<LoginReplyDto> phoneLogin(PhoneLoginRequestDto request) async =>
      decodeJson(
        await _client.post(AuthEndpoints.phoneLogin, body: request.toJson()),
        LoginReplyDto.fromJson,
      );

  /// 服务端是否开启了 App 的一键登录.
  Future<OneClickConfigDto> oneClickConfig() async => decodeJson(
    await _client.get(AuthEndpoints.oneClickConfig),
    OneClickConfigDto.fromJson,
  );

  Future<LoginReplyDto> oneClickLogin(OneClickLoginRequestDto request) async =>
      decodeJson(
        await _client.post(AuthEndpoints.oneClickLogin, body: request.toJson()),
        LoginReplyDto.fromJson,
      );

  /// 同一账号密码错误次数过多后, 服务端要求带 [captchaHeaders], 否则返回 `BizCodes.captchaMissing`.
  Future<LoginReplyDto> passwordLogin(
    PasswordLoginRequestDto request, {
    Map<String, String> captchaHeaders = const {},
  }) async => decodeJson(
    await _client.post(
      AuthEndpoints.login,
      body: request.toJson(),
      headers: captchaHeaders,
    ),
    LoginReplyDto.fromJson,
  );

  Future<void> logout() => _client.post(AuthEndpoints.logout);

  /// [client] 决定学校认证页完成后的重定向目标: `app` 回到 App, `web` 回到网页.
  Future<SsoStartDto> startSso({required String client}) async => decodeJson(
    await _client.get(AuthEndpoints.sdu, query: {'client': client}),
    SsoStartDto.fromJson,
  );

  /// 完成统一认证. [ticket] 取自回跳地址, 只能由发起认证的账号使用一次.
  Future<void> confirmSso(String ticket) =>
      _client.post(AuthEndpoints.sduConfirm, body: {'ticket': ticket});

  /// 邮箱放在请求体中, 不进入服务端的访问日志.
  Future<void> sendVerifyEmail(
    String email, {
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(
    AuthEndpoints.sendEmail,
    body: {'email': email},
    headers: captchaHeaders,
  );

  /// 提交认证邮件链接中的 [token]. token 必须属于当前登录的账号.
  Future<void> verifyEmail(String token) =>
      _client.post(AuthEndpoints.verifyEmail, body: {'token': token});

  /// 用户名是否可用. 已被占用时失败, 业务码为 `BizCodes.usernameTaken`.
  Future<void> checkUsername(String userName) =>
      _client.post(AuthEndpoints.checkUsername, body: {'userName': userName});

  /// 向当前账号绑定的手机发送验证码, 供设置用户名和设置或修改密码使用.
  Future<void> sendAccountCode({
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(AuthEndpoints.passwordCode, headers: captchaHeaders);

  /// 用验证码设置或修改密码, 不需要旧密码.
  Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) => _client.post(
    AuthEndpoints.passwordReset,
    body: {'code': code, 'newPassword': newPassword},
  );

  /// 用旧密码修改密码. 账号还没设过密码时失败, 业务码为 `BizCodes.passwordNotSet`.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) => _client.post(
    AuthEndpoints.changePassword,
    body: {'oldPassword': oldPassword, 'newPassword': newPassword},
  );

  /// 首次设置用户名. [newPassword] 为 null 时不设置密码.
  ///
  /// 本机保持登录. 同时设置密码时, 其他设备要重新登录.
  Future<void> setUsername({
    required String userName,
    required String code,
    String? newPassword,
  }) => _client.post(
    AuthEndpoints.setUsername,
    body: {'userName': userName, 'code': code, 'newPassword': ?newPassword},
  );
}

@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) => AuthApi(ref.watch(apiClientProvider));
