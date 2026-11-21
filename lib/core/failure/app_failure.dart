import 'package:eat/core/failure/messages.dart';

/// 失败的类别, 决定页面的处理方式: 就地重试, 返回登录页, 弹出拦截对话框, 或只显示提示.
enum FailureKind {
  /// 网络不可达, 包括连接错误, DNS 解析失败与超时, 读请求会自动重试.
  network,

  /// 服务端错误, 包括 HTTP 5xx 与 9xxxx 系统错误.
  server,

  /// 登录已过期, 网络层会同步通知登录态清除本地凭证.
  sessionExpired,

  /// 服务端判定无权限 (未认证或已封禁), 页面按最新的账号状态弹出拦截对话框.
  forbidden,

  tooFrequent,

  /// 码表中已登记的业务错误, 或服务端说明了原因 ([AppFailure.userMessage]) 的业务错误.
  business,

  /// 请求已取消 (例如用户已离开页面), 此时不展示提示.
  cancelled,

  /// 未归类的失败, 如未在码表登记的业务码或响应解析失败.
  unknown,
}

/// 网络层抛出的唯一异常类型.
///
/// 页面只读取 [kind] 和 [message]. 业务码仅用于就地提示, 例如验证码错误.
/// 错误码不展示给用户. 服务端的 `msg` 原样放在 [serverMessage] 里, 用于调试和上报;
/// 其中能给用户看的原因放进 [userMessage] (见 [userFacingMessage]).
class const AppFailure(
  final FailureKind kind, {
  final Object? code,
  final String? serverMessage,

  /// 失败响应外壳中携带的 `data`, 例如发布重名菜品时已有菜品的 id.
  final Object? data,

  /// 服务端写给用户的原因, 有值时 [message] 使用它, 码表和页面的提示只作兜底.
  ///
  /// 由 `ApiClient` 用 [userFacingMessage] 取出, 只在业务错误, 未知错误和限流时有值.
  final String? userMessage,
}) implements Exception {
  const AppFailure.network() : this(FailureKind.network);

  const AppFailure.cancelled() : this(FailureKind.cancelled);

  /// 根据码表将业务码转换为 [AppFailure], 由码表决定失败类别与提示文案.
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
  ///
  /// 限流时服务端说明的原因以 "请稍后再试" 结尾且给出了等待时间, 结尾换成 [retryHint].
  String get message =>
      _userMessage ??
      switch (kind) {
        FailureKind.network => '网络连接失败，请重试',
        FailureKind.server => '服务器出错，请稍后再试',
        FailureKind.sessionExpired => '登录已过期，请重新登录',
        FailureKind.tooFrequent => '操作过于频繁，$retryHint',
        FailureKind.business => failureMessages[code] ?? '操作失败，请重试',
        FailureKind.forbidden => '当前账号暂无此权限',
        FailureKind.cancelled || FailureKind.unknown => '操作失败，请重试',
      };

  String? get _userMessage {
    const later = '请稍后再试';
    final text = switch (kind) {
      FailureKind.business ||
      FailureKind.unknown ||
      FailureKind.tooFrequent => userMessage,
      _ => null,
    };
    if (text == null ||
        kind != FailureKind.tooFrequent ||
        retryAfter == null ||
        !text.endsWith(later)) {
      return text;
    }
    return text.substring(0, text.length - later.length) + retryHint;
  }

  /// 限流响应中指定的等待时间, 取自 `data.retryAfterSeconds`, 未提供时返回 null.
  Duration? get retryAfter => switch (data) {
    {'retryAfterSeconds': final num seconds} when seconds > 0 => Duration(
      seconds: seconds.ceil(),
    ),
    _ => null,
  };

  /// 描述何时可重试的短句 (如 "请 15 分钟后再试"), 无 [retryAfter] 时返回 "请稍后再试".
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
