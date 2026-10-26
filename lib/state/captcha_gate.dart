import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'captcha_gate.g.dart';

/// 把人机验证弹出来、等结果。页面用自己的 `BuildContext` 包一层 `HumanVerifier.verify` 传进来，
/// Provider 里不拿 `BuildContext`。
typedef CaptchaPresenter = Future<CaptchaOutcome> Function(
  CaptchaParams params,
);

/// 发验证码、发认证邮件前先过人机验证，票据随这一次请求发出（技术架构 18.3）。
///
/// 每次都重新拿初始化参数、新建验证实例；服务端说票据缺失或无效时整套重来，最多三次。
class CaptchaGate {
  CaptchaGate(this._auth);

  static const _maxAttempts = 3;

  final AuthRepository _auth;

  /// 返回 false 表示用户关掉了验证，什么都没发。验证不过、发送失败时抛 [AppFailure]。
  Future<bool> run(
    CaptchaPresenter present,
    Future<void> Function(CaptchaTicket? ticket) send,
  ) async {
    for (var attempt = 1; ; attempt++) {
      final params = await _auth.captchaParams();
      CaptchaTicket? ticket;
      if (params != null) {
        switch (await present(params)) {
          case CaptchaPassed(ticket: final passed):
            ticket = passed;
          case CaptchaCancelled():
            return false;
          case CaptchaFailed():
            throw AppFailure.fromCode(BizCodes.captchaInvalid);
        }
      }
      try {
        await send(ticket);
        return true;
      } on AppFailure catch (e) {
        final retry = BizCodes.captchaRetryCodes.contains(e.code);
        if (!retry || attempt >= _maxAttempts) rethrow;
      }
    }
  }
}

@Riverpod(keepAlive: true)
CaptchaGate captchaGate(Ref ref) =>
    CaptchaGate(ref.watch(authRepositoryProvider));
