import 'package:eat/core/failure/app_failure.dart';

/// 客户端需要单独处理的业务码. 依据后端码表 `docs/api/biz-codes.md`.
abstract final class BizCodes {
  static const success = 0;

  /// 参数不合法. 具体原因写在 `msg` 里, 有的写给用户 (如内容里有联系方式), 有的是客户端的问题 (如字段名).
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

  /// 一键登录的取号凭证无效, 已使用或无法换取手机号. 由于凭证仅限单次使用, 重试时需重新拉起授权页.
  static const oneClickTokenInvalid = 20002;

  /// 无权限. 未通过认证却访问受限接口时返回.
  ///
  /// 对方未公开粉丝或关注列表时, 列表接口也返回该码.
  static const permissionDenied = 20004;

  /// 登录请求缺少隐私政策版本号, 仅在服务端发布过政策后出现.
  ///
  /// 服务端会在核销验证码前校验同意状态, 用户确认后可使用同一验证码或密码重试.
  static const consentRequired = 20005;

  /// 服务端未开启一键登录.
  static const oneClickUnavailable = 20007;

  /// 隐私政策已更新.
  ///
  /// 登录时表示携带的政策版本号已过期, 处理方式同 [consentRequired].
  /// 已登录时由网络层引导用户重新确认, 确认后重发原请求 (该码表示原请求尚未执行, 可安全重发).
  static const consentPolicyChanged = 20009;

  static const userNotFound = 30001;

  /// 账号不可用, 或封禁中的受限会话执行了不允许的操作.
  ///
  /// 封禁的账号仍能登录. 受限会话被拒绝时 `data` 带 `reason` 和 `banUntil`, 网络层按无权限处理.
  /// `data` 为空表示账号已不存在, 服务端已让会话下线, 网络层按登录过期处理.
  static const userDisabled = 30002;
  static const usernameTaken = 30003;

  /// 密码校验失败, 涵盖账号不存在, 未设置密码, 密码错误, 以及修改密码时旧密码错误.
  static const wrongPassword = 30004;
  static const wrongCode = 30005;

  /// 账号已完成学生认证.
  static const alreadyVerified = 30006;

  /// 邮箱认证链接无效, 已使用或不属于当前登录账号.
  static const emailTokenInvalid = 30008;

  /// 邮箱不是山大邮箱.
  static const emailNotSdu = 30009;

  /// 账号尚未设置密码, 仅在使用旧密码修改密码时返回.
  static const passwordNotSet = 30010;
  static const mobileNotBound = 30011;

  /// 缺少人机验证票据, 需重新完成人机验证.
  static const captchaMissing = 30015;

  /// 人机验证票据无效, 已过期或触发风控, 需重新完成人机验证.
  static const captchaInvalid = 30016;

  /// 账号处于注销冷静期内, 登录时 `data.deleteAt` 为彻底删除的 Unix 毫秒时间戳.
  ///
  /// 在原申请设备上携带撤销凭据登录可直接撤销注销, 不会收到该码.
  /// 冷静期内服务端会下线全部会话, 已登录请求收到该码时按登录过期处理.
  static const accountDeletionPending = 30017;

  /// 第三方服务不可用, 超时, 返回异常, 例如短信服务拒绝发送, 一键登录的运营商接口出错.
  static const thirdPartyUnavailable = 50001;
  static const thirdPartyTimeout = 50002;
  static const thirdPartyBadResponse = 50003;

  static const captchaUnavailable = 50004;

  /// 操作失败. 含义随接口而定, 原因写在 `msg` 里 (见 [userFacingMessage]), 不进入码表.
  ///
  /// 例如号码或邮箱已被其他账号使用, 统一认证不是当前账号发起的, 要下线的设备不存在.
  static const opFailed = 40001;

  /// 当前状态不允许该操作.
  ///
  /// 含义随接口而定, 例如重复设置登录用户名, 未认证时发送绑定验证码, 本站未启用某项同步.
  /// 因此不归为无权限, 不触发账号状态刷新.
  static const stateNotAllowed = 40002;

