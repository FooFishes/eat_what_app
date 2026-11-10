import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
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

  /// 封禁账号登录得到的受限会话. 账号状态仍以 `/user/info` 的 `banned` 为准.
  final bool restricted = false,
});

/// 登录, 发送验证码, 学生认证, 设置用户名和密码.
///
/// 数据跨境同意由用户确认, 本类不代替用户同意.
/// 登录需要同意时抛出业务码为 [BizCodes.consentRequired] 的 [AppFailure], 临时凭证用 [consentProofOf] 读取.
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

  /// 验证码登录. 新号码在此步自动注册.
  ///
  /// [crossBorderConsent] 为 true 表示用户已在同意面板中同意, 请求携带同意和政策版本.
  /// 注册新号码时必须携带, 否则服务端返回不带临时凭证的 [BizCodes.consentRequired].
  Future<SignInResult> loginWithCode(
    String mobile,
    String code, {
    bool crossBorderConsent = false,
  }) async {
    final version = crossBorderConsent ? await _policyVersionOrNull() : null;
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

  /// [account] 为手机号, 用户名或邮箱.
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

  /// 首次设置用户名, 可同时设置初始密码. 成功后本机和其他设备都要重新登录.
  Future<void> setUsername(String userName, String code, {String? password}) =>
      _auth.setUsername(userName: userName, code: code, newPassword: password);

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

  /// 发送登录请求. 只返回临时凭证 `consentProof` 时不算成功.
  ///
  /// 服务端要求同意时通常返回业务码 [BizCodes.consentRequired], 凭证在失败的 `data` 中.
  /// 成功外壳中只带凭证的响应也转换为同一种失败, 页面只需处理一种情况.
  Future<SignInResult> _login(Future<LoginReplyDto> Function() send) async {
    final reply = await send();
    if (_resultOf(reply) case final result?) return result;
    if (reply.consentProof case final proof? when proof.isNotEmpty) {
      throw AppFailure.fromCode(
        BizCodes.consentRequired,
        data: {'consentProof': proof},
      );
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
      restricted: reply.restricted ?? false,
    );
  }
}

/// 登录要求同意时服务端给出的临时凭证. 只用于提交同意, 不是登录凭证.
///
/// 不是要求同意的失败, 或没有凭证时返回 null.
/// 注册新号码时服务端不发凭证, 用户同意后需在注册请求中携带同意.
String? consentProofOf(AppFailure failure) => switch (failure) {
  AppFailure(
    code: BizCodes.consentRequired,
    data: {'consentProof': final String proof},
  )
      when proof.isNotEmpty =>
    proof,
  _ => null,
};

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(authApiProvider), ref.watch(consentApiProvider));
