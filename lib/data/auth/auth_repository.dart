import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/data/auth/auth_api.dart';
import 'package:eat/data/auth/auth_dto.dart';
import 'package:eat/data/consent/consent_api.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// 登录成功的结果: 会话凭证, 以及本次是否为新号码自动注册.
class const SignInResult({
  required final AuthToken token,
  required final bool newUser,
});

/// 登录, 发送验证码和学生认证.
///
/// 产品默认替所有用户同意跨站同步, 因此同意在本类中自动完成, 页面不感知.
class AuthRepository {
  AuthRepository(this._auth, this._consent);

  final AuthApi _auth;
  final ConsentApi _consent;

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

  /// 验证码登录.
  ///
  /// 新号码在此步自动注册, 因此请求携带跨站同步同意和政策版本.
  Future<SignInResult> loginWithCode(String mobile, String code) async {
    final version = await _policyVersionOrNull();
    return _login(
      () => _auth.phoneLogin(
        PhoneLoginRequestDto(
          mobile: mobile,
          code: code,
          device: _device,
          crossBorderConsent: version == null ? null : true,
          consentPolicyVersion: version,
        ),
      ),
    );
  }

  /// [account] 为手机号或用户名.
  Future<SignInResult> loginWithPassword(String account, String password) =>
      _login(
        () => _auth.passwordLogin(
          PasswordLoginRequestDto(
            userName: account,
            password: password,
            device: _device,
          ),
        ),
      );

  /// 已登录时服务端要求同意 (业务码 20005, 20006). 使用当前会话同意, 不带 proof.
  Future<bool> grantConsentForSession() async {
    await _consent.grant(policyVersion: await _consent.policyVersion());
    return true;
  }

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

  Future<void> sendVerifyEmail(String email, CaptchaTicket? ticket) =>
      _auth.sendVerifyEmail(email, captchaHeaders: ticket?.headers ?? const {});

  /// 读取政策版本. 网络错误向上抛出, 其余失败返回 null.
  ///
  /// 部分部署没有注册同意接口. 读取失败时登录请求不带同意参数.
  Future<String?> _policyVersionOrNull() async {
    try {
      return await _consent.policyVersion();
    } on AppFailure catch (e) {
      if (e.kind == FailureKind.network) rethrow;
      return null;
    }
  }

  /// 发送登录请求.
  ///
  /// 只返回临时凭证 `consentProof` 时不算成功: 先用它同意, 再用同一组参数重新登录一次.
  /// 登录参数只在本次调用中保留在内存里.
  Future<SignInResult> _login(Future<LoginReplyDto> Function() send) async {
    var reply = await send();
    if (_resultOf(reply) case final result?) return result;
    if (reply.consentProof case final proof? when proof.isNotEmpty) {
      await _consent.grant(
        policyVersion: await _consent.policyVersion(),
        proof: proof,
      );
      reply = await send();
      if (_resultOf(reply) case final result?) return result;
    }
    throw const AppFailure(FailureKind.unknown, serverMessage: 'no token');
  }

  static SignInResult? _resultOf(LoginReplyDto reply) {
    final LoginReplyDto(:tokenName, :tokenValue) = reply;
    if (tokenName == null || tokenName.isEmpty) return null;
    if (tokenValue == null || tokenValue.isEmpty) return null;
    return SignInResult(
      token: AuthToken(name: tokenName, value: tokenValue),
      newUser: reply.newUser ?? false,
    );
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(authApiProvider), ref.watch(consentApiProvider));
