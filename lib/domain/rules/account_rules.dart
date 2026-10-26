/// 登录、认证表单的校验规则，和接口的限制一致，提交前在客户端先拦一次。
abstract final class AccountRules {
  static final _mobile = RegExp(r'^1[3-9]\d{9}$');
  static final _smsCode = RegExp(r'^\d{6}$');
  static final _username = RegExp(r'^[A-Za-z0-9_]{3,10}$');

  /// 只支持中国大陆手机号，11 位、1 开头（产品 6.2）。
  static bool isMobile(String value) => _mobile.hasMatch(value);

  static bool isSmsCode(String value) => _smsCode.hasMatch(value);

  /// 密码 6–64 位（产品 6.12）。
  static bool isPassword(String value) =>
      value.length >= 6 && value.length <= 64;

  /// 密码登录的账号：手机号，或者 3–10 位字母、数字、下划线的用户名（产品 7.1）。
  static bool isLoginAccount(String value) =>
      isMobile(value) || _username.hasMatch(value);

  /// 能用来认证的山大邮箱：`@mail.sdu.edu.cn` 或 `@sdu.edu.cn`，服务端还会再查一次。
  static bool isSduEmail(String value) {
    final email = value.trim().toLowerCase();
    final at = email.lastIndexOf('@');
    if (at <= 0) return false;
    final domain = email.substring(at + 1);
    return domain == 'mail.sdu.edu.cn' || domain == 'sdu.edu.cn';
  }

  /// 手机号打码成「138 **** 5678」；不是 11 位时原样返回。
  static String maskMobile(String mobile) {
    if (mobile.length != 11) return mobile;
    return '${mobile.substring(0, 3)} **** ${mobile.substring(7)}';
  }
}
