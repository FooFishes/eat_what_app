import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/state/cross_border_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const _token = AuthToken(name: 'satoken', value: 'tk');

Future<Object?> _result(Future<Object?> request) =>
    request.then<Object?>((value) => value, onError: (Object e) => e);

void main() {
  late TestEnv env;
  late ProviderContainer container;
  var shown = 0;
  var answer = true;

  setUp(() async {
    env = TestEnv();
    shown = 0;
    answer = true;
    env.adapter.on('GET /auth/consent/policy', [
      FakeAdapter.ok({
        'version': 'v3',
        'privacyText': '隐私政策正文',
        'crossBorderText': '数据跨境说明正文',
        'publishedAt': 1792763739329,
      }),
    ]);
    container = await env.container(
      session: const SignedIn(user: testUser),
      token: _token,
    );
    container.read(crossBorderConsentProvider).sessionPresenter = () async {
      shown++;
      return answer;
    };
  });

  test('已登录时政策更新：弹对话框，同意后用当前会话提交，再重发原请求', () async {
    env.adapter
      ..on('POST /auth/consent/grant', [
        FakeAdapter.ok({
          'agreedVersion': 'v3',
          'agreedAt': 1792763739329,
          'currentVersion': 'v3',
          'required': false,
        }),
      ])
      ..on('GET /a', [FakeAdapter.fail(20009), FakeAdapter.ok('A')]);

    expect(await container.read(apiClientProvider).get('/a'), 'A');
    expect(shown, 1);
    expect(env.adapter.sent('POST /auth/consent/grant').single.body, {
      'policyVersion': 'v3',
    });
  });

  test('用户不同意：不提交同意，只让这次请求失败，不退出登录', () async {
    answer = false;
    env.adapter.on('GET /a', [FakeAdapter.fail(20009), FakeAdapter.ok('A')]);

    final failure = await _result(container.read(apiClientProvider).get('/a'));
    expect(failure, isA<AppFailure>());
    expect((failure! as AppFailure).message, '同意隐私政策后才能继续');
    expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
    expect(env.adapter.sent('GET /a'), hasLength(1));
    expect(container.read(sessionProvider), isA<SignedIn>());
  });

  test('并发的请求只弹一次对话框，同意后各自重发', () async {
    env.adapter
      ..on('POST /auth/consent/grant', [FakeAdapter.ok()])
      ..on('GET /a', [FakeAdapter.fail(20009), FakeAdapter.ok('A')])
      ..on('GET /b', [FakeAdapter.fail(20009), FakeAdapter.ok('B')]);

    final client = container.read(apiClientProvider);
    expect(await Future.wait([client.get('/a'), client.get('/b')]), ['A', 'B']);
    expect(shown, 1);
    expect(env.adapter.sent('POST /auth/consent/grant'), hasLength(1));
  });

  test('没有注册对话框时按不同意处理', () async {
    container.read(crossBorderConsentProvider).sessionPresenter = null;
    env.adapter.on('GET /a', [FakeAdapter.fail(20009)]);

    final failure = await _result(container.read(apiClientProvider).get('/a'));
    expect((failure! as AppFailure).code, 20005);
    expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
  });

  group('读取版本', () {
    test('还没发布政策时版本为空，确认时不弹对话框', () async {
      env.adapter.on('GET /auth/consent/policy', [
        FakeAdapter.ok({
          'version': null,
          'privacyText': null,
          'crossBorderText': null,
          'publishedAt': null,
        }),
      ]);
      final consent = container.read(crossBorderConsentProvider);

      expect(await consent.currentVersion(), isNull);
      expect(
        await consent.confirm(() async => throw StateError('不该弹')),
        isNull,
      );
    });

    test('确认时用户同意返回当前版本，不提交同意', () async {
      final consent = container.read(crossBorderConsentProvider);

      expect(await consent.confirm(() async => true), 'v3');
      expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
    });
  });
}
