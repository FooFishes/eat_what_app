import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/state/captcha_gate.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verify_providers.g.dart';

/// 认证页的状态：认证链接发到了哪、多久后能重发，统一认证是不是跳出去过，以及最近一次提示。
class const VerifyState({
  final String? emailSentTo,
  final DateTime? resendAt,
  final bool busy = false,
  final bool ssoStarted = false,
  final String? notice,
});

/// 邮件 60 秒后可以重发，和验证码一样。
const emailResendInterval = Duration(seconds: 60);

@riverpod
class Verify extends _$Verify {
  @override
  VerifyState build() => const VerifyState();

  /// 跳到学校的统一认证页。地址一次有效，每次点都重新拿。
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

  /// 先过人机验证再发认证邮件。
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

  /// 换个邮箱：回到填邮箱的样子。
  void editEmail() => state = VerifyState(ssoStarted: state.ssoStarted);

  /// 回到页面或点「我已完成，刷新状态」时重新拉认证状态。跳出去认证过、回来还没认证时，提示重新认证。
  ///
  /// 统一认证失败时后端现在不跳回来，分不出是链接失效还是学号认证过别的账号（现状差距 2.1）。
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
