/// 运营商一键登录原生桥, 封装 Android 与 iOS 端的阿里云号码认证 SDK.
///
/// 仅负责消息转发, 不包含业务逻辑; 初始化时机, 失败回退策略与凭证分发均由 App 的 `core/platform/number_auth/` 处理.
library;

import 'package:eat_number_auth/src/messages.g.dart';

export 'src/messages.g.dart'
    show AuthPageStyleMessage, LoginTokenMessage, LoginTokenStatus;

/// 号码认证 SDK 入口, 须在用户同意隐私政策后才能调用 [prepare].
abstract final class NumberAuthSdk {
  static final _api = NumberAuthHostApi();

  /// 配置方案密钥并预取号, 同时检查当前网络环境是否支持一键登录.
  ///
  /// 返回 null 表示可拉起授权页, 否则返回失败码 (SDK 的六位数字码或插件自定义的英文标识), 仅用于问题排查.
  static Future<String?> prepare(String secret, {required Duration timeout}) =>
      _api.prepare(secret, timeout.inMilliseconds);

  /// 拉起授权页, 等待用户点击登录, 关闭或切换其他方式, 调用前须确保 [prepare] 已成功.
  ///
  /// 获取凭证成功时授权页仍保持打开并显示加载态, 须调用 [closeAuthPage] 关闭; 其余返回状态均表示授权页已关闭.
  static Future<LoginTokenMessage> requestLoginToken(
    AuthPageStyleMessage style, {
    required Duration timeout,
  }) => _api.requestLoginToken(style, timeout.inMilliseconds);

  /// 关闭授权页; 若授权页未打开则忽略.
  static Future<void> closeAuthPage() => _api.closeAuthPage();
}
