import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/data/cancellation/cancellation_repository.dart';
import 'package:eat/features/auth/restore_providers.dart';
import 'package:eat/state/captcha_gate.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/cross_site_consent.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// 登录页的协议勾选状态.
///
/// 手机号登录和密码登录都要求先勾选. 登录成功后写入本机的同意记录.
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

/// 验证码发送过于频繁. 页面弹出面板提示何时可以重试, 并提供 "用密码登录".
final class AuthCodeLimited extends AuthFormEvent {
  const AuthCodeLimited(this.failure);

  /// 限流失败. [AppFailure.retryHint] 给出何时可以重试.
  final AppFailure failure;
}

/// 用户在同意面板中同意了跨站同步, 但本次提交已核销验证码. 页面清空验证码并提示重新获取.
final class AuthCodeConsumed extends AuthFormEvent {
  const AuthCodeConsumed();
}

/// 账号正在注销冷静期内. 页面打开撤销注销页, 申请已交给 [AccountRestore].
final class AuthRestoreRequired extends AuthFormEvent {
  const AuthRestoreRequired();
}

/// 手机号登录页的状态: 验证码重发倒计时, 提交状态, 最近一次失败.
class const PhoneLoginState({
  final DateTime? resendAt,
  final bool sending = false,
  final bool submitting = false,
  final AuthFormEvent? event,

  /// 用户是否已在同意面板中同意跨站同步. 为 true 时登录请求携带同意, 海外站的新号码据此注册.
  final bool consented = false,
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
    state = PhoneLoginState(
      resendAt: state.resendAt,
      sending: true,
      consented: state.consented,
    );
    final auth = ref.read(authRepositoryProvider);
    try {
      final sent = await ref
          .read(captchaGateProvider)
          .run(present, (ticket) => auth.sendLoginCode(mobile, ticket));
      if (!ref.mounted) return;
      state = PhoneLoginState(
        resendAt: sent ? clock.now().add(resendInterval) : state.resendAt,
        consented: state.consented,
      );
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = PhoneLoginState(
        resendAt: state.resendAt,
        consented: state.consented,
        event: e.kind == FailureKind.tooFrequent
            ? AuthCodeLimited(e)
            : AuthFormFailed(e),
      );
    }
  }

  /// 服务端要求同意跨站同步时, 用 [present] 弹出同意面板.
  ///
  /// 要求同意的响应已核销验证码, 因此用户同意后不自动重新登录, 而是要求重新获取验证码.
  /// 已有账号带临时凭证, 同意后立即提交. 海外站的新号码没有凭证, 下次登录请求携带同意完成注册.
  Future<void> submit(
    ConsentPresenter present,
    String mobile,
    String code,
  ) async {
    if (state.submitting) return;
    state = PhoneLoginState(
      resendAt: state.resendAt,
      submitting: true,
      consented: state.consented,
    );
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .loginWithCode(mobile, code, crossBorderConsent: state.consented);
      await _signIn(ref, result);
      if (ref.mounted) {
        state = PhoneLoginState(
          resendAt: state.resendAt,
          consented: state.consented,
        );
      }
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      if (e.code == BizCodes.consentRequired) {
        await _consent(present, e);
      } else if (pendingCancellationOf(e) case final pending?) {
        unawaited(
          ref
              .read(accountRestoreProvider.notifier)
              .begin(pending, account: mobile, method: RestoreMethod.code),
        );
        state = PhoneLoginState(
          resendAt: state.resendAt,
          consented: state.consented,
          event: const AuthRestoreRequired(),
        );
      } else {
        _fail(e);
      }
    }
  }

  Future<void> _consent(ConsentPresenter present, AppFailure required) async {
    final consent = ref.read(crossSiteConsentProvider);
    try {
      if (consentProofOf(required) case final proof?) {
        await consent.grant(present, proof: proof);
      } else {
        await consent.confirm(present);
      }
      if (!ref.mounted) return;
      state = PhoneLoginState(
        resendAt: state.resendAt,
        consented: true,
        event: const AuthCodeConsumed(),
      );
    } on AppFailure catch (e) {
      if (ref.mounted) _fail(e);
    }
  }

  void _fail(AppFailure failure) => state = PhoneLoginState(
    resendAt: state.resendAt,
    consented: state.consented,
    event: AuthFormFailed(failure),
  );
}

/// 密码登录页的状态: 提交状态和最近一次失败.
class const PasswordLoginState({
  final bool submitting = false,
  final AppFailure? failure,

  /// 账号正在注销冷静期内. 页面打开撤销注销页, 申请已交给 [AccountRestore].
  final bool restore = false,
});

@riverpod
class PasswordLogin extends _$PasswordLogin {
  @override
  PasswordLoginState build() => const PasswordLoginState();

  /// 服务端要求同意跨站同步时, 用 [present] 弹出同意面板.
  ///
  /// 用户同意后用临时凭证提交同意, 随后用同一组账号密码重新登录.
  /// 账号密码只在本次调用中保留在内存里.
  Future<void> submit(
    ConsentPresenter present,
    String account,
    String password,
  ) async {
    if (state.submitting) return;
    state = const PasswordLoginState(submitting: true);
    final auth = ref.read(authRepositoryProvider);
    try {
      SignInResult result;
      try {
        result = await auth.loginWithPassword(account, password);
      } on AppFailure catch (e) {
        final proof = consentProofOf(e);
        if (proof == null) rethrow;
        await ref.read(crossSiteConsentProvider).grant(present, proof: proof);
        result = await auth.loginWithPassword(account, password);
      }
      await _signIn(ref, result);
      if (ref.mounted) state = const PasswordLoginState();
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      if (pendingCancellationOf(e) case final pending?) {
        unawaited(
          ref
              .read(accountRestoreProvider.notifier)
              .begin(pending, account: account, method: RestoreMethod.password),
        );
        state = const PasswordLoginState(restore: true);
        return;
      }
      state = PasswordLoginState(failure: e);
    }
  }
}

/// 登录成功后记录协议同意, 再更新登录态. 守卫随后把页面导回原目标地址.
///
/// 首次同意时在这里补启动崩溃上报等服务.
Future<void> _signIn(Ref ref, SignInResult result) async {
  await ref.read(privacyConsentStoreProvider).record();
  unawaited(ref.read(consentedServicesProvider.notifier).start());
  await ref.read(sessionProvider.notifier).signIn(result);
}

/// [failure] 是否为账号或密码错误. 是时输入框下划线显示 `warn` 色, 并提示账号或密码错误.
bool isWrongCredentials(AppFailure failure) =>
    failure.code == BizCodes.wrongPassword ||
    failure.code == BizCodes.userNotFound;
