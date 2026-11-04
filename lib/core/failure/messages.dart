import 'package:eat/core/failure/app_failure.dart';

/// 客户端需要单独处理的业务码. 依据后端码表 `docs/api/biz-codes.md`.
abstract final class BizCodes {
  static const success = 0;

  /// 限流. 短信发送过频, 密码输错锁定都返回该码.
  ///
  /// 部分分支在 `data.retryAfterSeconds` 中给出可重试的秒数, 其余分支 `data` 为 null.
  /// 因此不能把每次 10003 都解释为同一种限制.
  static const tooFrequent = 10003;

  /// 当前场景不支持该操作. 对方未公开粉丝或关注列表时, 列表接口返回该码.
  static const notSupported = 10004;
  static const notLoggedIn = 20001;
  static const tokenInvalid = 20002;
  static const tokenExpired = 20003;

  /// 无权限. 未认证访问需认证的接口, 或受限会话访问后端未登记的接口时返回.
  static const permissionDenied = 20004;

  /// 海外站未同意跨站同步.
  ///
  /// 登录时 `data.consentProof` 带有临时凭证, 用户同意后用它提交同意.
  /// 已登录时网络层请用户同意, 同意后重发一次原请求. 该码表示原请求未被执行, 因此可以重发.
  static const consentRequired = 20005;

  /// 账号或数据正在跨站同步. 赞, 收藏, 标签, 菜品详情, 发布等接口都可能返回.
  ///
  /// 不触发自动同意, 不重发请求.
  /// 该码不保证写入未被受理, 自动重发写请求可能重复提交.
  static const dataSyncPending = 20006;

  /// 身份验证暂不可用. 登录时保留输入, 提示稍后再试.
  ///
  /// 已登录时提交同意返回该码, 表示当前会话不能提交同意, 需要重新登录取得临时凭证.
  static const authUnavailable = 20007;

  /// 同意的临时凭证无效或已过期. 需要重新登录取得新凭证.
  static const consentProofInvalid = 20008;

  /// 同意政策已更新. 处理方式同 [consentRequired], 请用户按新政策重新同意.
  static const consentPolicyChanged = 20009;

  /// 账号授权已过期. 按登录过期处理.
  ///
  /// 后端要求重新登录, 客户端不得代替用户重新同意.
  static const authorizationExpired = 20010;

  static const userNotFound = 30001;

  /// 账号已被封禁. 登录时提示封禁, 不显示码.
  ///
  /// 站点不支持受限会话时, 封禁账号登录返回该码.
  /// 受限会话在解封后, 每个请求都返回该码. 网络层据此按登录过期处理, 重新登录取得普通会话.
  static const userDisabled = 30002;
  static const usernameTaken = 30003;
  static const wrongPassword = 30004;
  static const wrongCode = 30005;
  static const passwordNotSet = 30010;
  static const mobileNotBound = 30011;

  /// 缺少人机验证票据. 需要重新进行人机验证.
  static const captchaMissing = 30015;

  /// 人机验证票据无效, 已过期或被判定有风险. 需要重新进行人机验证.
  static const captchaInvalid = 30016;

  static const captchaUnavailable = 50004;

  /// 当前状态不允许该操作.
  ///
  /// 含义随接口而定, 例如重复设置登录用户名, 未认证时发送绑定验证码, 本站未启用某项同步.
  /// 因此不归为无权限, 不触发账号状态刷新.
  static const stateNotAllowed = 40002;

  static const foodNotFound = 40008;

  /// 发布的菜品与该店已有菜品重名 (忽略空白). `data.id` 为已有菜品的 id.
  static const duplicateDish = 40016;

  /// 集群会话无效或已撤销. HTTP 401, 响应体只有字符串 `code`.
  static const clusterSessionInvalid = 'CLUSTER_SESSION_INVALID';
  static const clusterSessionRevoked = 'CLUSTER_SESSION_REVOKED';

  static const sessionCodes = {
    notLoggedIn,
    tokenInvalid,
    tokenExpired,
    authorizationExpired,
    clusterSessionInvalid,
    clusterSessionRevoked,
  };
  static const consentCodes = {consentRequired, consentPolicyChanged};

  /// 已登录时提交同意失败, 需要清除会话重新登录的业务码. 重新登录时服务端会返回临时凭证.
  static const consentSignInCodes = {authUnavailable, consentProofInvalid};
  static const captchaRetryCodes = {captchaMissing, captchaInvalid};
}

/// 业务码对应的提示. 只收录需要专门说明的业务码, 其余使用 [AppFailure.message] 的默认提示.
const failureMessages = <Object, String>{
  10001: '填写的内容有误，请检查后重试',
  10002: '填写的内容有误，请检查后重试',
  BizCodes.userNotFound: '账号或密码错误',
  BizCodes.wrongPassword: '账号或密码错误',
  BizCodes.userDisabled: '账号已被封禁',
  BizCodes.usernameTaken: '用户名已被占用',
  BizCodes.wrongCode: '验证码错误，请重新输入',
  BizCodes.passwordNotSet: '该号码未设置密码，请使用验证码登录',
  BizCodes.mobileNotBound: '请先绑定手机号',
  BizCodes.captchaMissing: '人机验证未通过，请重试',
  BizCodes.captchaInvalid: '人机验证未通过，请重试',
  BizCodes.captchaUnavailable: '人机验证暂不可用，请稍后再试',
  BizCodes.consentRequired: '需要同意数据同步后才能继续',
  BizCodes.dataSyncPending: '数据正在同步，请稍后再试',
  BizCodes.authUnavailable: '身份验证暂不可用，请稍后再试',
  BizCodes.consentProofInvalid: '验证信息已过期，请重新登录',
  BizCodes.consentPolicyChanged: '数据同步说明已更新，请重新确认',
  BizCodes.stateNotAllowed: '当前无法执行此操作，请刷新后重试',
  BizCodes.foodNotFound: '这道菜已删除',
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
