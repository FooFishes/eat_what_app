/// 学生认证方式. [label] 是界面上的名称.
enum VerifyMethod {
  sso('山大统一认证'),
  schoolEmail('山大邮箱');

  const VerifyMethod(this.label);

  final String label;
}

/// 账号已完成的学生认证, 来自 `GET /auth/verify`. 未认证时 [method] 为 null.
class const VerifyStatus({
  required final bool verified,
  final VerifyMethod? method,
});

/// 当前登录的账号, 来自 `GET /user/info`.
///
/// - 昵称是对外展示的名字, 允许重复.
/// - [username] 是登录用的用户名, 未设置时为 null.
/// - 手机号只用于登录和身份确认, 展示时必须打码.
class const CurrentUser({
  required final int id,
  required final String nickname,
  final String? username,
  final String? avatarUrl,
  final String? phone,
  final String? signature,
  required final bool hasPassword,
  required final bool verified,
  final VerifyMethod? verifyMethod,
  final String? verifiedEmail,

  /// 用户等级, 取值 1 到 10, 服务端未返回时为 null.
  final int? level,
  final bool banned = false,
  final String? banReason,

  /// 封禁截止时间, 仅在限时封禁时有值, 为 null 表示永久封禁或未被封禁.
  final DateTime? banUntil,
});
