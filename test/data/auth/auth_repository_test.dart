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
    test('默认不带数据跨境同意，不替用户同意', () async {
      env.adapter.on('POST /auth/phone/login', [_token(newUser: true)]);

      final result = await auth.loginWithCode('13812345678', '246810');
      expect(result.token.name, 'satoken');
      expect(result.token.value, 'tk');
      expect(result.newUser, isTrue);
      expect(env.adapter.sent('POST /auth/phone/login').single.body, {
        'mobile': '13812345678',
        'code': '246810',
        'device': 'APP',
      });
      expect(env.adapter.sent('GET /auth/consent/policy'), isEmpty);
    });

    test('用户同意后才带上同意和当前政策版本，新号码据此注册', () async {
      env.adapter
        ..on('GET /auth/consent/policy', [_policy])
        ..on('POST /auth/phone/login', [_token(newUser: true)]);

      await auth.loginWithCode(
        '13812345678',
        '246810',
        crossBorderConsent: true,
      );
      expect(env.adapter.sent('POST /auth/phone/login').single.body, {
        'mobile': '13812345678',
        'code': '246810',
        'device': 'APP',
        'crossBorderConsent': true,
        'consentPolicyVersion': 'cb-v3',
      });
    });

    test('读不到政策版本时照常登录，只是不带同意参数', () async {
      env.adapter.on('POST /auth/phone/login', [_token()]);

      await auth.loginWithCode(
        '13812345678',
        '246810',
        crossBorderConsent: true,
      );
      final body =
          env.adapter.sent('POST /auth/phone/login').single.body as Map;
      expect(body.containsKey('crossBorderConsent'), isFalse);
      expect(body.containsKey('consentPolicyVersion'), isFalse);
    });

    test('要求同意时不自动同意，把临时凭证交给页面', () async {
      env.adapter.on('POST /auth/phone/login', [
        {
          'code': 20005,
          'msg': '需要跨境同步同意',
          'data': {'consentProof': 'proof-1', 'status': 'NOT_GRANTED'},
        },
      ]);

      final failure = await auth
          .loginWithCode('13812345678', '246810')
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(failure, isA<AppFailure>());
      expect(consentProofOf(failure! as AppFailure), 'proof-1');
      expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
      expect(env.adapter.sent('POST /auth/phone/login'), hasLength(1));
    });

    test('成功外壳里只有临时凭证时按要求同意处理', () async {
      env.adapter.on('POST /auth/login', [
        FakeAdapter.ok({'consentProof': 'proof-1'}),
      ]);

      await expectLater(
        auth.loginWithPassword('chi_fan', 'secret1'),
        throwsA(isA<AppFailure>().having(consentProofOf, 'proof', 'proof-1')),
      );
      expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
    });

    test('新号码要求同意但没有凭证时，凭证为空', () async {
      env.adapter.on('POST /auth/phone/login', [FakeAdapter.fail(20005)]);

      await expectLater(
        auth.loginWithCode('13812345678', '246810'),
        throwsA(
          isA<AppFailure>()
              .having((f) => f.code, 'code', 20005)
              .having(consentProofOf, 'proof', isNull),
        ),
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

  test('密码登录用手机号、用户名或邮箱', () async {
    env.adapter.on('POST /auth/login', [_token()]);

    final result = await auth.loginWithPassword('chi_fan', 'secret1');
    expect(result.newUser, isFalse);
    expect(env.adapter.sent('POST /auth/login').single.body, {
      'userName': 'chi_fan',
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
