/// 登录和认证表单的校验规则.
///
/// 规则与接口的限制一致, 用于提交前在客户端预先拦截.
abstract final class AccountRules {
  static final _mobile = RegExp(r'^1[3-9]\d{9}$');
  static final _smsCode = RegExp(r'^\d{6}$');
  static final _username = RegExp(r'^[A-Za-z0-9_]{3,10}$');

  /// 是否为中国大陆手机号. 不支持其他地区的号码.
  static bool isMobile(String value) => _mobile.hasMatch(value);

  static bool isSmsCode(String value) => _smsCode.hasMatch(value);

  /// 用户名为 3–10 位字母, 数字或下划线, 区分大小写.
  static bool isUsername(String value) => _username.hasMatch(value);

  /// 密码长度为 6–64 位.
  static bool isPassword(String value) =>
      value.length >= 6 && value.length <= 64;

  /// 校验密码登录账号格式 (支持手机号, 用户名或邮箱), 与登录接口一致, 仅限制长度为 3–64 位.
  ///
  /// 不按 [isUsername] 校验: 系统生成的登录名形如 `p_` 加 12 位十六进制, 超过 10 位.
  /// 按用户名规则拦截会让这些账号和邮箱都无法用密码登录.
  static bool isLoginAccount(String value) =>
      value.length >= 3 && value.length <= 64;

  /// 是否为可用于学生认证的山大邮箱 (`@mail.sdu.edu.cn` 或 `@sdu.edu.cn`). 服务端会再次校验.
  static bool isSduEmail(String value) {
    final email = value.trim().toLowerCase();
    final at = email.lastIndexOf('@');
    if (at <= 0) return false;
    final domain = email.substring(at + 1);
    return domain == 'mail.sdu.edu.cn' || domain == 'sdu.edu.cn';
  }

  /// 将手机号脱敏为 "138 **** 5678" 格式, 长度不为 11 位时原样返回.
  static String maskMobile(String mobile) {
    if (mobile.length != 11) return mobile;
    return '${mobile.substring(0, 3)} **** ${mobile.substring(7)}';
  }
}
