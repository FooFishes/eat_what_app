import 'package:eat/core/failure/app_failure.dart';

// TODO: 接口文档只声明 0 为成功, 其余业务码取自 legacy 实现和接口说明, 未经后端确认.
// 后端提供完整码表后逐项核对.
/// 客户端需要单独处理的业务码.
abstract final class BizCodes {
  static const success = 0;
  static const tooFrequent = 10003;
  static const notLoggedIn = 20001;
  static const tokenInvalid = 20002;
  static const tokenExpired = 20003;
  static const permissionDenied = 20004;

  /// 海外站未同意跨站同步. 网络层自动同意后重发请求.
  static const consentRequired = 20005;

  /// 跨站授权过期或尚未同步. 处理方式同 [consentRequired].
  static const consentExpired = 20006;

  static const userNotFound = 30001;
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

  /// 发布的菜品与该店已有菜品重名 (忽略空白). `data.id` 为已有菜品的 id.
  static const duplicateDish = 40016;

  /// `/auth/getCode` 和 `/user/getCode` 在账号未认证时返回的字符串业务码.
  static const stateNotAllowed = 'STATE_NOT_ALLOWED';

  static const sessionCodes = {notLoggedIn, tokenInvalid, tokenExpired};
  static const consentCodes = {consentRequired, consentExpired};
  static const captchaRetryCodes = {captchaMissing, captchaInvalid};
}

/// 业务码对应的提示. 只收录需要专门说明的业务码, 其余使用 [AppFailure.message] 的默认提示.
const failureMessages = <Object, String>{
  10001: '填写的内容有误，请检查后重试',
  10002: '填写的内容有误，请检查后重试',
  BizCodes.userNotFound: '账号或密码错误',
  BizCodes.wrongPassword: '账号或密码错误',
  BizCodes.userDisabled: '账号已停用',
  BizCodes.usernameTaken: '用户名已被占用',
  BizCodes.wrongCode: '验证码错误，请重新输入',
  BizCodes.passwordNotSet: '该号码未设置密码，请使用验证码登录',
  BizCodes.mobileNotBound: '请先绑定手机号',
  BizCodes.captchaMissing: '人机验证未通过，请重试',
  BizCodes.captchaInvalid: '人机验证未通过，请重试',
  BizCodes.captchaUnavailable: '人机验证暂不可用，请稍后再试',
  BizCodes.duplicateDish: '这家店已有这道菜',
};

/// 业务码所属的失败类别.
FailureKind failureKindOf(Object code) {
  if (code == BizCodes.tooFrequent) return FailureKind.tooFrequent;
  if (BizCodes.sessionCodes.contains(code)) return FailureKind.sessionExpired;
  if (code == BizCodes.permissionDenied || code == BizCodes.stateNotAllowed) {
    return FailureKind.forbidden;
  }
  if (failureMessages.containsKey(code)) return FailureKind.business;
  if (code is int && code ~/ 10000 == 9) return FailureKind.server;
  return FailureKind.unknown;
}