  /// 重复提交. 推送, 上传等模块用该码, 含义随接口而定, 因此不登记全局提示.
  static const duplicateSubmit = 40004;

  static const foodNotFound = 40008;

  /// 店铺不存在, 如已被管理员删除.
  static const restaurantNotFound = 40009;

  /// 发布的菜品与该店已有菜品重名 (忽略空白). `data.id` 为已有菜品的 id.
  static const duplicateDish = 40016;

  /// 新建店铺时同一地图地点已存在店铺, 或 200 m 内有同名店铺, `data.duplicates` 为候选重复店铺列表.
  ///
  /// 该码仅作确认提示, 用户确认并非同一家后可携带 `force` 重新提交.
  static const shopMayExist = 40017;

  static const sessionCodes = {notLoggedIn};
  static const consentCodes = {consentRequired, consentPolicyChanged};
  static const captchaRetryCodes = {captchaMissing, captchaInvalid};
}

/// 业务码对应的提示. 只收录需要专门说明的业务码, 其余使用 [AppFailure.message] 的默认提示.
const failureMessages = <Object, String>{
  10001: '提交的内容有误，请检查后重试',
  10002: '提交的内容有误，请检查后重试',
  BizCodes.oneClickTokenInvalid: '本机号码验证失败，请重试',
  BizCodes.oneClickUnavailable: '一键登录暂不可用，请用验证码登录',
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
  BizCodes.thirdPartyUnavailable: '服务暂不可用，请稍后再试',
  BizCodes.thirdPartyTimeout: '服务暂不可用，请稍后再试',
  BizCodes.thirdPartyBadResponse: '服务暂不可用，请稍后再试',
  BizCodes.captchaUnavailable: '人机验证暂不可用，请稍后再试',
  BizCodes.consentRequired: '同意隐私政策后才能继续',
  BizCodes.consentPolicyChanged: '隐私政策已更新，请重新确认',
  BizCodes.stateNotAllowed: '当前无法执行此操作，请刷新后重试',
  BizCodes.foodNotFound: '这道菜已删除',
  BizCodes.restaurantNotFound: '这家店已删除',
  BizCodes.duplicateDish: '这家店已有这道菜',
  BizCodes.accountDeletionPending: '账号注销中，在申请注销的设备上重新登录可以撤销',
};

/// 返回业务码对应的失败类别.
FailureKind failureKindOf(Object code) {
  if (code == BizCodes.tooFrequent) return FailureKind.tooFrequent;
  if (BizCodes.sessionCodes.contains(code)) return FailureKind.sessionExpired;
  if (code == BizCodes.permissionDenied) return FailureKind.forbidden;
  if (failureMessages.containsKey(code)) return FailureKind.business;
  if (code is int && code ~/ 10000 == 9) return FailureKind.server;
  return FailureKind.unknown;
}

/// 默认文案只是笼统说法的业务码在后端的默认文案 (后端 `BizCode`).
///
/// 后端带上具体原因时 `msg` 是 "默认文案：原因" (10001 除外, 原因直接替换默认文案), 前缀要去掉;
/// 只有默认文案时说不清原因, 不如客户端的提示.
const _genericTexts = <Object, String>{
  BizCodes.paramInvalid: '参数非法',
  BizCodes.paramMissing: '参数缺失',
  BizCodes.tooFrequent: '请求频率过高',
  BizCodes.opFailed: '操作失败',
  BizCodes.stateNotAllowed: '当前状态不允许该操作',
  BizCodes.duplicateSubmit: '重复提交',
  BizCodes.thirdPartyUnavailable: '第三方服务不可用',
  BizCodes.thirdPartyTimeout: '第三方接口超时',
  BizCodes.thirdPartyBadResponse: '第三方返回异常',
};

