import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/state/captcha_gate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

Map<String, Object?> _config() => FakeAdapter.ok({
  'enabled': true,
  'provider': 'tencent-cloud-intl',
  'appId': '123456789',
  'scriptUrl': 'https://ca.turing.captcha.qcloud.com/TJNCaptcha-global.js',
  'aidEncrypted': 'MDEyMzQ1Njc4OTAxMjM0NQ==',
  'aidEncryptedType': 'cbc',
  'expiresAt': 1710231372,
});

void main() {
  late TestEnv env;
  late CaptchaGate gate;
  final presented = <CaptchaParams>[];

  Future<CaptchaOutcome> present(CaptchaParams params) {
    presented.add(params);
    return env.verifier.verify(_NoContext(), params);
  }

  setUp(() async {
    env = TestEnv();
    presented.clear();
    gate = (await env.container()).read(captchaGateProvider);
  });

  test('每次都重新拿参数，通过后把票据带给发送', () async {
    env.adapter.on('GET /auth/captcha/config', [_config()]);
    final tickets = <CaptchaTicket?>[];

    expect(await gate.run(present, (t) async => tickets.add(t)), isTrue);
    expect(await gate.run(present, (t) async => tickets.add(t)), isTrue);
    expect(env.adapter.sent('GET /auth/captcha/config'), hasLength(2));
    expect(presented.first.appId, '123456789');
    expect(tickets.map((t) => t?.ticket), ['t-1', 't-1']);
  });

  test('服务端关掉了人机验证时直接发', () async {
    env.adapter.on('GET /auth/captcha/config', [
      FakeAdapter.ok({'enabled': false, 'provider': 'tencent-cloud-intl'}),
    ]);
    CaptchaTicket? sent = const CaptchaTicket(ticket: 'x', randstr: 'x');

    expect(await gate.run(present, (t) async => sent = t), isTrue);
    expect(sent, isNull);
    expect(presented, isEmpty);
  });

  test('用户关掉验证就什么都不发', () async {
    env.adapter.on('GET /auth/captcha/config', [_config()]);
    env.verifier.outcome = const CaptchaCancelled();
    var sends = 0;

    expect(await gate.run(present, (_) async => sends++), isFalse);
    expect(sends, 0);
  });

  test('腾讯的脚本没加载出来时提示重试，不发', () async {
    env.adapter.on('GET /auth/captcha/config', [_config()]);
    env.verifier.outcome = const CaptchaFailed();

    await expectLater(
      gate.run(present, (_) async {}),
      throwsA(
        isA<AppFailure>().having((f) => f.message, 'message', '人机验证未通过，请重试'),
      ),
    );
  });

  test('票据缺失或无效时整套重来，最多三次', () async {
    env.adapter.on('GET /auth/captcha/config', [_config()]);
    var sends = 0;

    await expectLater(
      gate.run(present, (_) async {
        sends++;
        throw AppFailure.fromCode(30016);
      }),
      throwsA(isA<AppFailure>()),
    );
    expect(sends, 3);
    expect(env.adapter.sent('GET /auth/captcha/config'), hasLength(3));

    sends = 0;
    expect(
      await gate.run(present, (_) async {
        if (++sends == 1) throw AppFailure.fromCode(30015);
      }),
      isTrue,
    );
    expect(sends, 2);
  });

  test('人机验证服务不可用时不重来', () async {
    env.adapter.on('GET /auth/captcha/config', [FakeAdapter.fail(50004)]);

    await expectLater(
      gate.run(present, (_) async {}),
      throwsA(
        isA<AppFailure>().having((f) => f.message, 'message', '人机验证暂不可用，请稍后再试'),
      ),
    );
    expect(env.adapter.sent('GET /auth/captcha/config'), hasLength(1));
  });

  test('腾讯的回调转成结果：容灾票据不算通过', () {
    expect(
      captchaOutcomeOf(ret: 0, ticket: 'tk', randstr: 'rs'),
      isA<CaptchaPassed>(),
    );
    expect(
      captchaOutcomeOf(ret: 2, ticket: null, randstr: null),
      isA<CaptchaCancelled>(),
    );
    expect(
      captchaOutcomeOf(ret: 0, ticket: 'trerror_1001', randstr: 'rs'),
      isA<CaptchaFailed>(),
    );
    expect(
      captchaOutcomeOf(ret: 0, ticket: 'tk', randstr: ''),
      isA<CaptchaFailed>(),
    );
    expect(
      captchaOutcomeOf(ret: -1, ticket: null, randstr: null),
      isA<CaptchaFailed>(),
    );
  });
}

/// [FakeHumanVerifier] 不用 `BuildContext`，随便给一个。
class _NoContext extends Fake implements BuildContext {}
