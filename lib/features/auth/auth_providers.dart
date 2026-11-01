import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/state/captcha_gate.dart';
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

/// 验证码发送过于频繁. 页面弹出面板说明次数上限, 并提供 "用密码登录".
final class AuthCodeLimited extends AuthFormEvent {
  const AuthCodeLimited();
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
            ? const AuthCodeLimited()
            : AuthFormFailed(e),
      );
    }
  }

  Future<void> submit(String mobile, String code) async {
    if (state.submitting) return;
    state = PhoneLoginState(resendAt: state.resendAt, submitting: true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .loginWithCode(mobile, code);
      await _signIn(ref, result);
      if (ref.mounted) state = PhoneLoginState(resendAt: state.resendAt);
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = PhoneLoginState(
        resendAt: state.resendAt,
        event: AuthFormFailed(e),
      );
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

  Future<void> submit(String account, String password) async {
    if (state.submitting) return;
    state = const PasswordLoginState(submitting: true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .loginWithPassword(account, password);
      await _signIn(ref, result);
      if (ref.mounted) state = const PasswordLoginState();
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = PasswordLoginState(failure: e);
    }
  }
}

/// 登录成功后记录协议同意, 再更新登录态. 守卫随后把页面导回原目标地址.
Future<void> _signIn(Ref ref, SignInResult result) async {
  await ref.read(privacyConsentStoreProvider).record();
  await ref.read(sessionProvider.notifier).signIn(result);
}

/// [failure] 是否为账号或密码错误. 是时输入框下划线显示 `warn` 色, 并提示账号或密码错误.
bool isWrongCredentials(AppFailure failure) =>
    failure.code == BizCodes.wrongPassword ||
    failure.code == BizCodes.userNotFound;
