/// 业务码枚举
///
/// 业务码结构：A B C D E
/// - A: 错误大类（0=成功, 1=通用错误, 2=认证, 3=用户, 4=业务逻辑, 5=外部依赖, 9=系统错误）
/// - B: 子系统编号
/// - C: 模块编号
/// - D-E: 具体错误编号
enum BizCode {
  // ==================== 成功 (0xxxx) ====================
  /// 业务成功
  success(0, '成功'),

  // ==================== 通用错误 (1xxxx) ====================
  /// 参数非法
  invalidParam(10001, '参数非法'),

  /// 参数缺失
  missingParam(10002, '参数缺失'),

  /// 请求频率过高
  rateLimitExceeded(10003, '请求频率过高'),

  /// 不支持的操作
  unsupportedOperation(10004, '不支持的操作'),

  // ==================== 认证与鉴权 (2xxxx) ====================
  /// 用户未登录
  notLogin(20001, '用户未登录'),

  /// Token 无效
  invalidToken(20002, 'Token 无效'),

  /// Token 已过期
  tokenExpired(20003, 'Token 已过期'),

  /// 权限不足
  permissionDenied(20004, '权限不足'),

  // ==================== 用户模块 (3xxxx) ====================
  /// 用户不存在
  userNotFound(30001, '用户不存在'),

  /// 用户被禁用
  userDisabled(30002, '用户被禁用'),

  /// 用户名已存在
  usernameExists(30003, '用户名已存在'),

  /// 密码错误
  wrongPassword(30004, '密码错误'),

  /// 验证码错误
  wrongVerificationCode(30005, '验证码错误'),

  /// 该用户已通过邮箱验证
  emailAlreadyVerified(30006, '该用户已通过邮箱验证'),

  /// 邮箱格式不正确
  invalidEmailFormat(30007, '邮箱格式不正确'),

  /// 邮箱验证链接无效或已过期
  invalidOrExpiredEmailLink(30008, '邮箱验证链接无效或已过期'),

  /// 仅支持山东大学邮箱（@sdu.edu.cn 或 @mail.sdu.edu.cn）
  onlySduEmailAllowed(30009, '仅支持山东大学邮箱（@sdu.edu.cn 或 @mail.sdu.edu.cn）'),

  // ==================== 业务逻辑错误 (4xxxx) ====================
  /// 操作失败
  operationFailed(40001, '操作失败'),

  /// 当前状态不允许该操作
  invalidState(40002, '当前状态不允许该操作'),

  /// 资源不足
  insufficientResources(40003, '资源不足'),

  /// 重复提交
  duplicateSubmission(40004, '重复提交'),

  // ==================== 外部依赖错误 (5xxxx) ====================
  /// 第三方服务不可用
  externalServiceUnavailable(50001, '第三方服务不可用'),

  /// 第三方接口超时
  externalServiceTimeout(50002, '第三方接口超时'),

  /// 第三方返回异常
  externalServiceError(50003, '第三方返回异常'),

  // ==================== 系统级错误 (9xxxx) ====================
  /// 系统内部异常
  systemError(90001, '系统内部异常'),

  /// 数据库异常
  databaseError(90002, '数据库异常'),

  /// Redis 异常
  redisError(90003, 'Redis 异常'),

  /// 未捕获异常
  uncaughtException(90004, '未捕获异常');

  /// 业务码
  final int code;

  /// 业务码描述
  final String message;

  const BizCode(this.code, this.message);

  /// 是否成功
  bool get isSuccess => code == 0;

  /// 是否失败
  bool get isFailure => code != 0;

  /// 根据业务码查找枚举
  static BizCode? fromCode(int code) {
    try {
      return BizCode.values.firstWhere((e) => e.code == code);
    } catch (_) {
      return null;
    }
  }

  /// 获取错误分类
  static ErrorCategory getErrorCategory(int code) {
    int category = code ~/ 10000;
    return switch (category) {
      1 => ErrorCategory.param,
      2 => ErrorCategory.auth,
      3 => ErrorCategory.user,
      4 => ErrorCategory.business,
      5 => ErrorCategory.external,
      9 => ErrorCategory.system,
      _ => ErrorCategory.unknown,
    };
  }

  /// 是否需要重新登录
  static bool requireReLogin(int code) {
    return code == notLogin.code ||
        code == invalidToken.code ||
        code == tokenExpired.code;
  }

  @override
  String toString() => 'BizCode($code, $message)';
}

enum ErrorCategory {
  param,
  auth,
  user,
  business,
  external,
  system,
  unknown,
}