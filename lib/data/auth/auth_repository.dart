import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/data/auth/auth_api.dart';
import 'package:eat/data/auth/auth_dto.dart';
import 'package:eat/data/consent/consent_api.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// 登录成功：拿到的凭证，以及这次是不是新号码自动注册。
class const SignInResult({
  required final AuthToken token,
  required final bool newUser,
});

/// 登录、发验证码和学生认证。跨站同步同意在这里自动完成，页面看不到（技术架构 9.5）。
class AuthRepository {
  AuthRepository(this._auth, this._consent);

  final AuthApi _auth;
  final ConsentApi _consent;

  static String get _device => kIsWeb ? 'WEB' : 'APP';

  /// 这一次人机验证的参数；服务端关掉了人机验证时返回 null，直接发。
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

  /// 验证码登录。新号码在这一步自动注册，所以请求一律带上跨站同步同意和政策版本。
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

  /// [account] 是手机号或用户名。
  Future<SignInResult> loginWithPassword(String account, String password) =>
      _login(
        () => _auth.passwordLogin(
          PasswordLoginRequestDto(
            username: account,
            password: password,
            device: _device,
          ),
        ),
      );

  /// 已登录时服务端要求同意（20005、20006）：用当前会话同意，不带 proof。
  Future<bool> grantConsentForSession() async {
    await _consent.grant(policyVersion: await _consent.policyVersion());
    return true;
  }

  /// 退出登录时通知服务端。失败也照常退出，所以不抛异常。
  Future<void> logout() async {
    try {
      await _auth.logout();
    } on AppFailure {
      // 本地照样清掉登录态；服务端的会话等它自己过期。
    }
  }

  /// 统一认证的学校页面地址，5 分钟内有效、只能用一次，每次点都重新拿。
  Future<Uri> ssoUrl() async {
    final url = (await _auth.startSso()).url;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'bad sso url');
    }
    return uri;
  }

  Future<void> sendVerifyEmail(String email, CaptchaTicket? ticket) =>
      _auth.sendVerifyEmail(email, captchaHeaders: ticket?.headers ?? const {});

  /// 读不到政策版本时（有的部署没有注册同意接口）照常登录，只是不带同意参数。
  Future<String?> _policyVersionOrNull() async {
    try {
      return await _consent.policyVersion();
    } on AppFailure catch (e) {
      if (e.kind == FailureKind.network) rethrow;
      return null;
    }
  }

  /// 登录只带回临时凭证 `consentProof` 时不算成功：带上它同意，再用同一组参数登录一次。
  /// 参数只在这一次调用里留在内存中。
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
