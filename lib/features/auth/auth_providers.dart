import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/state/captcha_gate.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/cross_border_consent.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// 登录页的协议勾选状态.
///
/// 勾选同时同意隐私政策, 用户协议和数据存放在境外. 手机号登录和密码登录都要求先勾选.
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
      final result = await _withConsent(
        ref,
        present,
        (version) => auth.loginWithCode(mobile, code, policyVersion: version),
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
      final result = await _withConsent(ref, consent, (version) async {
        try {
          return await auth.loginWithPassword(
            account,
            password,
            policyVersion: version,
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
    failure.code == BizCodes.wrongPassword;
