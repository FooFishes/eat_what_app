import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
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

/// 统一认证的结果, 来自后端重定向到回跳链接时附带的 `result` 和 `code`.
///
/// 回跳链接任何人都能构造, 因此结果只用于提示, 不能作为认证凭证.
class const SsoResult({required final bool success, final int? code});

/// 统一认证回跳链接中的失败业务码, 取值与后端 `AuthService` 重定向时附带的 `code` 一致.
abstract final class SsoCodes {
  /// 认证链接无效, 过期或已用过.
  static const linkExpired = 30012;

  /// 学号已认证过本站的其他账号.
  static const studentIdTaken = 30013;

  /// 学校返回的认证凭证无效或无法解析.
  static const badSchoolResponse = 50003;
}

/// 统一认证失败时的提示. 不显示业务码, 未收录的业务码使用通用提示.
String ssoFailureMessage(int? code) => switch (code) {
  SsoCodes.linkExpired => '认证链接已失效，请重新发起认证',
  SsoCodes.studentIdTaken => '该学号已认证其他账号',
  SsoCodes.badSchoolResponse => '学校返回的认证结果无效，请重新认证',
  BizCodes.consentRequired || BizCodes.dataSyncPending => '账号正在同步，请稍后重新认证',
  BizCodes.userDisabled => '账号已停用',
  final int code when code ~/ 10000 == 9 => '暂时无法认证，请稍后再试',
  _ => '认证没有完成，请重新认证',
};

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

  /// 重新请求认证状态. 在打开页面, 回到前台或点击 "我已完成, 刷新状态" 时调用.
  ///
  /// 跳转过统一认证或用户主动刷新, 而账号仍未认证时, 提示重新认证.
  /// 自动刷新不替换已有的提示, 以保留回跳链接给出的具体原因.
  Future<void> refresh({bool userAsked = false}) async {
    await ref.read(sessionProvider.notifier).refreshUser();
    if (!ref.mounted) return;
    if (_verified) {
      state = _copy(notice: null);
    } else if (userAsked || (state.ssoStarted && state.notice == null)) {
      state = _copy(notice: '认证未完成，请重新认证');
    }
  }

  /// 显示统一认证回跳的结果, 并重新请求认证状态.
  ///
  /// 是否已认证以服务端返回的当前账号为准: 期间切换过账号时, 结果不套用到新账号.
  /// 成功但账号仍未认证时, 可能是跨站同步尚未完成, 提示稍后刷新而不是重新认证.
  Future<void> showSsoResult(SsoResult result) async {
    await ref.read(browserProvider).closeSso();
    await ref.read(sessionProvider.notifier).refreshUser();
    if (!ref.mounted) return;
    if (_verified) {
      state = _copy(notice: null);
    } else if (result.success) {
      state = _copy(ssoStarted: true, notice: '认证结果尚未同步，请稍后刷新状态');
    } else {
      state = _copy(notice: ssoFailureMessage(result.code));
    }
  }

  bool get _verified => switch (ref.read(sessionProvider)) {
    SignedIn(:final user) => user?.verified ?? false,
    SignedOut() => false,
  };

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
