import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

const _token = AuthToken(name: 'satoken', value: 'abc');

Future<(ApiClient, FakeAdapter, TokenStore)> _client({
  AuthToken? token = _token,
  ApiHooks hooks = const ApiHooks(),
}) async {
  final adapter = FakeAdapter();
  final tokens = TokenStore(MemorySecureStore());
  if (token != null) await tokens.save(token);
  final client = ApiClient(
    baseUrl: 'https://api.test/api',
    tokens: tokens,
    hooks: hooks,
    adapter: adapter,
  );
  return (client, adapter, tokens);
}

Future<AppFailure> _failure(Future<Object?> request) async {
  try {
    await request;
  } on AppFailure catch (e) {
    return e;
  }
  fail('应该失败');
}

void main() {
  test('成功时只返回外壳里的 data，请求头用登录返回的头名', () async {
    final (client, adapter, _) = await _client(
      token: const AuthToken(name: 'x-token', value: 'v1'),
    );
    adapter.on('GET /user/info', [
      FakeAdapter.ok({'id': 1}),
    ]);

    expect(await client.get('/user/info'), {'id': 1});
    expect(adapter.requests.single.headers['x-token'], 'Bearer v1');
  });

  test('没登录时不加鉴权头', () async {
    final (client, adapter, _) = await _client(token: null);
    adapter.on('GET /auth/consent/policy', [FakeAdapter.ok()]);

    await client.get('/auth/consent/policy');
    expect(adapter.requests.single.headers.containsKey('satoken'), isFalse);
  });

  group('失败都转成 AppFailure', () {
    test('HTTP 200 带非零 code 也是失败，按码表归类', () async {
      final (client, adapter, _) = await _client();
      adapter.on('POST /auth/phone/login', [FakeAdapter.fail(30005, '验证码不对')]);

      final failure = await _failure(client.post('/auth/phone/login'));
      expect(failure.kind, FailureKind.business);
      expect(failure.message, '验证码错误，请重新输入');
      expect(failure.message, isNot(contains('30005')));
    });

    test('码表里没有的码是「未知」，不把服务端的 msg 给用户看', () async {
      final (client, adapter, _) = await _client();
      adapter.on('GET /x', [FakeAdapter.fail(41234, 'NullPointerException')]);

      final failure = await _failure(client.get('/x'));
      expect(failure.kind, FailureKind.unknown);
      expect(failure.message, '操作失败，请重试');
    });

    test('9xxxx 和 HTTP 5xx 是服务器出错', () async {
      final (client, adapter, _) = await _client();
      adapter.on('GET /a', [FakeAdapter.fail(90001)]);
      adapter.on('GET /b', [const FakeResponse(status: 502, body: 'bad')]);

      expect((await _failure(client.get('/a'))).kind, FailureKind.server);
      expect((await _failure(client.get('/b'))).kind, FailureKind.server);
    });

    test('非 200 的 ErrorResponse 保留字符串码', () async {
      final (client, adapter, _) = await _client();
      adapter.on('GET /x', [
        const FakeResponse(
          status: 503,
          body: {'code': 'SITE_ENROLLMENT_REQUIRED'},
        ),
      ]);

      final failure = await _failure(client.get('/x'));
      expect(failure.kind, FailureKind.unknown);
      expect(failure.code, 'SITE_ENROLLMENT_REQUIRED');
    });

    test('40002 不当作无权限，不刷新账号状态', () async {
      var forbidden = 0;
      final (client, adapter, _) = await _client(
        hooks: ApiHooks(onForbidden: () => forbidden++),
      );
      adapter.on('POST /auth/username/set', [FakeAdapter.fail(40002)]);

      final failure = await _failure(client.post('/auth/username/set'));
      expect(failure.kind, FailureKind.business);
      expect(failure.code, 40002);
      expect(forbidden, 0);
    });

    test('连不上是「没网」，提示网络连接失败', () async {
      final (client, adapter, _) = await _client();
      adapter.on('GET /x', [const FakeResponse.offline()]);

      final failure = await _failure(client.get('/x'));
      expect(failure.kind, FailureKind.network);
      expect(failure.message, '网络连接失败，请重试');
    });

    test('频率过高单独一类', () async {
      final (client, adapter, _) = await _client();
      adapter.on('POST /auth/phone/code', [FakeAdapter.fail(10003)]);

      final failure = await _failure(client.post('/auth/phone/code'));
      expect(failure.kind, FailureKind.tooFrequent);
      expect(failure.message, '操作过于频繁，请稍后再试');
    });

    test('频率过高时带出服务端给的等待秒数', () async {
      final (client, adapter, _) = await _client();
      adapter.on('POST /auth/login', [
        {
          'code': 10003,
          'msg': '请求频率过高',
          'data': {'retryAfterSeconds': 900},
        },
      ]);

      final failure = await _failure(client.post('/auth/login'));
      expect(failure.retryAfter, const Duration(minutes: 15));
      expect(failure.message, '操作过于频繁，请 15 分钟后再试');
    });

    test('取消的请求不提示', () async {
      final (client, adapter, _) = await _client();
      adapter.on('GET /x', [FakeAdapter.ok()]);
      final cancel = CancelToken()..cancel();

      final failure = await _failure(client.get('/x', cancelToken: cancel));
      expect(failure.kind, FailureKind.cancelled);
    });

    test('外壳形状不对是「未知」', () async {
      final (client, adapter, _) = await _client();
      adapter.on('GET /x', [
        const FakeResponse(body: ['not', 'a', 'map']),
      ]);

      expect((await _failure(client.get('/x'))).kind, FailureKind.unknown);
    });
  });

  group('登录过期', () {
    test('几个请求同时过期只通知一次', () async {
      var expired = 0;
      late TokenStore tokens;
      final (client, adapter, store) = await _client(
        hooks: ApiHooks(
          onSessionExpired: () {
            expired++;
            tokens.clear();
          },
        ),
      );
      tokens = store;
      adapter.on('GET /a', [FakeAdapter.fail(20001)]);
      adapter.on('GET /b', [FakeAdapter.fail(20001)]);

      final failures = await Future.wait([
        _failure(client.get('/a')),
        _failure(client.get('/b')),
      ]);
      expect(
        failures.map((f) => f.kind),
        everyElement(FailureKind.sessionExpired),
      );
      expect(expired, 1);
    });

    test('受限会话被拒绝时按无权限处理，通知刷新账号状态，不清除登录态', () async {
      var expired = 0;
      var forbidden = 0;
      final hooks = ApiHooks(
        onSessionExpired: () => expired++,
        onForbidden: () => forbidden++,
      );
      final (client, adapter, _) = await _client(hooks: hooks);
      adapter.on('POST /foods/like', [
        FakeAdapter.fail(30002, '账号封禁中', {'reason': '刷赞', 'banUntil': null}),
      ]);

      final failure = await _failure(client.post('/foods/like'));
      expect(failure.kind, FailureKind.forbidden);
      expect(failure.code, BizCodes.userDisabled);
      expect((expired, forbidden), (0, 1));
    });

    test('带凭证的请求收到不带原因的 30002 或 30017 时按会话失效处理；登录请求不带凭证时按码表提示', () async {
      var expired = 0;
      final hooks = ApiHooks(onSessionExpired: () => expired++);
      for (final code in [30002, 30017]) {
        final (client, adapter, _) = await _client(hooks: hooks);
        adapter.on('GET /user/info', [FakeAdapter.fail(code)]);
        final failure = await _failure(client.get('/user/info'));
        expect(failure.kind, FailureKind.sessionExpired, reason: '$code');
        expect(failure.code, code);
      }
      expect(expired, 2);

      final (login, loginAdapter, _) = await _client(token: null, hooks: hooks);
      loginAdapter.on('POST /auth/login', [FakeAdapter.fail(30002)]);
      final rejected = await _failure(login.post('/auth/login'));
      expect(rejected.kind, FailureKind.business);
      expect(rejected.message, '账号已被封禁');
      expect(expired, 2);
    });

    test('没登录时遇到 2000x 不当作过期', () async {
      var expired = 0;
      final (client, adapter, _) = await _client(
        token: null,
        hooks: ApiHooks(onSessionExpired: () => expired++),
      );
      adapter.on('GET /a', [FakeAdapter.fail(20001)]);

      await _failure(client.get('/a'));
      expect(expired, 0);
    });
  });

  test('没权限时让上层刷新账号状态', () async {
    var forbidden = 0;
    final (client, adapter, _) = await _client(
      hooks: ApiHooks(onForbidden: () => forbidden++),
    );
    adapter.on('GET /a', [FakeAdapter.fail(20004)]);

    final failure = await _failure(client.get('/a'));
    expect(failure.kind, FailureKind.forbidden);
    expect(failure.message, '当前账号暂无此权限');
    expect(forbidden, 1);
  });

  group('隐私政策同意', () {
    test('要求同意时请用户确认，同意后把原请求重发一次', () async {
      var asks = 0;
      final (client, adapter, _) = await _client(
        hooks: ApiHooks(requestConsent: () async => asks++),
      );
      adapter.on('POST /a', [FakeAdapter.fail(20005), FakeAdapter.ok('A')]);
      adapter.on('GET /b', [FakeAdapter.fail(20009), FakeAdapter.ok('B')]);

      expect(await client.post('/a'), 'A');
      expect(await client.get('/b'), 'B');
      expect(asks, 2);
      expect(adapter.sent('POST /a'), hasLength(2));
      expect(adapter.sent('GET /b'), hasLength(2));
    });

    test('几个请求同时要求同意时只问一次', () async {
      var asks = 0;
      final answer = Completer<void>();
      final (client, adapter, _) = await _client(
        hooks: ApiHooks(
          requestConsent: () {
            asks++;
            return answer.future;
          },
        ),
      );
      adapter.on('GET /a', [FakeAdapter.fail(20005), FakeAdapter.ok('A')]);
      adapter.on('GET /b', [FakeAdapter.fail(20005), FakeAdapter.ok('B')]);

      final results = Future.wait([client.get('/a'), client.get('/b')]);
      await pumpEventQueue();
      answer.complete();
      expect(await results, ['A', 'B']);
      expect(asks, 1);
    });

    test('用户不同意时原请求失败，不重发', () async {
      final (client, adapter, _) = await _client(
        hooks: ApiHooks(
          requestConsent: () async =>
              throw AppFailure.fromCode(BizCodes.consentRequired),
        ),
      );
      adapter.on('POST /a', [FakeAdapter.fail(20005), FakeAdapter.ok()]);

      final failure = await _failure(client.post('/a'));
      expect(failure.kind, FailureKind.business);
      expect(failure.message, '同意隐私政策后才能继续');
      expect(adapter.sent('POST /a'), hasLength(1));
    });

    test('同意出错或重发后还要求同意时失败，只重发一次', () async {
      final (client, adapter, _) = await _client(
        hooks: ApiHooks(requestConsent: () async {}),
      );
      adapter.on('GET /a', [FakeAdapter.fail(20005)]);

      final failure = await _failure(client.get('/a'));
      expect(failure.code, BizCodes.consentRequired);
      expect(adapter.sent('GET /a'), hasLength(2), reason: '只重发一次，不一直绕圈');

      final (failing, adapter2, _) = await _client(
        hooks: ApiHooks(requestConsent: () async => throw Exception('down')),
      );
      adapter2.on('GET /a', [FakeAdapter.fail(20005)]);
      expect((await _failure(failing.get('/a'))).kind, FailureKind.unknown);
      expect(adapter2.sent('GET /a'), hasLength(1));
    });

    test('没登录时不问，交给登录流程处理', () async {
      var asks = 0;
      final (client, adapter, _) = await _client(
        token: null,
        hooks: ApiHooks(requestConsent: () async => asks++),
      );
      adapter.on('POST /auth/login', [FakeAdapter.fail(20005)]);

      expect(
        (await _failure(client.post('/auth/login'))).code,
        BizCodes.consentRequired,
      );
      expect(asks, 0);
    });
  });

  test('只对网络错误自动重试，最多 2 次', () {
    const network = AppFailure.network();
    expect(retryOnNetworkFailure(0, network), isNotNull);
    expect(retryOnNetworkFailure(1, network), isNotNull);
    expect(retryOnNetworkFailure(2, network), isNull);
    expect(retryOnNetworkFailure(0, AppFailure.fromCode(30005)), isNull);
    expect(retryOnNetworkFailure(0, AppFailure.fromCode(20001)), isNull);
    expect(retryOnNetworkFailure(0, StateError('x')), isNull);
  });

  group('User-Agent', () {
    test('App 端的请求带上能识别平台的 User-Agent', () async {
      final adapter = FakeAdapter()..on('GET /a', [FakeAdapter.ok()]);
      final client = ApiClient(
        baseUrl: 'https://api.test/api',
        tokens: TokenStore(MemorySecureStore()),
        userAgent: Future.value('EatWhat/0.1.0 (Android)'),
        adapter: adapter,
      );

      await client.get('/a');
      expect(
        adapter.sent('GET /a').single.headers['User-Agent'],
        'EatWhat/0.1.0 (Android)',
      );
    });

    test('后端能从中认出 iOS 和安卓，读不到版本时省略版本', () {
      expect(
        appUserAgent(TargetPlatform.android, '0.1.0'),
        'EatWhat/0.1.0 (Android)',
      );
      expect(appUserAgent(TargetPlatform.iOS, '0.1.0'), 'EatWhat/0.1.0 (iOS)');
      expect(appUserAgent(TargetPlatform.iOS, null), 'EatWhat (iOS)');
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        final ua = appUserAgent(platform, '1.0.0').toLowerCase();
        expect(ua.contains('android') || ua.contains('ios'), isTrue);
      }
    });
  });
}
