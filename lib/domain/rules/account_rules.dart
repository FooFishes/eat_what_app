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

  /// 密码长度为 6–64 位.
  static bool isPassword(String value) =>
      value.length >= 6 && value.length <= 64;

  /// 密码登录的账号: 手机号, 或 3–10 位由字母, 数字, 下划线组成的用户名.
  static bool isLoginAccount(String value) =>
      isMobile(value) || _username.hasMatch(value);

  /// 是否为可用于学生认证的山大邮箱 (`@mail.sdu.edu.cn` 或 `@sdu.edu.cn`). 服务端会再次校验.
  static bool isSduEmail(String value) {
    final email = value.trim().toLowerCase();
    final at = email.lastIndexOf('@');
    if (at <= 0) return false;
    final domain = email.substring(at + 1);
    return domain == 'mail.sdu.edu.cn' || domain == 'sdu.edu.cn';
  }

  /// 把手机号打码为 "138 **** 5678" 的形式. 长度不是 11 位时原样返回.
  static String maskMobile(String mobile) {
    if (mobile.length != 11) return mobile;
    return '${mobile.substring(0, 3)} **** ${mobile.substring(7)}';
  }
}
