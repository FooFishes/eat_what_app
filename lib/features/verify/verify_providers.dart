import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/state/captcha_gate.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verify_providers.g.dart';

/// 认证页的状态.
///
/// - [emailSentTo]: 认证邮件的收件地址.
/// - [resendAt]: 允许重发的时间.
/// - [ssoStarted]: 是否已跳转过统一认证页.
/// - [notice]: 最近一次提示.
class const VerifyState({
  final String? emailSentTo,
  final DateTime? resendAt,
  final bool busy = false,
  final bool ssoStarted = false,
  final String? notice,
});

/// 认证邮件的重发间隔, 与短信验证码一致.
const emailResendInterval = Duration(seconds: 60);

@riverpod
class Verify extends _$Verify {
  @override
  VerifyState build() => const VerifyState();

  /// 跳转到学校的统一认证页. 认证地址只能使用一次, 因此每次点击都重新获取.
  Future<void> startSso() async {
    if (state.busy) return;
    state = _copy(busy: true, notice: null);
    try {
      final url = await ref.read(authRepositoryProvider).ssoUrl();
      final opened = await ref.read(browserProvider).openSso(url);
      if (!ref.mounted) return;
      state = _copy(
        busy: false,
        ssoStarted: true,
        notice: opened ? null : '无法打开学校页面，请重试',
      );
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = _copy(busy: false, notice: _noticeOf(e));
    }
  }

  /// 通过人机验证后发送认证邮件.
  Future<void> sendEmail(CaptchaPresenter present, String email) async {
    if (state.busy) return;
    state = _copy(busy: true, notice: null);
    final auth = ref.read(authRepositoryProvider);
    try {
      final sent = await ref
          .read(captchaGateProvider)
          .run(present, (ticket) => auth.sendVerifyEmail(email, ticket));
      if (!ref.mounted) return;
      state = sent
          ? VerifyState(
              emailSentTo: email,
              resendAt: clock.now().add(emailResendInterval),
              ssoStarted: state.ssoStarted,
            )
          : _copy(busy: false, notice: null);
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      state = _copy(busy: false, notice: _noticeOf(e));
    }
  }

  /// 更换邮箱: 清除已发送状态, 回到邮箱输入.
  void editEmail() => state = VerifyState(ssoStarted: state.ssoStarted);

  // TODO: 统一认证失败时后端不重定向回客户端, 客户端无法区分链接失效和学号已认证其他账号, 只能统一提示重新认证. 后端失败时也重定向并带上错误码后, 按错误码分别提示.
  /// 重新请求认证状态. 在回到页面或点击 "我已完成, 刷新状态" 时调用.
  ///
  /// 跳转过统一认证或用户主动刷新, 而账号仍未认证时, 提示重新认证.
  Future<void> refresh({bool userAsked = false}) async {
    await ref.read(sessionProvider.notifier).refreshUser();
    if (!ref.mounted) return;
    final verified = switch (ref.read(sessionProvider)) {
      SignedIn(:final user) => user?.verified ?? false,
      SignedOut() => false,
    };
    if (verified) {
      state = _copy(notice: null);
    } else if (userAsked || state.ssoStarted) {
      state = _copy(notice: '认证未完成，请重新认证');
    }
  }

  VerifyState _copy({bool? busy, bool? ssoStarted, required String? notice}) =>
      VerifyState(
        emailSentTo: state.emailSentTo,
        resendAt: state.resendAt,
        busy: busy ?? state.busy,
        ssoStarted: ssoStarted ?? state.ssoStarted,
        notice: notice,
      );

  static String? _noticeOf(AppFailure failure) =>
      failure.kind == FailureKind.cancelled ? null : failure.message;
}
