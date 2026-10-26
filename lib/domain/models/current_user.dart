/// 学生认证的方式，[label] 是界面上的叫法。
enum VerifyMethod {
  sso('山大统一认证'),
  schoolEmail('山大邮箱');

  const VerifyMethod(this.label);

  final String label;
}

/// 当前登录的账号，来自 `GET /user/info`。
///
/// 昵称是对外展示的名字，可以重复；[username] 是登录用的名字，没设过时为 null（产品 7.1）。
/// 手机号只用来登录和确认身份，展示时要打码。
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
  required final bool banned,
  final String? banReason,
  final DateTime? bannedAt,
});
