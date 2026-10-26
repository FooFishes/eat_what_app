import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

Map<String, Object?> _token({bool newUser = false}) => FakeAdapter.ok({
  'tokenName': 'satoken',
  'tokenValue': 'tk',
  'isLogin': true,
  'newUser': newUser,
});

final _policy = FakeAdapter.ok({'version': 'cb-v3', 'url': null});

void main() {
  late TestEnv env;
  late AuthRepository auth;

  setUp(() async {
    env = TestEnv();
    final container = await env.container();
    auth = container.read(authRepositoryProvider);
  });

  group('验证码登录', () {
    test('一律带上跨站同步同意和当前政策版本，新号码就此注册', () async {
      env.adapter
        ..on('GET /auth/consent/policy', [_policy])
        ..on('POST /auth/phone/login', [_token(newUser: true)]);

      final result = await auth.loginWithCode('13812345678', '246810');
      expect(result.token.name, 'satoken');
      expect(result.token.value, 'tk');
      expect(result.newUser, isTrue);
      final body = env.adapter.sent('POST /auth/phone/login').single.body;
      expect(body, {
        'mobile': '13812345678',
        'code': '246810',
        'device': 'APP',
        'crossBorderConsent': true,
        'consentPolicyVersion': 'cb-v3',
      });
    });

    test('读不到政策版本时照常登录，只是不带同意参数', () async {
      env.adapter.on('POST /auth/phone/login', [_token()]);

      await auth.loginWithCode('13812345678', '246810');
      final body =
          env.adapter.sent('POST /auth/phone/login').single.body as Map;
      expect(body.containsKey('crossBorderConsent'), isFalse);
      expect(body.containsKey('consentPolicyVersion'), isFalse);
    });

    test('只带回临时 proof 时先同意，再用同样的参数登录一次', () async {
      env.adapter
        ..on('GET /auth/consent/policy', [_policy])
        ..on('POST /auth/consent/grant', [FakeAdapter.ok()])
        ..on('POST /auth/phone/login', [
          FakeAdapter.ok({'consentProof': 'proof-1', 'status': 'NOT_GRANTED'}),
          _token(),
        ]);

      final result = await auth.loginWithCode('13812345678', '246810');
      expect(result.token.value, 'tk');
      expect(env.adapter.sent('POST /auth/consent/grant').single.body, {
        'policyVersion': 'cb-v3',
        'proof': 'proof-1',
      });
      final logins = env.adapter.sent('POST /auth/phone/login').toList();
      expect(logins, hasLength(2));
      expect(logins[0].body, logins[1].body);
    });

    test('同意之后还是没有 token，不算登录成功', () async {
      env.adapter
        ..on('GET /auth/consent/policy', [_policy])
        ..on('POST /auth/consent/grant', [FakeAdapter.ok()])
        ..on('POST /auth/phone/login', [
          FakeAdapter.ok({'consentProof': 'proof-1'}),
        ]);

      expect(
        () => auth.loginWithCode('13812345678', '246810'),
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

  test('密码登录用手机号或用户名', () async {
    env.adapter.on('POST /auth/login', [_token()]);

    final result = await auth.loginWithPassword('chi_fan', 'secret1');
    expect(result.newUser, isFalse);
    expect(env.adapter.sent('POST /auth/login').single.body, {
      'username': 'chi_fan',
      'password': 'secret1',
      'device': 'APP',
    });
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
