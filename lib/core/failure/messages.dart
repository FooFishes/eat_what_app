import 'package:eat/core/failure/app_failure.dart';

/// 客户端需要单独处理的业务码. 依据后端码表 `docs/api/biz-codes.md`.
abstract final class BizCodes {
  static const success = 0;

  /// 参数不合法.
  ///
  /// 对象不存在的部分情况也返回该码, 例如评论不存在, 被回复的评论不存在, 消息卡片不存在.
  static const paramInvalid = 10001;

  /// 缺少参数. 换绑手机时也表示当前号码的校验已过期, 需要重新验证.
  static const paramMissing = 10002;

  /// 限流. 短信发送过频, 密码输错锁定都返回该码.
  ///
  /// 部分分支在 `data.retryAfterSeconds` 中给出可重试的秒数, 其余分支 `data` 为 null.
  /// 因此不能把每次 10003 都解释为同一种限制.
  static const tooFrequent = 10003;

  /// 接口不存在 (HTTP 404) 或请求方法不支持 (HTTP 405).
  static const notSupported = 10004;

  /// 未登录, 包括登录过期和在其他设备上被下线.
  static const notLoggedIn = 20001;

  /// 无权限. 未认证访问需认证的接口时返回.
  ///
  /// 对方未公开粉丝或关注列表时, 列表接口也返回该码.
  static const permissionDenied = 20004;

  /// 登录请求没有带隐私政策的版本. 只在服务端发布过政策后出现.
  ///
  /// 服务端在核销验证码之前校验同意. 用户同意后用同一个验证码或密码重试.
  static const consentRequired = 20005;

  /// 隐私政策已更新.
  ///
  /// 登录时表示带的版本不是当前版本, 处理方式同 [consentRequired].
  /// 已登录时网络层请用户同意, 同意后重发一次原请求. 该码表示原请求未被执行, 因此可以重发.
  static const consentPolicyChanged = 20009;

  static const userNotFound = 30001;

  /// 账号不可用, 或封禁中的受限会话执行了不允许的操作.
  ///
  /// 封禁的账号仍能登录. 受限会话被拒绝时 `data` 带 `reason` 和 `banUntil`, 网络层按无权限处理.
  /// `data` 为空表示账号已不存在, 服务端已让会话下线, 网络层按登录过期处理.
  static const userDisabled = 30002;
  static const usernameTaken = 30003;

  /// 密码登录的所有失败: 账号不存在, 没设过密码, 密码错误. 也用于改密码时旧密码错误.
  static const wrongPassword = 30004;
  static const wrongCode = 30005;

  /// 账号已完成学生认证.
  static const alreadyVerified = 30006;

  /// 邮箱认证链接无效, 已用过, 或不属于当前登录的账号.
  static const emailTokenInvalid = 30008;

  /// 邮箱不是山大邮箱.
  static const emailNotSdu = 30009;

  /// 账号没设过密码. 只在用旧密码修改密码时出现.
  static const passwordNotSet = 30010;
  static const mobileNotBound = 30011;

  /// 缺少人机验证票据. 需要重新进行人机验证.
  static const captchaMissing = 30015;

  /// 人机验证票据无效, 已过期或被判定有风险. 需要重新进行人机验证.
  static const captchaInvalid = 30016;

  /// 账号在注销冷静期内. 登录时 `data.deleteAt` 是彻底删除的时间 (Unix 毫秒).
  ///
  /// 冷静期内服务端让账号的所有会话下线, 带凭证的请求收到该码时按登录过期处理.
  static const accountDeletionPending = 30017;

  static const captchaUnavailable = 50004;

  /// 操作失败. 含义随接口而定, 由页面就地说明, 不进入码表.
  ///
  /// 例如号码或邮箱已被其他账号使用, 统一认证不是当前账号发起的, 要下线的设备不存在.
  static const opFailed = 40001;

  /// 当前状态不允许该操作.
  ///
  /// 含义随接口而定, 例如重复设置登录用户名, 未认证时发送绑定验证码, 本站未启用某项同步.
  /// 因此不归为无权限, 不触发账号状态刷新.
  static const stateNotAllowed = 40002;

  /// 新建或修改店铺时, 附近 100 m 内已有同名的店, 或地图地点已被别的店使用. `data` 为空.
  ///
  /// 推送等其他模块也用该码表示重复提交, 含义随接口而定, 因此不登记全局提示, 由页面就地处理.
  static const duplicateSubmit = 40004;

  static const foodNotFound = 40008;

  /// 店铺不存在, 如已被管理员删除.
  static const restaurantNotFound = 40009;

  /// 发布的菜品与该店已有菜品重名 (忽略空白). `data.id` 为已有菜品的 id.
  static const duplicateDish = 40016;

  static const sessionCodes = {notLoggedIn};
  static const consentCodes = {consentRequired, consentPolicyChanged};
  static const captchaRetryCodes = {captchaMissing, captchaInvalid};
}

/// 业务码对应的提示. 只收录需要专门说明的业务码, 其余使用 [AppFailure.message] 的默认提示.
const failureMessages = <Object, String>{
  10001: '提交的内容有误，请检查后重试',
  10002: '提交的内容有误，请检查后重试',
  BizCodes.userNotFound: '用户不存在',
  BizCodes.wrongPassword: '账号或密码错误',
  BizCodes.userDisabled: '账号已被封禁',
  BizCodes.usernameTaken: '用户名已被占用',
  BizCodes.wrongCode: '验证码错误，请重新输入',
  BizCodes.alreadyVerified: '账号已经认证过了',
  BizCodes.emailTokenInvalid: '链接无效或已过期，请在发起认证的账号上打开',
  BizCodes.emailNotSdu: '请填写山大邮箱',
  BizCodes.passwordNotSet: '还没有设置过密码',
  BizCodes.mobileNotBound: '请先绑定手机号',
  BizCodes.captchaMissing: '人机验证未通过，请重试',
  BizCodes.captchaInvalid: '人机验证未通过，请重试',
  BizCodes.captchaUnavailable: '人机验证暂不可用，请稍后再试',
  BizCodes.consentRequired: '同意隐私政策后才能继续',
  BizCodes.consentPolicyChanged: '隐私政策已更新，请重新确认',
  BizCodes.stateNotAllowed: '当前无法执行此操作，请刷新后重试',
  BizCodes.foodNotFound: '这道菜已删除',
  BizCodes.restaurantNotFound: '这家店已删除',
  BizCodes.duplicateDish: '这家店已有这道菜',
};

/// 业务码所属的失败类别.
FailureKind failureKindOf(Object code) {
  if (code == BizCodes.tooFrequent) return FailureKind.tooFrequent;
  if (BizCodes.sessionCodes.contains(code)) return FailureKind.sessionExpired;
  if (code == BizCodes.permissionDenied) return FailureKind.forbidden;
  if (failureMessages.containsKey(code)) return FailureKind.business;
  if (code is int && code ~/ 10000 == 9) return FailureKind.server;
  return FailureKind.unknown;
}
