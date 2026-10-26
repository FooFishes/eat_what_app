import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
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
      adapter.on('GET /user/getCode', [
        const FakeResponse(status: 403, body: {'code': 'STATE_NOT_ALLOWED'}),
      ]);

      final failure = await _failure(client.get('/user/getCode'));
      expect(failure.kind, FailureKind.forbidden);
      expect(failure.code, 'STATE_NOT_ALLOWED');
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
      adapter.on('GET /a', [FakeAdapter.fail(20003)]);
      adapter.on('GET /b', [FakeAdapter.fail(20002)]);

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

    expect((await _failure(client.get('/a'))).kind, FailureKind.forbidden);
    expect(forbidden, 1);
  });

  group('跨站同步同意', () {
    test('要求同意时自动同意一次，再把原请求重发', () async {
      var grants = 0;
      final (client, adapter, _) = await _client(
        hooks: ApiHooks(
          grantConsent: () async {
            grants++;
            return true;
          },
        ),
      );
      adapter.on('GET /a', [FakeAdapter.fail(20005), FakeAdapter.ok('A')]);
      adapter.on('GET /b', [FakeAdapter.fail(20006), FakeAdapter.ok('B')]);

      final results = await Future.wait([client.get('/a'), client.get('/b')]);
      expect(results, ['A', 'B']);
      expect(grants, 1, reason: '同时要求同意时只同意一次');
      expect(adapter.sent('GET /a'), hasLength(2));
    });

    test('同意失败或重发后还要求同意，按「未知」处理', () async {
      final (client, adapter, _) = await _client(
        hooks: ApiHooks(grantConsent: () async => true),
      );
      adapter.on('GET /a', [FakeAdapter.fail(20005)]);

      final failure = await _failure(client.get('/a'));
      expect(failure.kind, FailureKind.unknown);
      expect(adapter.sent('GET /a'), hasLength(2), reason: '只重发一次，不一直绕圈');

      final (failing, adapter2, _) = await _client(
        hooks: ApiHooks(grantConsent: () async => throw Exception('down')),
      );
      adapter2.on('GET /a', [FakeAdapter.fail(20006)]);
      expect((await _failure(failing.get('/a'))).kind, FailureKind.unknown);
      expect(adapter2.sent('GET /a'), hasLength(1));
    });
  });

  test('只对网络错误自动重试，最多 2 次', () {
    const network = AppFailure.network();
    expect(retryOnNetworkFailure(0, network), isNotNull);
    expect(retryOnNetworkFailure(1, network), isNotNull);
    expect(retryOnNetworkFailure(2, network), isNull);
    expect(retryOnNetworkFailure(0, AppFailure.fromCode(30005)), isNull);
    expect(retryOnNetworkFailure(0, AppFailure.fromCode(20003)), isNull);
    expect(retryOnNetworkFailure(0, StateError('x')), isNull);
  });
}