/// 不用 `msg` 的业务码: 客户端另有流程, 或后端的文案放在客户端的场景里不对.
///
/// 未登录走登录流程; 20002 说的是取号或核验凭证, 文案是内部术语; 无权限弹拦截对话框;
/// 一键登录不可用时静默改用短信; 30002 弹封禁对话框或按会话失效处理, 登录时说账号已被封禁;
/// 店铺可能重复由新建店铺页按 `data.duplicates` 自己写提示; 接口不存在是客户端或版本的问题.
const _clientOwnedCodes = {
  BizCodes.notLoggedIn,
  BizCodes.oneClickTokenInvalid,
  BizCodes.permissionDenied,
  BizCodes.oneClickUnavailable,
  BizCodes.userDisabled,
  BizCodes.shopMayExist,
  BizCodes.notSupported,
};

/// `msg` 里允许出现的拉丁字母: 图片格式, 文件大小单位和山大邮箱的域名.
/// 其余拉丁字母多是字段名, 枚举值或英文的校验默认文案.
final _allowedLatin = RegExp(
  r'JPEG|JPG|PNG|WebP|GIF|MB|KB|@mail\.sdu\.edu\.cn|@sdu\.edu\.cn',
);
final _latin = RegExp('[A-Za-z]');

/// 不合文案规范的口语和感叹号 (设计规范「文案」).
final _offStyle = RegExp('吧|一下|！|!');

/// 后端确实会返回, 但不能给用户看的 `msg`.
const _deniedTexts = {
  /// 内部: Hibernate 的中文默认文案, 不说是哪一项.
  '不能为空',

  /// 内部: 客户端多传了手机号.
  '此场景的手机号由服务器确定',

  /// 内部: 要下线的设备已不在, 页面刷新列表.
  '设备会话不存在',

  /// 内部: 推送令牌的并发登记, 后台重试.
  '设备令牌刚被登记，请重试',

  /// 内部: 消息卡片已过期, 静默处理.
  '通知不存在',

  /// 内部: 客户端只传了一个坐标.
  '缺少经纬度',

  /// 内部: Web 一键登录的回跳地址配置.
  '页面地址不合法',

  /// 内部: 客户端同时传了验证码和核验凭证.
  '短信验证码与号码核验凭据只能提供一种',

  /// 内部: 客户端没传验证码也没传核验凭证.
  '请提供短信验证码或号码核验凭据',

  /// 用词: 产品里叫「菜」, 客户端说「这道菜已删除」.
  '菜品不存在',

  /// 用词: 产品里叫「店」, 客户端说「这家店已删除」.
  '餐厅不存在',

  /// 用词: 产品里叫「商圈」.
  '商场不存在',

  /// 笼统: 客户端的提示还说了怎么撤销.
  '账号注销中',

  /// 误导: 统一认证过的账号也返回 30006, 不一定是邮箱.
  '该用户已通过邮箱验证',
};

/// 从服务端的 `msg` 取出可以直接给用户看的原因, 不能用时返回 null.
///
/// 后端的原因合适就用它, 码表和页面的提示只在不能用时兜底.
/// [_clientOwnedCodes] 和系统错误 (9xxxx) 不看 `msg`.
/// 去掉默认文案前缀后, 空的, 只剩默认文案的, 带拉丁字母的, 不合文案规范的, 以及 [_deniedTexts] 都不用.
String? userFacingMessage(Object? code, String? msg) {
  if (code is! int || _clientOwnedCodes.contains(code)) return null;
  if (code ~/ 10000 == 9) return null;
  var text = msg?.trim() ?? '';
  final generic = _genericTexts[code];
  if (generic != null && text.startsWith('$generic：')) {
    text = text.substring(generic.length + 1).trim();
  }
  if (text.isEmpty ||
      text == generic ||
      text.replaceAll(_allowedLatin, '').contains(_latin) ||
      text.contains(_offStyle) ||
      _deniedTexts.contains(text)) {
    return null;
  }
  return text;
}
