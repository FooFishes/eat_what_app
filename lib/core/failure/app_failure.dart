import 'package:eat/core/failure/messages.dart';

/// 失败的类别, 决定页面的处理方式: 就地重试, 返回登录页, 弹出拦截对话框, 或只显示提示.
enum FailureKind {
  /// 网络不可达: 连接错误, DNS 失败, 超时. 读请求会自动重试.
  network,

  /// HTTP 5xx 或 9xxxx 系统错误.
  server,

  /// 登录过期. 网络层已通知登录态清除登录信息.
  sessionExpired,

  /// 服务端判定无权限 (未认证或已封禁). 页面按最新的账号状态弹出拦截对话框.
  forbidden,

  tooFrequent,

  /// 码表中已登记的业务错误. [AppFailure.message] 为对应的提示.
  business,

  /// 请求已取消, 例如页面已离开. 不显示提示.
  cancelled,

  /// 其他失败: 码表中未登记的业务码, 响应解析失败.
  unknown,
}

/// 网络层抛出的唯一异常类型.
///
/// 页面只读取 [kind] 和 [message]. 业务码仅用于就地提示, 例如验证码错误.
/// 服务端的 `msg` 和错误码不展示给用户, [serverMessage] 仅用于调试和上报.
class const AppFailure(
  final FailureKind kind, {
  final Object? code,
  final String? serverMessage,

  /// 失败响应外壳中携带的 `data`, 例如发布重名菜品时已有菜品的 id.
  final Object? data,
}) implements Exception {
  const AppFailure.network() : this(FailureKind.network);

  const AppFailure.cancelled() : this(FailureKind.cancelled);

  /// 按码表把业务码转换为失败, 码表决定类别和提示.
  factory AppFailure.fromCode(
    Object code, {
    String? serverMessage,
    Object? data,
  }) => AppFailure(
    failureKindOf(code),
    code: code,
    serverMessage: serverMessage,
    data: data,
  );

  /// 展示给用户的提示.
  String get message => switch (kind) {
    FailureKind.network => '网络连接失败，请重试',
    FailureKind.server => '服务器出错，请稍后再试',
    FailureKind.sessionExpired => '登录已过期，请重新登录',
    FailureKind.tooFrequent => '操作过于频繁，$retryHint',
    FailureKind.business => failureMessages[code] ?? '操作失败，请重试',
    FailureKind.forbidden => '当前账号暂无此权限',
    FailureKind.cancelled || FailureKind.unknown => '操作失败，请重试',
  };

  /// 限流响应给出的等待时间, 取自 `data.retryAfterSeconds`. 没有给出时为 null.
  Duration? get retryAfter => switch (data) {
    {'retryAfterSeconds': final num seconds} when seconds > 0 => Duration(
      seconds: seconds.ceil(),
    ),
    _ => null,
  };

  /// 何时可以重试的短句, 例如 "请 15 分钟后再试". 没有 [retryAfter] 时为 "请稍后再试".
  ///
  /// 不足一分钟按秒提示, 不足一小时向上取整到分钟, 其余向上取整到小时.
  /// 验证码的 24 小时上限会给出以小时计的等待时间.
  String get retryHint => switch (retryAfter?.inSeconds) {
    null => '请稍后再试',
    final s when s < 60 => '请 $s 秒后再试',
    final s when s <= 3600 => '请 ${(s / 60).ceil()} 分钟后再试',
    final s => '请 ${(s / 3600).ceil()} 小时后再试',
  };

  @override
  String toString() => 'AppFailure($kind, code: $code, msg: $serverMessage)';
}
