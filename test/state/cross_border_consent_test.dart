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
  final shown = <ConsentPolicy>[];
  var answer = true;

  setUp(() async {
    env = TestEnv();
    shown.clear();
    answer = true;
    env.adapter.on('GET /auth/consent/policy', [
      FakeAdapter.ok({'version': 'cb-v3', 'url': '/api/policies/cb-v3.html'}),
    ]);
    container = await env.container(
      session: const SignedIn(user: testUser),
      token: _token,
    );
    container
        .read(crossBorderConsentProvider)
        .sessionPresenter = (policy) async {
      shown.add(policy);
      return answer;
    };
  });

  test('已登录时要求同意：弹面板，同意后用当前会话提交，再重发原请求', () async {
    env.adapter
      ..on('POST /auth/consent/grant', [FakeAdapter.ok()])
      ..on('GET /a', [FakeAdapter.fail(20005), FakeAdapter.ok('A')]);

    expect(await container.read(apiClientProvider).get('/a'), 'A');
    expect(shown.single.version, 'cb-v3');
    expect(
      shown.single.url,
      Uri.parse('https://api.test/api/policies/cb-v3.html'),
      reason: '站内路径按接口地址补全',
    );
    expect(env.adapter.sent('POST /auth/consent/grant').single.body, {
      'policyVersion': 'cb-v3',
    });
  });

  test('用户不同意：不提交同意，原请求失败', () async {
    answer = false;
    env.adapter.on('GET /a', [FakeAdapter.fail(20009), FakeAdapter.ok('A')]);

    final failure = await _result(container.read(apiClientProvider).get('/a'));
    expect(failure, isA<AppFailure>());
    expect((failure! as AppFailure).message, '需要同意数据跨境后才能继续');
    expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
    expect(env.adapter.sent('GET /a'), hasLength(1));
    expect(container.read(sessionProvider), isA<SignedIn>());
  });

  for (final code in [20007, 20008]) {
    test('提交同意返回 $code：清除登录态，回登录页重新登录', () async {
      env.adapter
        ..on('POST /auth/consent/grant', [FakeAdapter.fail(code)])
        ..on('GET /a', [FakeAdapter.fail(20005)]);

      final failure = await _result(
        container.read(apiClientProvider).get('/a'),
      );
      expect((failure! as AppFailure).kind, FailureKind.sessionExpired);
      expect(container.read(sessionProvider), isA<SignedOut>());
      expect(env.adapter.sent('GET /a'), hasLength(1));
      // 本地数据的清除在后台异步执行. 释放容器前等待清除完成.
      await pumpEventQueue();
    });
  }

  test('没有注册面板时按不同意处理', () async {
    container.read(crossBorderConsentProvider).sessionPresenter = null;
    env.adapter.on('GET /a', [FakeAdapter.fail(20005)]);

    final failure = await _result(container.read(apiClientProvider).get('/a'));
    expect((failure! as AppFailure).code, 20005);
    expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
  });
}
