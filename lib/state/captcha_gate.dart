import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'captcha_gate.g.dart';

/// 弹出人机验证并等待结果.
///
/// 由页面用自身的 `BuildContext` 包装 `HumanVerifier.verify` 后传入, Provider 不持有 `BuildContext`.
typedef CaptchaPresenter = Future<CaptchaOutcome> Function(
  Future<CaptchaParams?> params,
);

/// 负责发送验证码与认证邮件前的人机验证流程, 校验票据仅随本次请求发送.
///
/// 每次尝试均会重新获取初始化参数并新建验证实例; 若服务端返回票据缺失或无效则重新发起验证,
/// 最多尝试 [_maxAttempts] 次.
class CaptchaGate {
  CaptchaGate(this._auth);

  static const _maxAttempts = 3;

  final AuthRepository _auth;

  /// 弹出人机验证并在通过后执行 [send]. 返回 false 表示用户取消验证且未发送请求.
  ///
  /// 验证不通过或发送失败时抛出 [AppFailure].
  Future<bool> run(
    CaptchaPresenter present,
    Future<void> Function(CaptchaTicket? ticket) send,
  ) async {
    for (var attempt = 1; ; attempt++) {
      // 若页面已关闭则 present 不会等待 params, 此处调用 ignore() 避免未捕获异常; 正常等待 params 的一方仍会收到错误.
      final params = _auth.captchaParams()..ignore();
      final CaptchaTicket? ticket;
      switch (await present(params)) {
        case CaptchaPassed(ticket: final passed):
          ticket = passed;
        case CaptchaSkipped():
          ticket = null;
        case CaptchaCancelled():
          return false;
        case CaptchaFailed():
          throw AppFailure.fromCode(BizCodes.captchaInvalid);
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
