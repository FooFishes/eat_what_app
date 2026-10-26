import 'package:eat/core/config/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'human_verifier_io.dart'
    if (dart.library.js_interop) 'human_verifier_web.dart'
    as platform;

part 'human_verifier.g.dart';

/// 一次人机验证的初始化参数，每次验证前从 `/auth/captcha/config` 重新拿，不缓存、不复用。
class const CaptchaParams({
  required final String appId,
  required final String scriptUrl,
  required final String aidEncrypted,
  required final String aidEncryptedType,
});

/// 验证通过后腾讯给的票据，原样放进发验证码请求的两个请求头。
///
/// 票据只放请求头，不进 URL、日志和本地存储（技术架构 18.3）。
class const CaptchaTicket({
  required final String ticket,
  required final String randstr,
}) {
  Map<String, String> get headers => {
    'X-Captcha-Ticket': ticket,
    'X-Captcha-Randstr': randstr,
  };
}

/// 一次验证的结果。
sealed class CaptchaOutcome {
  const CaptchaOutcome();
}

final class CaptchaPassed extends CaptchaOutcome {
  const CaptchaPassed(this.ticket);

  final CaptchaTicket ticket;
}

/// 用户关掉了验证，什么也不发。
final class CaptchaCancelled extends CaptchaOutcome {
  const CaptchaCancelled();
}

/// 腾讯的脚本没加载出来或者报错。腾讯此时给的容灾票据（`trerror_` 开头）后端不收，所以当失败处理。
final class CaptchaFailed extends CaptchaOutcome {
  const CaptchaFailed();
}

/// 腾讯云验证码。要不要用户动手由腾讯判断：没风险时自动通过，用户看不到。
///
/// App 里在一层透明的全屏 WebView 里加载腾讯的 JS，Web 上直接在页面里加载，结果一样。
abstract interface class HumanVerifier {
  Future<CaptchaOutcome> verify(BuildContext context, CaptchaParams params);
}

@Riverpod(keepAlive: true)
HumanVerifier humanVerifier(Ref ref) =>
    platform.createHumanVerifier(ref.watch(appConfigProvider));

/// 腾讯回调里的结果转成 [CaptchaOutcome]：`ret` 为 0 且票据不是容灾票据才算通过，2 是用户关掉。
CaptchaOutcome captchaOutcomeOf({
  required int? ret,
  required String? ticket,
  required String? randstr,
}) {
  if (ret == 2) return const CaptchaCancelled();
  if (ret == 0 &&
      ticket != null &&
      ticket.isNotEmpty &&
      !ticket.startsWith('trerror_') &&
      randstr != null &&
      randstr.isNotEmpty) {
    return CaptchaPassed(CaptchaTicket(ticket: ticket, randstr: randstr));
  }
  return const CaptchaFailed();
}
