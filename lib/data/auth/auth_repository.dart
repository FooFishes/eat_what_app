import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/data/auth/auth_api.dart';
import 'package:eat/data/auth/auth_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// 登录成功的结果: 会话凭证, 以及本次是否为新号码自动注册.
class const SignInResult({
  required final AuthToken token,
  final bool newUser = false,
});

/// 登录, 发送验证码, 学生认证, 设置用户名和密码.
///
/// 隐私政策由用户确认, 本类不代替用户同意. 登录请求携带调用方给出的政策版本.
class AuthRepository {
  AuthRepository(this._auth);

  final AuthApi _auth;

  static String get _device => kIsWeb ? 'WEB' : 'APP';

  /// 本次人机验证的参数. 服务端关闭人机验证时返回 null, 调用方直接发送请求.
  Future<CaptchaParams?> captchaParams() async {
    final config = await _auth.captchaConfig();
    if (config.enabled != true) return null;
    final CaptchaConfigDto(
      :appId,
      :scriptUrl,
      :aidEncrypted,
      :aidEncryptedType,
    ) = config;
    if (appId == null || scriptUrl == null || aidEncrypted == null) {
      throw const AppFailure(
        FailureKind.unknown,
        serverMessage: 'bad captcha config',
      );
    }
    return CaptchaParams(
      appId: appId,
      scriptUrl: scriptUrl,
      aidEncrypted: aidEncrypted,
      aidEncryptedType: aidEncryptedType ?? 'cbc',
    );
  }

  Future<void> sendLoginCode(String mobile, CaptchaTicket? ticket) =>
      _auth.sendLoginCode(mobile, captchaHeaders: ticket?.headers ?? const {});

  /// 验证码登录. 新号码在此步自动注册.
  ///
  /// [policyVersion] 是用户同意的隐私政策版本, 服务端还没发布政策时为 null.
  /// 服务端在核销验证码之前校验同意, 因此收到要求同意的业务码时可以用同一个验证码重试.
  Future<SignInResult> loginWithCode(
    String mobile,
    String code, {
    String? policyVersion,
  }) async => _resultOf(
    await _auth.phoneLogin(
      PhoneLoginRequestDto(
        mobile: mobile,
        code: code,
        device: _device,
        policyVersion: policyVersion,
      ),
    ),
  );

  /// [account] 为手机号, 用户名或邮箱. [ticket] 是人机验证的票据, 服务端要求时才需要.
  Future<SignInResult> loginWithPassword(
    String account,
    String password, {
    String? policyVersion,
    CaptchaTicket? ticket,
  }) async => _resultOf(
    await _auth.passwordLogin(
      PasswordLoginRequestDto(
        userName: account,
        password: password,
        device: _device,
        policyVersion: policyVersion,
      ),
      captchaHeaders: ticket?.headers ?? const {},
    ),
  );

  /// 退出登录时通知服务端. 通知失败不影响退出, 因此不抛出异常.
  Future<void> logout() async {
    try {
      await _auth.logout();
    } on AppFailure {
      // 调用方仍会清除本地登录态. 服务端会话等待自然过期.
    }
  }

  /// 学校统一认证页的地址. 地址有时效且只能使用一次, 因此每次点击都重新请求.
  Future<Uri> ssoUrl() async {
    final url = (await _auth.startSso(client: kIsWeb ? 'web' : 'app')).url;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'bad sso url');
    }
    return uri;
  }

  /// 用统一认证回跳地址中的 [ticket] 完成认证.
  Future<void> confirmSso(String ticket) => _auth.confirmSso(ticket);

  Future<void> sendVerifyEmail(String email, CaptchaTicket? ticket) =>
      _auth.sendVerifyEmail(email, captchaHeaders: ticket?.headers ?? const {});

  /// 用认证邮件链接中的 [token] 完成邮箱认证.
  Future<void> verifyEmail(String token) => _auth.verifyEmail(token);

  Future<void> checkUsername(String userName) => _auth.checkUsername(userName);

  /// 向当前账号绑定的手机发送验证码, 用于设置用户名和设置或修改密码.
  Future<void> sendAccountCode(CaptchaTicket? ticket) =>
      _auth.sendAccountCode(captchaHeaders: ticket?.headers ?? const {});

  /// 用验证码设置或修改密码. 成功后其他设备要重新登录, 本机不受影响.
  Future<void> resetPassword(String code, String newPassword) =>
      _auth.resetPassword(code: code, newPassword: newPassword);

  /// 用旧密码修改密码. 成功后其他设备要重新登录, 本机不受影响.
  Future<void> changePassword(String oldPassword, String newPassword) =>
      _auth.changePassword(oldPassword: oldPassword, newPassword: newPassword);

  /// 首次设置用户名, 可同时设置初始密码. 本机保持登录, 同时设置密码时其他设备要重新登录.
  Future<void> setUsername(String userName, String code, {String? password}) =>
      _auth.setUsername(userName: userName, code: code, newPassword: password);

  static SignInResult _resultOf(LoginReplyDto reply) {
    final LoginReplyDto(:tokenName, :tokenValue) = reply;
    if (tokenName == null ||
        tokenName.isEmpty ||
        tokenValue == null ||
        tokenValue.isEmpty) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'no token');
    }
    return SignInResult(
      token: AuthToken(name: tokenName, value: tokenValue),
      newUser: reply.newUser ?? false,
    );
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(authApiProvider));
