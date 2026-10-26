import 'package:eat/core/failure/messages.dart';

/// 失败的大类，决定页面怎么反应：就地重试、回登录页、弹拦截面板，还是只给一句提示。
enum FailureKind {
  /// 连不上：连接错误、DNS 失败、超时。读请求会自动重试。
  network,

  /// HTTP 5xx 或 9xxxx 系统错误。
  server,

  /// 登录过期，网络层已经通知登录态清掉登录信息。
  sessionExpired,

  /// 服务端判定没权限（没认证、被封禁），页面按最新的账号状态弹拦截面板。
  forbidden,

  /// 请求频率过高。
  tooFrequent,

  /// 业务码表里有的错误，[AppFailure.message] 是那一句提示。
  business,

  /// 请求被取消（页面已经离开），不提示。
  cancelled,

  /// 其他：码表里没有的业务码、响应解析失败。
  unknown,
}

/// 网络层抛出的唯一异常：页面只看 [kind] 和 [message]，业务码只用来就地提示（比如验证码错误）。
///
/// 服务端的 `msg` 和错误码不直接给用户看（产品 6.13）；[serverMessage] 只用于调试和上报。
class const AppFailure(
  final FailureKind kind, {
  final Object? code,
  final String? serverMessage,
}) implements Exception {
  const AppFailure.network() : this(FailureKind.network);

  const AppFailure.cancelled() : this(FailureKind.cancelled);

  /// 业务码转成失败，归类和提示按码表（技术架构 7.4、7.5）。
  factory AppFailure.fromCode(Object code, {String? serverMessage}) =>
      AppFailure(failureKindOf(code), code: code, serverMessage: serverMessage);

  /// 给用户看的一句话。
  String get message => switch (kind) {
    FailureKind.network => '网络连接失败，请重试',
    FailureKind.server => '服务器出错，请稍后再试',
    FailureKind.sessionExpired => '登录已过期，请重新登录',
    FailureKind.tooFrequent => '操作过于频繁，请稍后再试',
    FailureKind.business => failureMessages[code] ?? '操作失败，请重试',
    FailureKind.forbidden ||
    FailureKind.cancelled ||
    FailureKind.unknown => '操作失败，请重试',
  };

  @override
  String toString() => 'AppFailure($kind, code: $code, msg: $serverMessage)';
}
