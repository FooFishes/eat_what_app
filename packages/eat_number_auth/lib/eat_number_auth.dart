/// 运营商一键登录原生桥: Android 和 iOS 上的阿里云号码认证 SDK.
///
/// 只做转发, 不含业务: 什么时候初始化, 失败后怎么回退, 凭证交给谁, 都由 App 的 `core/platform/number_auth/` 处理.
library;

import 'package:eat_number_auth/src/messages.g.dart';

export 'src/messages.g.dart'
    show AuthPageStyleMessage, LoginTokenMessage, LoginTokenStatus;

/// 号码认证 SDK. 用户同意隐私政策之后才能调用 [prepare].
abstract final class NumberAuthSdk {
  static final _api = NumberAuthHostApi();

  /// 设置方案密钥, 检查当前环境能否一键登录, 并预取号.
  ///
  /// 返回 null 表示可以拉起授权页, 否则是失败的返回码 (SDK 的六位数字码, 或插件自己的英文码), 只用于排查.
  static Future<String?> prepare(String secret, {required Duration timeout}) =>
      _api.prepare(secret, timeout.inMilliseconds);

  /// 拉起授权页, 等用户点登录, 关闭或切换. 要先 [prepare] 成功.
  ///
  /// 拿到凭证时授权页还开着并显示加载, 用 [closeAuthPage] 关闭. 其余结果授权页都已关闭.
  static Future<LoginTokenMessage> requestLoginToken(
    AuthPageStyleMessage style, {
    required Duration timeout,
  }) => _api.requestLoginToken(style, timeout.inMilliseconds);

  /// 关闭授权页. 授权页没开着时什么也不做.
  static Future<void> closeAuthPage() => _api.closeAuthPage();
}
