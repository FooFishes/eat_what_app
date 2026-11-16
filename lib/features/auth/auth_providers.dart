import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/number_auth/number_auth.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/data/cancellation/cancellation_repository.dart';
import 'package:eat/state/captcha_gate.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/cross_border_consent.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// 登录页的协议勾选状态.
///
/// 勾选同时同意隐私政策, 用户协议和个人信息出境说明. 手机号登录和密码登录都要求先勾选.
/// 登录请求携带服务端当前的政策版本, 登录成功后写入本机的同意记录.
@Riverpod(keepAlive: true)
class LoginAgreement extends _$LoginAgreement {
  @override
  bool build() => false;

  void set({required bool agreed}) => state = agreed;
}

/// 一次登录表单提交或发送验证码的结果. 页面据此就地显示提示.
sealed class AuthFormEvent {
  const AuthFormEvent();
}

/// 操作失败. [failure] 决定提示显示的位置.
final class AuthFormFailed extends AuthFormEvent {
  const AuthFormFailed(this.failure);

  final AppFailure failure;
}

/// 验证码发送过于频繁. 页面弹出对话框提示何时可以重试, 并提供 "用密码登录".
final class AuthCodeLimited extends AuthFormEvent {
  const AuthCodeLimited(this.failure);

  /// 限流失败. [AppFailure.retryHint] 给出何时可以重试.
  final AppFailure failure;
}

/// 手机号登录页的状态: 验证码重发倒计时, 提交状态, 最近一次失败.
class const PhoneLoginState({
  final DateTime? resendAt,
  final bool sending = false,
  final bool submitting = false,
  final AuthFormEvent? event,
});

/// 验证码的重发间隔.
const resendInterval = Duration(seconds: 60);

@riverpod
class PhoneLogin extends _$PhoneLogin {
  @override
  PhoneLoginState build() => const PhoneLoginState();

  /// 先完成人机验证再发送验证码. 用户关闭验证时不发送请求, 也不开始倒计时.
  Future<void> sendCode(CaptchaPresenter present, String mobile) async {
    if (state.sending) return;
    state = PhoneLoginState(resendAt: state.resendAt, sending: true);
    final auth = ref.read(authRepositoryProvider);
    try {
      final sent = await ref
          .read(captchaGateProvider)
          .run(present, (ticket) => auth.sendLoginCode(mobile, ticket));
      if (!ref.mounted) return;
      state = PhoneLoginState(
        resendAt: sent ? clock.now().add(resendInterval) : state.resendAt,
      );
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = PhoneLoginState(
        resendAt: state.resendAt,
        event: e.kind == FailureKind.tooFrequent
            ? AuthCodeLimited(e)
            : AuthFormFailed(e),
      );
    }
  }

  /// 服务端要求同意新版政策时, 用 [present] 弹出同意对话框, 用户同意后用同一个验证码重试.
  Future<void> submit(
    ConsentPresenter present,
    String mobile,
    String code,
  ) async {
    if (state.submitting) return;
    state = PhoneLoginState(resendAt: state.resendAt, submitting: true);
    final auth = ref.read(authRepositoryProvider);
    try {
      final deletionKey = await _deletionKey(ref);
      final result = await _withConsent(
        ref,
        present,
        (version) => auth.loginWithCode(
          mobile,
          code,
          policyVersion: version,
          deletionKey: deletionKey,
        ),
      );
      await _signIn(ref, result);
      if (ref.mounted) state = PhoneLoginState(resendAt: state.resendAt);
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = PhoneLoginState(
          resendAt: state.resendAt,
          event: AuthFormFailed(e),
        );
      }
    }
  }
}

/// 密码登录页的状态: 提交状态和最近一次失败.
class const PasswordLoginState({
  final bool submitting = false,
  final AppFailure? failure,
});

@riverpod
class PasswordLogin extends _$PasswordLogin {
  @override
  PasswordLoginState build() => const PasswordLoginState();

