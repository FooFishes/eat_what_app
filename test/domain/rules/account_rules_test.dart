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

  test('密码登录的账号是手机号或 3–10 位用户名', () {
    expect(AccountRules.isLoginAccount('13812345678'), isTrue);
    expect(AccountRules.isLoginAccount('chi_fan'), isTrue);
    expect(AccountRules.isLoginAccount('ab'), isFalse);
    expect(AccountRules.isLoginAccount('a' * 11), isFalse);
    expect(AccountRules.isLoginAccount('吃饭'), isFalse);
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
