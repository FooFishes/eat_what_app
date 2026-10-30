import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/core/storage/secure_store.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/state/api_hooks.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// 内存里的 [KvStore]。
class MemoryKvStore implements KvStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deletePrefix(String prefix) async =>
      values.removeWhere((key, _) => key.startsWith(prefix));
}

/// 内存里的 [SecureStore]。
class MemorySecureStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// 一次请求：方法、路径、查询参数、请求头和 JSON 请求体，测试里用来断言发了什么。
class const SentRequest(
  final String method,
  final String path,
  final Map<String, dynamic> query,
  final Map<String, dynamic> headers,
  final Object? body,
) {
  String get route => '$method $path';
}

/// 假的网络适配器：按「方法 路径」返回登记好的响应，不起真服务器（技术架构 21.1）。
///
/// 每个路由登记一串响应，依次用掉，用完后一直返回最后一个；没登记的路由返回 HTTP 404。
/// 响应是一个 Map 时当作 HTTP 200 的 JSON；是 [FakeResponse] 时可以指定状态码，或者模拟连不上。
class FakeAdapter implements HttpClientAdapter {
  final _routes = <String, List<Object>>{};
  final requests = <SentRequest>[];

  /// 登记 [route]（如 `POST /auth/phone/login`）的响应。
  void on(String route, List<Object> responses) =>
      _routes[route] = [...responses];

  /// 业务成功的外壳。
  static Map<String, Object?> ok([Object? data]) => {
    'code': 0,
    'msg': 'ok',
    'data': data,
    'timestamp': 0,
  };

  /// 业务失败的外壳（HTTP 200 带非零 `code`）。
  static Map<String, Object?> fail(Object code, [String msg = 'error']) => {
    'code': code,
    'msg': msg,
    'data': null,
    'timestamp': 0,
  };

  Iterable<SentRequest> sent(String route) =>
      requests.where((r) => r.route == route);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final route = '${options.method} ${options.path}';
    requests.add(
      SentRequest(
        options.method,
        options.path,
        options.queryParameters,
        options.headers,
        options.data,
      ),
    );
    final queue = _routes[route];
    if (queue == null || queue.isEmpty) {
      return ResponseBody.fromString('{}', 404, headers: _json);
    }
    final next = queue.length > 1 ? queue.removeAt(0) : queue.first;
    if (next case FakeResponse(:final status, :final body, :final offline)) {
      if (offline) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      }
      return ResponseBody.fromString(jsonEncode(body), status, headers: _json);
    }
    return ResponseBody.fromString(jsonEncode(next), 200, headers: _json);
  }

  @override
  void close({bool force = false}) {}

  static const _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };
}

/// 指定了状态码或者连不上的响应。
class const FakeResponse({
  final int status = 200,
  final Object? body,
  final bool offline = false,
}) {
  const FakeResponse.offline() : this(offline: true);
}

/// 测试用的环境配置。
const testConfig = AppConfig(
  envName: 'test',
  apiBaseUrl: 'https://api.test/api',
  webBaseUrl: 'https://eat.test',
  assetBaseUrl: 'https://img.test',
  sentryDsn: '',
  tiandituKey: '',
  privacyUrl: 'https://eat.test/privacy.html',
  termsUrl: 'https://eat.test/terms.html',
);

/// `/user/info` 的一份样例。
Map<String, Object?> userInfoJson({
  bool verified = false,
  String? method,
  bool banned = false,
  bool hasPassword = false,
}) => {
  'id': 42,
  'displayName': '天凉被破王',
  'userName': null,
  'hasUsername': false,
  'avatar': null,
  'role': 'user',
  'banned': banned,
  'banReason': banned ? '多次发布不是实拍的照片' : null,
  'bannedAt': banned ? 1792763739329 : null,
  'phone': '13812345678',
  'verified': verified,
  'method': method,
  'hasPassword': hasPassword,
};

const testUser = CurrentUser(
  id: 42,
  nickname: '天凉被破王',
  phone: '13812345678',
  hasPassword: false,
  verified: false,
  banned: false,
);

/// 人机验证：直接给出事先定好的结果，不弹任何东西。
class FakeHumanVerifier implements HumanVerifier {
  FakeHumanVerifier([this.outcome = const CaptchaPassed(_ticket)]);

  static const _ticket = CaptchaTicket(ticket: 't-1', randstr: 'r-1');

  CaptchaOutcome outcome;
  var calls = 0;

  @override
  Future<CaptchaOutcome> verify(
    BuildContext context,
    CaptchaParams params,
  ) async {
    calls++;
    return outcome;
  }
}

/// 一开始就是 [initial] 的登录态，跳过从本地存储恢复。
class FakeSession extends Session {
  FakeSession(this.initial);

  final SessionState initial;

  @override
  SessionState build() => initial;
}

/// 测试用的一套假环境：网络、存储都在内存里，网络层的回调接到登录态上。
class TestEnv {
  final adapter = FakeAdapter();
  final kv = MemoryKvStore();
  final secure = MemorySecureStore();
  final verifier = FakeHumanVerifier();

  /// [session] 给定时登录态从它开始；要测登录过期，同时传 [token]，网络层会带上它。
  Future<ProviderContainer> container({
    SessionState? session,
    AuthToken? token,
    List<Override> overrides = const [],
  }) async {
    final tokens = TokenStore(secure);
    if (token != null) await tokens.save(token);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        ...stateOverrides,
        appConfigProvider.overrideWithValue(testConfig),
        kvStoreProvider.overrideWithValue(kv),
        secureStoreProvider.overrideWithValue(secure),
        tokenStoreProvider.overrideWithValue(tokens),
        humanVerifierProvider.overrideWithValue(verifier),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            baseUrl: testConfig.apiBaseUrl,
            tokens: tokens,
            hooks: ref.watch(apiHooksProvider),
            adapter: adapter,
          ),
        ),
        if (session != null)
          sessionProvider.overrideWith(() => FakeSession(session)),
        ...overrides,
      ],
    );
    return container;
  }
}