  /// 服务端要求同意新版政策时, 用 [consent] 弹出同意对话框. 要求人机验证时, 用 [captcha] 弹出验证.
  ///
  /// 两种情况都在用户确认后用同一组账号密码重新登录. 账号密码只在本次调用中保留在内存里.
  /// 用户关闭人机验证时按取消处理, 页面不显示提示.
  Future<void> submit(
    ConsentPresenter consent,
    CaptchaPresenter captcha,
    String account,
    String password,
  ) async {
    if (state.submitting) return;
    state = const PasswordLoginState(submitting: true);
    final auth = ref.read(authRepositoryProvider);
    try {
      final deletionKey = await _deletionKey(ref);
      final result = await _withConsent(ref, consent, (version) async {
        try {
          return await auth.loginWithPassword(
            account,
            password,
            policyVersion: version,
            deletionKey: deletionKey,
          );
        } on AppFailure catch (e) {
          if (!BizCodes.captchaRetryCodes.contains(e.code)) rethrow;
          SignInResult? verified;
          await ref
              .read(captchaGateProvider)
              .run(
                captcha,
                (ticket) async => verified = await auth.loginWithPassword(
                  account,
                  password,
                  policyVersion: version,
                  deletionKey: deletionKey,
                  ticket: ticket,
                ),
              );
          return verified ?? (throw const AppFailure.cancelled());
        }
      });
      await _signIn(ref, result);
      if (ref.mounted) state = const PasswordLoginState();
    } on AppFailure catch (e) {
      if (ref.mounted) state = PasswordLoginState(failure: e);
    }
  }
}

/// 点 "手机注册 / 登录" 之后, 登录页接下来该做什么.
sealed class OneClickOutcome {
  const OneClickOutcome();
}

/// 一键登录成功. 守卫随后把页面导回原目标地址.
final class OneClickSignedIn extends OneClickOutcome {
  const OneClickSignedIn();
}

/// 用户关掉了授权页, 留在登录页.
final class OneClickDismissed extends OneClickOutcome {
  const OneClickDismissed();
}

/// 改用验证码登录: 一键登录不可用, 或用户在授权页点了 "其他号码登录".
///
/// [revoking] 表示账号在注销冷静期内而本机存有撤销凭据, 验证码登录页要提示用验证码登录可以撤销.
final class OneClickUseCode extends OneClickOutcome {
  const OneClickUseCode({this.revoking = false});

  final bool revoking;
}

/// 用户授权后登录失败, 授权页已关闭. 页面弹对话框说明原因, 让用户重试或改用验证码登录.
final class OneClickFailed extends OneClickOutcome {
  const OneClickFailed(this.failure);

  final AppFailure failure;
}

/// 这次登录不了, 重试也没用: 用户不同意新版政策, 或账号在注销冷静期内而本机没有撤销凭据.
/// 授权页已关闭, 页面只说明原因.
final class OneClickBlocked extends OneClickOutcome {
  const OneClickBlocked(this.failure);

  final AppFailure failure;
}

/// 运营商一键登录. 状态是一次登录是否正在进行, 登录页的按钮据此显示加载.
///
/// 用户勾选协议后在后台准备: 先问服务端开没开, 再初始化号码认证 SDK 并预取号.
/// SDK 会联网并读取网络和 SIM 卡状态, 没勾选协议前不碰它.
///
/// 一键登录不可用时 (Web, 没有 SIM 卡, 没开蜂窝网络, 服务端没开, 取凭证失败) 不提示, 直接改用验证码登录.
@Riverpod(keepAlive: true)
class OneClickLogin extends _$OneClickLogin {
  /// 准备的结果: 能否拉起授权页. 为 null 表示还没准备, 或上次失败后要重新准备.
  Future<bool>? _ready;

  /// 服务端是否开启了一键登录. 问到结果后本次运行内不再问.
  bool? _enabled;

  @override
  bool build() {
    ref.listen(loginAgreementProvider, (_, agreed) {
      if (agreed) unawaited(_prepare());
    }, fireImmediately: true);
    return false;
  }

  /// 用户点了 "手机注册 / 登录", 且已勾选协议.
  ///
  /// 能一键登录时拉起授权页, 用户确认后登录. 服务端要求同意新版政策时, 先关掉授权页,
  /// 再用 [present] 弹出同意对话框, 用户同意后用同一个凭证重试.
  Future<OneClickOutcome> start(ConsentPresenter present) async {
    if (state) return const OneClickDismissed();
    state = true;
    try {
      final numberAuth = ref.read(numberAuthProvider);
      if (!await _prepare()) {
        _prepareAgain();
        return const OneClickUseCode();
      }
      switch (await numberAuth.requestToken()) {
        case NumberAuthGranted(:final token):
          return await _login(present, token);
        case NumberAuthCancelled():
          return const OneClickDismissed();
        case NumberAuthSwitched():
          return const OneClickUseCode();
        case NumberAuthFailed():
          _prepareAgain();
          return const OneClickUseCode();
      }
    } finally {
      if (ref.mounted) state = false;
    }
  }

