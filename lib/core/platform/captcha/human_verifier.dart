import 'package:eat/core/config/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'human_verifier_io.dart'
    if (dart.library.js_interop) 'human_verifier_web.dart'
    as platform;

part 'human_verifier.g.dart';

/// 一次人机验证的初始化参数. 每次验证前从 `/auth/captcha/config` 重新获取, 不缓存也不复用.
class const CaptchaParams({
  required final String appId,
  required final String scriptUrl,
  required final String aidEncrypted,
  required final String aidEncryptedType,
});

/// 验证通过后腾讯返回的票据, 原样放入发送验证码请求的两个请求头.
///
/// 票据只放在请求头中, 不写入 URL, 日志和本地存储.
class const CaptchaTicket({
  required final String ticket,
  required final String randstr,
}) {
  Map<String, String> get headers => {
    'X-Captcha-Ticket': ticket,
    'X-Captcha-Randstr': randstr,
  };
}

sealed class CaptchaOutcome {
  const CaptchaOutcome();
}

final class CaptchaPassed extends CaptchaOutcome {
  const CaptchaPassed(this.ticket);

  final CaptchaTicket ticket;
}

/// 服务端关闭了人机验证 (`enabled` 为 false), 不带票据发送.
final class CaptchaSkipped extends CaptchaOutcome {
  const CaptchaSkipped();
}

/// 用户关闭了验证, 不发送请求.
final class CaptchaCancelled extends CaptchaOutcome {
  const CaptchaCancelled();
}

/// 腾讯的脚本加载失败或运行报错.
///
/// 此时腾讯返回容灾票据 (以 `trerror_` 开头), 后端不接受, 因此按失败处理.
final class CaptchaFailed extends CaptchaOutcome {
  const CaptchaFailed();
}

/// 腾讯云验证码. 是否需要用户操作由腾讯判断, 无风险时自动通过, 用户无感知.
///
/// App 在全屏透明 WebView 中加载腾讯的 JS, Web 直接在页面中加载. 两端的结果一致.
///
/// 加载期间页面保持原样, 由发起验证的按钮显示加载状态. 遮罩在验证组件渲染完成后与组件一起出现.
abstract interface class HumanVerifier {
  /// [params] 为正在获取的初始化参数, 结果为 null 时返回 [CaptchaSkipped].
  ///
  /// 获取参数与加载验证页同时进行, 获取失败时抛出相应的错误.
  Future<CaptchaOutcome> verify(
    BuildContext context,
    Future<CaptchaParams?> params,
  );
}

@Riverpod(keepAlive: true)
HumanVerifier humanVerifier(Ref ref) =>
    platform.createHumanVerifier(ref.watch(appConfigProvider));

/// 把腾讯回调的结果转换为 [CaptchaOutcome].
///
/// `ret` 为 0 且票据不是容灾票据时为通过, `ret` 为 2 表示用户关闭, 其余为失败.
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
