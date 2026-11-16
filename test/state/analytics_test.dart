import 'dart:convert';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/state/analytics.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const _events = 'POST /telemetry/events';
const _token = AuthToken(name: 'satoken', value: 'tk');

Map<String, Object?> _accepted({bool enabled = true}) =>
    FakeAdapter.ok({'accepted': 1, 'duplicates': 0, 'enabled': enabled});

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv()..adapter.on(_events, [_accepted()]);
  });

  Future<(ProviderContainer, Analytics)> started({
    SessionState? session,
    AuthToken? token,
  }) async {
    final container = await env.container(session: session, token: token);
    final analytics = container.read(analyticsProvider);
    await analytics.start();
    await pumpEventQueue();
    return (container, analytics);
  }

  /// 记录 [count] 个可区分的事件, 第 i 个事件的 `code` 为 [from] + i.
  void trackMany(Analytics analytics, int count, {int from = 0}) {
    for (var i = 0; i < count; i++) {
      analytics.track(LoadFailedEvent(AnalyticsPage.home, code: from + i));
    }
  }

  List<Map<String, Object?>> sentEvents(int index) {
    final body = env.adapter.sent(_events).elementAt(index).body! as Map;
    return [for (final e in body['events'] as List) e as Map<String, Object?>];
  }

  List<Object?> queuedCodes() => [
    for (final e in jsonDecode(env.kv.values[Analytics.queueKey]!) as List)
      ((e as Map)['properties'] as Map)['code'],
  ];

  test('同意隐私政策之前不采集', () async {
    final container = await env.container();
    final analytics = container.read(analyticsProvider);

    trackMany(analytics, Analytics.batchSize);
    await analytics.flush();

    expect(analytics.active, isFalse);
    expect(env.adapter.sent(_events), isEmpty);
  });

  test('同意记录存在时随其他服务一起开始采集', () async {
    env.kv.values[PrivacyConsentStore.key] = '{"version":"2026-10"}';
    final container = await env.container();

    await container.read(consentedServicesProvider.notifier).start();

    expect(container.read(analyticsProvider).active, isTrue);
  });

  test('满 20 条上报一次，批次带安装 ID，游客也上报', () async {
    final (_, analytics) = await started(session: const Guest());

    trackMany(analytics, Analytics.batchSize - 1);
    await pumpEventQueue();
    expect(env.adapter.sent(_events), isEmpty);

    trackMany(analytics, 1, from: 19);
    await pumpEventQueue();

    final body = env.adapter.sent(_events).single.body! as Map;
    expect(body['installId'], testInstallId);
    final events = sentEvents(0);
    expect(events, hasLength(Analytics.batchSize));
    expect(events.first['eventId'], matches(_uuid));
    expect(events.map((e) => e['eventId']).toSet(), hasLength(20));
    expect(events.first['properties'], {
      'event': 'load_failed',
      'page': 'HOME',
      'code': 0,
    });
    expect(env.kv.values[Analytics.queueKey], isNull);
  });

  testWidgets('最早的事件等满 30 秒后上报', (tester) async {
    final container = await env.container();
    final analytics = container.read(analyticsProvider);
    await analytics.start();

    analytics.track(const AppOpenEvent());
    await tester.pump(const Duration(seconds: 29));
    expect(env.adapter.sent(_events), isEmpty);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(sentEvents(0).single['properties'], {'event': 'app_open'});
  });

  test('发不出去时存进本地队列，下次启动补发同样的事件', () async {
    env.adapter.on(_events, [const FakeResponse.offline()]);
    final (_, first) = await started();

    trackMany(first, 3);
    await first.flush();
    expect(queuedCodes(), [0, 1, 2]);

    env.adapter.on(_events, [_accepted()]);
    await started();

    final resent = sentEvents(1);
    expect(resent.map((e) => (e['properties'] as Map)['code']), [0, 1, 2]);
    expect(
      resent.map((e) => e['eventId']),
      sentEvents(0).map((e) => e['eventId']),
      reason: '重发时 eventId 不变，服务端据此去重',
    );
    expect(env.kv.values[Analytics.queueKey], isNull);
  });

  test('本地队列最多保留 500 条，满了丢掉最旧的', () async {
    env.adapter.on(_events, [const FakeResponse.offline()]);
    final (_, analytics) = await started();

    trackMany(analytics, Analytics.maxQueued + 10);
    await pumpEventQueue();
    await analytics.flush();

    final codes = queuedCodes();
    expect(codes, hasLength(Analytics.maxQueued));
    expect(codes.first, 10);
    expect(codes.last, Analytics.maxQueued + 9);
  });

  test('一批数据不合法时丢弃这一批，不再重发', () async {
    env.adapter.on(_events, [FakeAdapter.fail(10001), _accepted()]);
    final (_, analytics) = await started();

    trackMany(analytics, 2);
    await analytics.flush();
    trackMany(analytics, 1, from: 2);
    await analytics.flush();

    expect(sentEvents(1).map((e) => (e['properties'] as Map)['code']), [2]);
    expect(env.kv.values[Analytics.queueKey], isNull);
  });

  test('服务端说已关闭时停止采集，清空待发事件', () async {
    env.adapter.on(_events, [_accepted(enabled: false)]);
    final (_, analytics) = await started(session: const SignedIn());

    trackMany(analytics, 2);
    await analytics.flush();
    trackMany(analytics, Analytics.batchSize);
    await analytics.flush();

    expect(analytics.active, isFalse);
    expect(env.adapter.sent(_events), hasLength(1));
    expect(env.kv.values[Analytics.enabledKey], 'false');
    expect(env.kv.values[Analytics.queueKey], isNull);
  });

  test('本机关着使用统计时启动后也不采集', () async {
    env.kv.values[Analytics.enabledKey] = 'false';
    final (_, analytics) = await started();

    trackMany(analytics, Analytics.batchSize);
    await analytics.flush();

    expect(env.adapter.sent(_events), isEmpty);
  });

  group('开关', () {
    test('关闭：带安装 ID 请求删除，清空待发事件，之后不采集', () async {
      env.adapter.on('DELETE /telemetry/consent', [
        FakeAdapter.ok({'enabled': false, 'retentionDays': 7}),
      ]);
      final (_, analytics) = await started(session: const Guest());
      trackMany(analytics, 3);

      final saved = await analytics.changeConsent(enabled: false);
      trackMany(analytics, Analytics.batchSize);
      await analytics.flush();

      expect(saved.enabled, isFalse);
      expect(env.adapter.sent('DELETE /telemetry/consent').single.query, {
        'installId': testInstallId,
      });
      expect(env.adapter.sent(_events), isEmpty);
      expect(env.kv.values[Analytics.enabledKey], 'false');
    });

    test('关闭失败时恢复采集', () async {
      env.adapter.on('DELETE /telemetry/consent', [
        const FakeResponse.offline(),
      ]);
      final (_, analytics) = await started();

      await expectLater(
        analytics.changeConsent(enabled: false),
        throwsA(isA<AppFailure>()),
      );

      expect(analytics.active, isTrue);
      expect(env.kv.values[Analytics.enabledKey], isNull);
    });

    test('重新开启后恢复采集', () async {
      env.kv.values[Analytics.enabledKey] = 'false';
      env.adapter.on('PUT /telemetry/consent', [
        FakeAdapter.ok({'enabled': true, 'retentionDays': 7}),
      ]);
      final (_, analytics) = await started();

      await analytics.changeConsent(enabled: true);

      expect(analytics.active, isTrue);
      expect(env.kv.values[Analytics.enabledKey], isNull);
    });

    test('游客的开关只看本机', () async {
      env.kv.values[Analytics.enabledKey] = 'false';
      env.adapter.on('GET /telemetry/consent', [
        FakeAdapter.ok({'enabled': true, 'retentionDays': 7}),
      ]);
      final (_, analytics) = await started(session: const Guest());

      final stats = await analytics.loadConsent(signedIn: false);

      expect(stats.enabled, isFalse);
      expect(stats.retentionDays, 7);
    });

    test('登录后同步服务端的开关', () async {
      env.adapter
        ..on('GET /telemetry/consent', [
          FakeAdapter.ok({'enabled': false, 'retentionDays': 7}),
        ])
        ..on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
      env.kv.values[PrivacyConsentStore.key] = '{"version":"2026-10"}';
      final container = await env.container(session: const Guest());
      await container.read(consentedServicesProvider.notifier).start();
      final analytics = container.read(analyticsProvider);

      await container
          .read(sessionProvider.notifier)
          .signIn(const SignInResult(token: _token));
      await pumpEventQueue();

      expect(analytics.active, isFalse);
      expect(env.kv.values[Analytics.enabledKey], 'false');
    });
  });

  group('退出登录', () {
    test('先用当前凭证补发，再通知服务端', () async {
      env.adapter.on('POST /auth/logout', [FakeAdapter.ok()]);
      final (container, analytics) = await started(
        session: const SignedIn(user: testUser),
        token: _token,
      );
      trackMany(analytics, 2);

      await container.read(sessionProvider.notifier).logout();

      final routes = env.adapter.requests.map((r) => r.route).toList();
      expect(
        routes.indexOf(_events),
        lessThan(routes.indexOf('POST /auth/logout')),
      );
      expect(env.adapter.sent(_events).single.headers['satoken'], 'Bearer tk');
    });

    test('补发失败也清空队列', () async {
      env.adapter
        ..on(_events, [const FakeResponse.offline()])
        ..on('POST /auth/logout', [FakeAdapter.ok()]);
      final (container, analytics) = await started(
        session: const SignedIn(user: testUser),
        token: _token,
      );
      trackMany(analytics, 2);
      await analytics.flush();
      expect(env.kv.values[Analytics.queueKey], isNotNull);

      await container.read(sessionProvider.notifier).logout();

      expect(env.kv.values[Analytics.queueKey], isNull);
      expect(container.read(sessionProvider), isA<SignedOut>());
    });
  });
}
