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
/// 勾选即同时同意隐私政策, 用户协议和个人信息出境说明, 手机号登录和密码登录均要求先勾选.
/// 登录请求会携带服务端当前的政策版本, 登录成功后将同意记录写入本机.
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

/// 手机号登录页的表单状态, 包含验证码重发倒计时, 提交状态和最近一次失败结果.
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

  /// 发送验证码前需先完成人机验证; 若用户关闭验证, 则不发送请求也不开始倒计时.
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

  /// 使用验证码登录. 若服务端要求同意新版政策, 则通过 [present] 弹出同意对话框, 待用户同意后沿用同一个验证码重试.
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

/// 密码登录页的表单状态, 包含提交状态和最近一次失败结果.
class const PasswordLoginState({
  final bool submitting = false,
  final AppFailure? failure,
});

@riverpod
class PasswordLogin extends _$PasswordLogin {
  @override
  PasswordLoginState build() => const PasswordLoginState();

  /// 使用账号密码登录. 若服务端要求同意新版政策则通过 [consent] 弹出同意对话框, 若要求人机验证则通过 [captcha] 弹出验证.
  ///
  /// 两种情况均在用户确认后沿用同一组账号密码重试, 账号密码仅在本次调用期间保留于内存中.
  /// 若用户关闭人机验证则按取消处理, 页面不显示错误提示.
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

/// 点击 "手机注册 / 登录" 后的处理结果, 登录页据此决定后续跳转或提示.
sealed class OneClickOutcome {
  const OneClickOutcome();
}

/// 一键登录成功, 路由守卫随后将页面导回原目标地址.
final class OneClickSignedIn extends OneClickOutcome {
  const OneClickSignedIn();
}

/// 用户关闭了授权页, 停留在登录页.
final class OneClickDismissed extends OneClickOutcome {
  const OneClickDismissed();
}

/// 因一键登录不可用或用户在授权页点击了 "其他号码登录", 转为使用验证码登录.
///
/// 当 [revoking] 为 true 时, 表示账号处于注销冷静期且本机存有撤销凭据, 验证码登录页需提示用户可通过验证码登录撤销注销.
final class OneClickUseCode extends OneClickOutcome {
  const OneClickUseCode({this.revoking = false});

  final bool revoking;
}

/// 用户授权后登录失败且授权页已关闭. 页面需弹出对话框说明原因, 并提供重试或改用验证码登录的入口.
final class OneClickFailed extends OneClickOutcome {
  const OneClickFailed(this.failure);

  final AppFailure failure;
}

/// 当前无法登录且重试无效, 包括用户拒绝新版政策, 或账号处于注销冷静期而本机无撤销凭据两种情况.
/// 此时授权页已关闭, 页面仅说明原因.
final class OneClickBlocked extends OneClickOutcome {
  const OneClickBlocked(this.failure);

  final AppFailure failure;
}

/// 运营商一键登录状态管理, 布尔状态表示登录流程是否正在进行, 登录页按钮据此显示加载状态.
///
/// 用户勾选协议后才在后台执行准备: 先向服务端查询开关状态, 再初始化号码认证 SDK 并预取号.
/// 由于 SDK 会联网并读取网络与 SIM 卡状态, 未勾选协议前不调用该 SDK.
///
/// 若一键登录不可用 (如 Web 端, 无 SIM 卡, 未开启蜂窝网络, 服务端未开启或获取凭证失败), 则不作错误提示, 直接转为验证码登录.
@Riverpod(keepAlive: true)
class OneClickLogin extends _$OneClickLogin {
  /// 预取号准备结果, 表示能否拉起授权页; 为 null 时表示尚未准备或上次失败后需重新准备.
  Future<bool>? _ready;

  /// 服务端是否开启一键登录的缓存标记, 获取结果后在本次运行期间不再重复查询.
  bool? _enabled;

  @override
  bool build() {
    ref.listen(loginAgreementProvider, (_, agreed) {
      if (agreed) unawaited(_prepare());
    }, fireImmediately: true);
    return false;
  }

  /// 响应 "手机注册 / 登录" 点击事件, 调用前需已勾选协议.
  ///
  /// 若一键登录可用则拉起授权页并在用户确认后登录; 若服务端要求同意新版政策, 则先关闭授权页再通过 [present] 弹出同意对话框, 待用户同意后沿用同一凭证重试.
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

  /// 使用运营商凭证执行登录. 请求期间授权页保持开启并显示加载状态, 结束后关闭.
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
      // 一键登录无法撤销注销; 若本机存有撤销凭据, 改用验证码登录即可撤销.
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

  /// 若之前不可用的条件可能已恢复 (如插入 SIM 卡, 开启蜂窝网络或网络恢复), 在后台重置并重新准备, 供下次点击时使用.
  void _prepareAgain() {
    if (!ref.read(numberAuthProvider).supported || _enabled == false) return;
    _ready = null;
    unawaited(_prepare());
  }
}

/// 携带服务端当前政策版本执行登录. 若服务端要求确认政策更新, 则弹窗请用户同意后沿用同一组凭据重试一次.
///
/// 服务端在核销验证码之前校验同意状态, 因此重试无需重新获取验证码.
/// 若用户拒绝同意, 则抛出业务码为 [BizCodes.consentRequired] 的 [AppFailure].
/// 返回登录结果和登录成功时携带的政策版本, 后者写入本机同意记录.
Future<({SignInResult result, String? version})> _withConsent(
  Ref ref,
  ConsentPresenter present,
  Future<SignInResult> Function(String? policyVersion) login,
) async {
  final consent = ref.read(crossBorderConsentProvider);
  final current = await consent.currentVersion();
  try {
    return (result: await login(current), version: current);
  } on AppFailure catch (e) {
    if (!BizCodes.consentCodes.contains(e.code)) rethrow;
    final confirmed = await consent.confirm(present);
    return (result: await login(confirmed), version: confirmed);
  }
}

/// 读取本机保存的注销撤销凭据. 读取失败时返回 null, 不阻塞登录流程.
Future<String?> _deletionKey(Ref ref) async {
  try {
    return await ref.read(cancellationRepositoryProvider).deletionKey();
  } on Object {
    return null;
  }
}

/// 登录成功后先持久化协议同意记录, 再更新会话状态, 路由守卫随后将页面导回原目标地址.
///
/// 若为首次同意, 会在此处启动崩溃上报等依赖同意的服务.
/// 若登录账号曾在本机申请注销, 此时注销已随登录撤销, 需清除本机的撤销凭据.
Future<void> _signIn(
  Ref ref,
  ({SignInResult result, String? version}) signedIn,
) async {
  final (:result, :version) = signedIn;
  await ref.read(privacyConsentStoreProvider).record(version);
  unawaited(ref.read(consentedServicesProvider.notifier).start());
  await ref.read(sessionProvider.notifier).signIn(result);
  if (ref.read(sessionProvider) case SignedIn(user: final user?)) {
    try {
      await ref.read(cancellationRepositoryProvider).signedIn(user.id);
    } on Object {
      // 凭据残留在本机不影响后续使用, 下次登录时服务端会忽略该凭据.
    }
  }
}

/// 判断 [failure] 是否为账号或密码错误. 为 true 时输入框下划线显示 `warn` 色并就地提示错误.
bool isWrongCredentials(AppFailure failure) =>
    failure.code == BizCodes.wrongPassword;
