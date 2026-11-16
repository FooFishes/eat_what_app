import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

Map<String, Object?> _token() => FakeAdapter.ok({
  'tokenName': 'satoken',
  'tokenValue': 'tk',
  'isLogin': true,
  'loginId': '42',
});

void main() {
  late TestEnv env;
  late AuthRepository auth;

  setUp(() async {
    env = TestEnv();
    final container = await env.container();
    auth = container.read(authRepositoryProvider);
  });

  group('验证码登录', () {
    test('带上调用方给的政策版本，自己不读政策', () async {
      env.adapter.on('POST /auth/phone/login', [_token()]);

      final result = await auth.loginWithCode(
        '13812345678',
        '246810',
        policyVersion: 'v3',
      );
      expect(result.token.name, 'satoken');
      expect(result.token.value, 'tk');
      expect(result.newUser, isFalse);
      expect(env.adapter.sent('POST /auth/phone/login').single.body, {
        'mobile': '13812345678',
        'code': '246810',
        'device': 'APP',
        'policyVersion': 'v3',
        'installId': testInstallId,
      });
      expect(env.adapter.sent('GET /auth/consent/policy'), isEmpty);
    });

    test('还没发布政策时不带版本', () async {
      env.adapter.on('POST /auth/phone/login', [_token()]);

      await auth.loginWithCode('13812345678', '246810');
      final body =
          env.adapter.sent('POST /auth/phone/login').single.body as Map;
      expect(body.containsKey('policyVersion'), isFalse);
    });

    test('响应带 newUser 时记下是新号码', () async {
      env.adapter.on('POST /auth/phone/login', [
        FakeAdapter.ok({
          'tokenName': 'satoken',
          'tokenValue': 'tk',
          'newUser': true,
        }),
      ]);

      final result = await auth.loginWithCode('13812345678', '246810');
      expect(result.newUser, isTrue);
    });

    test('要求同意时原样抛出，不替用户同意', () async {
      env.adapter.on('POST /auth/phone/login', [FakeAdapter.fail(20005)]);

      await expectLater(
        auth.loginWithCode('13812345678', '246810'),
        throwsA(isA<AppFailure>().having((f) => f.code, 'code', 20005)),
      );
      expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
    });

    test('响应里没有凭证时算失败', () async {
      env.adapter.on('POST /auth/phone/login', [
        FakeAdapter.ok({'isLogin': false}),
      ]);

      await expectLater(
        auth.loginWithCode('13812345678', '246810'),
        throwsA(isA<AppFailure>()),
      );
    });

    test('验证码不对就地提示', () async {
      env.adapter.on('POST /auth/phone/login', [FakeAdapter.fail(30005)]);

      await expectLater(
        auth.loginWithCode('13812345678', '000000'),
        throwsA(
          isA<AppFailure>().having((f) => f.message, 'message', '验证码错误，请重新输入'),
        ),
      );
    });
  });

  group('密码登录', () {
    test('用手机号、用户名或邮箱，带上政策版本', () async {
      env.adapter.on('POST /auth/login', [_token()]);

      final result = await auth.loginWithPassword(
        'chi_fan',
        'secret1',
        policyVersion: 'v3',
      );
      expect(result.newUser, isFalse);
      final sent = env.adapter.sent('POST /auth/login').single;
      expect(sent.body, {
        'userName': 'chi_fan',
        'password': 'secret1',
        'device': 'APP',
        'policyVersion': 'v3',
        'installId': testInstallId,
      });
      expect(sent.headers.containsKey('X-Captcha-Ticket'), isFalse);
    });

    test('有人机验证票据时放进请求头', () async {
      env.adapter.on('POST /auth/login', [_token()]);

      await auth.loginWithPassword(
        'chi_fan',
        'secret1',
        ticket: const CaptchaTicket(ticket: 't-1', randstr: 'r-1'),
      );
      final headers = env.adapter.sent('POST /auth/login').single.headers;
      expect(headers['X-Captcha-Ticket'], 't-1');
      expect(headers['X-Captcha-Randstr'], 'r-1');
    });
  });

  group('学生认证', () {
    test('统一认证用回跳地址里的票据确认', () async {
      env.adapter.on('POST /auth/sdu/confirm', [FakeAdapter.ok()]);

      await auth.confirmSso('ticket-1');
      expect(env.adapter.sent('POST /auth/sdu/confirm').single.body, {
        'ticket': 'ticket-1',
      });
    });

    test('认证邮件用 POST，邮箱在请求体里，票据在请求头里', () async {
      env.adapter.on('POST /auth/sendEmail', [FakeAdapter.ok()]);

      await auth.sendVerifyEmail(
        'a@mail.sdu.edu.cn',
        const CaptchaTicket(ticket: 't-1', randstr: 'r-1'),
      );
      final sent = env.adapter.sent('POST /auth/sendEmail').single;
      expect(sent.body, {'email': 'a@mail.sdu.edu.cn'});
      expect(sent.query, isEmpty);
      expect(sent.headers['X-Captcha-Ticket'], 't-1');
    });

    test('邮件链接的 token 放在请求体里提交', () async {
      env.adapter.on('POST /auth/verifyEmail', [FakeAdapter.ok()]);

      await auth.verifyEmail('token-1');
      expect(env.adapter.sent('POST /auth/verifyEmail').single.body, {
        'token': 'token-1',
      });
    });
  });

  test('查用户名用请求体', () async {
    env.adapter.on('POST /auth/checkUsername', [FakeAdapter.ok()]);

    await auth.checkUsername('chi_fan');
    final sent = env.adapter.sent('POST /auth/checkUsername').single;
    expect(sent.body, {'userName': 'chi_fan'});
    expect(sent.query, isEmpty);
  });

  test('发验证码带上人机验证票据的两个请求头', () async {
    env.adapter.on('POST /auth/phone/code', [FakeAdapter.ok()]);

    await auth.sendLoginCode(
      '13812345678',
      const CaptchaTicket(ticket: 't-1', randstr: 'r-1'),
    );
    final headers = env.adapter.sent('POST /auth/phone/code').single.headers;
    expect(headers['X-Captcha-Ticket'], 't-1');
    expect(headers['X-Captcha-Randstr'], 'r-1');
  });

  test('人机验证关掉时不需要参数', () async {
    env.adapter.on('GET /auth/captcha/config', [
      FakeAdapter.ok({
        'enabled': false,
        'provider': 'tencent-cloud-intl',
        'appId': null,
        'scriptUrl': null,
        'aidEncrypted': null,
        'aidEncryptedType': null,
        'expiresAt': null,
      }),
    ]);

    expect(await auth.captchaParams(), isNull);
  });

  test('退出登录时服务端失败也不抛', () async {
    env.adapter.on('POST /auth/logout', [const FakeResponse.offline()]);

    await auth.logout();
  });
}
