import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/data/auth/auth_api.dart';
import 'package:eat/data/auth/auth_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// 登录成功的结果, 包含会话凭证以及本次是否为新号码自动注册.
class const SignInResult({
  required final AuthToken token,
  final bool newUser = false,
});

/// 负责登录, 发送验证码, 学生认证以及设置用户名和密码.
///
/// 隐私政策需由用户亲自确认, 本类不代为同意, 登录请求仅携带调用方传入的政策版本.
class AuthRepository {
  AuthRepository(this._auth);

  final AuthApi _auth;

  static String get _device => kIsWeb ? 'WEB' : 'APP';

  /// 获取本次人机验证参数. 若服务端关闭了人机验证则返回 null, 调用方无需验证即可发送请求.
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

  /// 使用手机验证码登录, 新号码在此步自动注册.
  ///
  /// [policyVersion] 为用户确认的隐私政策版本, 服务端尚未发布政策时为 null.
  /// 服务端会在核销验证码前校验协议确认状态, 因此收到要求确认协议的业务码时, 可用同一验证码重试.
  ///
  /// [deletionKey] 为申请注销时保存在本机的撤销凭据, 若账号处于注销冷静期内, 随登录一并撤销注销.
  Future<SignInResult> loginWithCode(
    String mobile,
    String code, {
    String? policyVersion,
    String? deletionKey,
  }) async => _resultOf(
    await _auth.phoneLogin(
      PhoneLoginRequestDto(
        mobile: mobile,
        code: code,
        device: _device,
        policyVersion: policyVersion,
        deletionKey: deletionKey,
      ),
    ),
  );

  /// 查询服务端是否开启了 App 的一键登录.
  Future<bool> oneClickEnabled() async =>
      (await _auth.oneClickConfig()).enabled ?? false;

  /// 使用运营商一键登录, 新号码在此步自动注册. [accessToken] 为用户在授权页确认后得到的取号凭证.
  ///
  /// 服务端会在核销凭证前校验协议确认状态, 因此收到要求确认协议的业务码时, 可用同一凭证重试;
  /// 若因其他原因失败, 该凭证即作废, 重试时需重新唤起授权页.
  ///
  /// 该方式不支持撤销注销: 若账号处于注销冷静期内, 将返回 `BizCodes.accountDeletionPending`, 需改用验证码或密码登录.
  Future<SignInResult> loginWithOneClick(
    String accessToken, {
    String? policyVersion,
  }) async => _resultOf(
    await _auth.oneClickLogin(
      OneClickLoginRequestDto(
        accessToken: accessToken,
        policyVersion: policyVersion,
      ),
    ),
  );

  /// 使用账号密码登录. [account] 可为手机号, 用户名或邮箱; [ticket] 为人机验证票据, 仅在服务端要求时传入.
  ///
  /// [deletionKey] 同 [loginWithCode].
  Future<SignInResult> loginWithPassword(
    String account,
    String password, {
    String? policyVersion,
    String? deletionKey,
    CaptchaTicket? ticket,
  }) async => _resultOf(
    await _auth.passwordLogin(
      PasswordLoginRequestDto(
        userName: account,
        password: password,
        device: _device,
        policyVersion: policyVersion,
        deletionKey: deletionKey,
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

  /// 获取学校统一认证页地址. 由于该地址具有时效且仅可使用一次, 每次点击均需重新请求.
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

  /// 用验证码设置或修改密码. 成功后其他设备需重新登录, 本机不受影响.
  Future<void> resetPassword(String code, String newPassword) =>
      _auth.resetPassword(code: code, newPassword: newPassword);

  /// 用旧密码修改密码. 成功后其他设备需重新登录, 本机不受影响.
  Future<void> changePassword(String oldPassword, String newPassword) =>
      _auth.changePassword(oldPassword: oldPassword, newPassword: newPassword);

  /// 首次设置用户名, 并可同时设置初始密码. 本机保持登录状态; 若同时设置了密码, 则其他设备需重新登录.
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