  /// 用凭证登录. 登录期间授权页开着并显示加载, 结束后关闭.
  Future<OneClickOutcome> _login(ConsentPresenter present, String token) async {
    final numberAuth = ref.read(numberAuthProvider);
    final auth = ref.read(authRepositoryProvider);
    try {
      final result = await _withConsent(ref, () async {
        await numberAuth.closeAuthPage();
        return present();
      }, (version) => auth.loginWithOneClick(token, policyVersion: version));
      await _signIn(ref, result);
      return const OneClickSignedIn();
    } on AppFailure catch (e) {
      return await _outcomeOf(e);
    } finally {
      await numberAuth.closeAuthPage();
    }
  }

  Future<OneClickOutcome> _outcomeOf(AppFailure e) async {
    if (e.kind == FailureKind.cancelled) return const OneClickDismissed();
    if (BizCodes.consentCodes.contains(e.code)) return OneClickBlocked(e);
    switch (e.code) {
      case BizCodes.oneClickUnavailable:
        _enabled = false;
        _ready = Future.value(false);
        return const OneClickUseCode();
      // 一键登录不能撤销注销. 本机存有撤销凭据时, 改用验证码登录就能撤销.
      case BizCodes.accountDeletionPending:
        return await _deletionKey(ref) == null
            ? OneClickBlocked(e)
            : const OneClickUseCode(revoking: true);
      default:
        return OneClickFailed(e);
    }
  }

  Future<bool> _prepare() => _ready ??= _check();

  Future<bool> _check() async {
    final numberAuth = ref.read(numberAuthProvider);
    if (!numberAuth.supported) return false;
    try {
      final enabled = _enabled ??= await ref
          .read(authRepositoryProvider)
          .oneClickEnabled();
      if (!enabled) return false;
    } on AppFailure {
      return false;
    }
    return numberAuth.prepare();
  }

  /// 这次不可用的原因可能已经消失 (插了卡, 开了蜂窝网络, 网络恢复), 在后台重新准备, 下次点按钮时再试.
  void _prepareAgain() {
    if (!ref.read(numberAuthProvider).supported || _enabled == false) return;
    _ready = null;
    unawaited(_prepare());
  }
}

/// 带服务端当前的政策版本登录. 服务端要求同意时请用户确认, 用户同意后用同一组凭据重试一次.
///
/// 服务端在核销验证码之前校验同意, 因此重试不需要重新获取验证码.
/// 用户不同意时抛出业务码为 [BizCodes.consentRequired] 的 [AppFailure].
Future<SignInResult> _withConsent(
  Ref ref,
  ConsentPresenter present,
  Future<SignInResult> Function(String? policyVersion) login,
) async {
  final consent = ref.read(crossBorderConsentProvider);
  try {
    return await login(await consent.currentVersion());
  } on AppFailure catch (e) {
    if (!BizCodes.consentCodes.contains(e.code)) rethrow;
    return login(await consent.confirm(present));
  }
}

/// 本机保存的注销撤销凭据. 读取失败时不带, 不影响登录.
Future<String?> _deletionKey(Ref ref) async {
  try {
    return await ref.read(cancellationRepositoryProvider).deletionKey();
  } on Object {
    return null;
  }
}

/// 登录成功后记录协议同意, 再更新登录态. 守卫随后把页面导回原目标地址.
///
/// 首次同意时在这里补启动崩溃上报等服务.
/// 登录的是在本机申请注销的账号时, 注销已随登录撤销, 删除本机的撤销凭据.
Future<void> _signIn(Ref ref, SignInResult result) async {
  await ref.read(privacyConsentStoreProvider).record();
  unawaited(ref.read(consentedServicesProvider.notifier).start());
  await ref.read(sessionProvider.notifier).signIn(result);
  if (ref.read(sessionProvider) case SignedIn(user: final user?)) {
    try {
      await ref.read(cancellationRepositoryProvider).signedIn(user.id);
    } on Object {
      // 凭据留在本机不影响使用. 下次登录时服务端忽略它.
    }
  }
}

/// [failure] 是否为账号或密码错误. 是时输入框下划线显示 `warn` 色, 并提示账号或密码错误.
bool isWrongCredentials(AppFailure failure) =>
    failure.code == BizCodes.wrongPassword;
