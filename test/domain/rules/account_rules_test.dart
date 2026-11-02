import 'package:eat/domain/rules/account_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('只收中国大陆手机号', () {
    expect(AccountRules.isMobile('13812345678'), isTrue);
    expect(AccountRules.isMobile('19912345678'), isTrue);
    expect(AccountRules.isMobile('12812345678'), isFalse);
    expect(AccountRules.isMobile('1381234567'), isFalse);
    expect(AccountRules.isMobile('+8613812345678'), isFalse);
  });

  test('验证码 6 位数字', () {
    expect(AccountRules.isSmsCode('246810'), isTrue);
    expect(AccountRules.isSmsCode('24681'), isFalse);
    expect(AccountRules.isSmsCode('24681a'), isFalse);
  });

  test('密码 6–64 位', () {
    expect(AccountRules.isPassword('12345'), isFalse);
    expect(AccountRules.isPassword('123456'), isTrue);
    expect(AccountRules.isPassword('x' * 64), isTrue);
    expect(AccountRules.isPassword('x' * 65), isFalse);
  });

  test('密码登录的账号按登录接口放宽到 3–64 位，手机号、用户名、邮箱都可以', () {
    expect(AccountRules.isLoginAccount('13812345678'), isTrue);
    expect(AccountRules.isLoginAccount('chi_fan'), isTrue);
    expect(AccountRules.isLoginAccount('p_0123456789ab'), isTrue);
    expect(AccountRules.isLoginAccount('zhang@mail.sdu.edu.cn'), isTrue);
    expect(AccountRules.isLoginAccount('a' * 64), isTrue);
    expect(AccountRules.isLoginAccount('ab'), isFalse);
    expect(AccountRules.isLoginAccount('a' * 65), isFalse);
    expect(
      AccountRules.isUsername('p_0123456789ab'),
      isFalse,
      reason: '设置用户名的规则不变',
    );
  });

  test('只认山大的两个邮箱后缀，不分大小写', () {
    expect(AccountRules.isSduEmail('2021@mail.sdu.edu.cn'), isTrue);
    expect(AccountRules.isSduEmail(' Zhang@SDU.edu.cn '), isTrue);
    expect(AccountRules.isSduEmail('a@qq.com'), isFalse);
    expect(AccountRules.isSduEmail('a@fake-sdu.edu.cn'), isFalse);
    expect(AccountRules.isSduEmail('@sdu.edu.cn'), isFalse);
  });

  test('手机号中间四位打码', () {
    expect(AccountRules.maskMobile('13812345678'), '138 **** 5678');
    expect(AccountRules.maskMobile('123'), '123');
  });
}
