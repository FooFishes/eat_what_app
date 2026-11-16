import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:eat/core/platform/app_info.dart';
import 'package:eat/data/remote_config/remote_config_repository.dart';
import 'package:eat/domain/models/client_config.dart';
import 'package:eat/domain/rules/remote_config_rules.dart';
import 'package:eat/state/remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/remote_config_json.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnv env;

  setUp(() => env = TestEnv());

  Future<ProviderContainer> container({String build = '25'}) => env.container(
    overrides: [appBuildNumberProvider.overrideWith((ref) async => build)],
  );

  Map<String, Object?> config({Object? maintenance, Object? versions}) =>
      FakeAdapter.ok(
        clientConfigJson(maintenance: maintenance, versions: versions),
      );

  group('快照', () {
    test('没有快照时用打包的默认值：功能全开，没有公告和维护', () async {
      final c = await container();
      await c.read(remoteConfigProvider.notifier).restore();
      final state = c.read(remoteConfigProvider);
      for (final feature in RemoteFeature.values) {
        expect(state.flag(feature).on, isTrue, reason: feature.name);
      }
      expect(state.announcements, isEmpty);
      expect(state.maintenance.mode, MaintenanceMode.none);
      expect(env.adapter.requests, isEmpty, reason: '启动时不等网络');
    });

    test('有快照时先用快照', () async {
      await env.kv.write(
        RemoteConfigRepository.snapshotKey,
        jsonEncode({'etag': '"v1"', 'data': clientConfigJson()}),
      );
      final c = await container();
      await c.read(remoteConfigProvider.notifier).restore();
      expect(c.read(remoteConfigProvider).configVersion, 12);
    });
  });

  group('获取', () {
    test('拿到新配置后替换并带上平台、构建号和 ETag', () async {
      env.adapter.on('GET /remote-config', [
        FakeResponse(body: config(), headers: const {'etag': '"v1"'}),
        const FakeResponse(status: 304),
      ]);
      final c = await container();
      final notifier = c.read(remoteConfigProvider.notifier);
      await notifier.refresh();
      expect(c.read(remoteConfigProvider).configVersion, 12);
      final first = env.adapter.sent('GET /remote-config').single;
      expect(first.query['platform'], 'android');
      expect(first.query['build'], 25);

      await notifier.refresh();
      expect(
        env.adapter.sent('GET /remote-config').last.headers['If-None-Match'],
        '"v1"',
      );
      expect(
        c.read(remoteConfigProvider).configVersion,
        12,
        reason: '304 时保留当前配置',
      );
    });

    test('获取失败时保留当前配置', () async {
      env.adapter.on('GET /remote-config', [const FakeResponse.offline()]);
      final c = await container();
      await c.read(remoteConfigProvider.notifier).refresh();
      expect(c.read(remoteConfigProvider), same(ClientConfig.empty));
    });

    test('回到前台时超过 10 分钟才重新获取，没开始获取过时不请求', () async {
      env.adapter.on('GET /remote-config', [
        FakeAdapter.ok(clientConfigJson()),
      ]);
      final c = await container();
      final notifier = c.read(remoteConfigProvider.notifier);
      final start = DateTime(2026, 11, 16, 12);

      await withClock(Clock.fixed(start), notifier.resume);
      expect(env.adapter.sent('GET /remote-config'), isEmpty);

      await withClock(Clock.fixed(start), notifier.refresh);
      await withClock(
        Clock.fixed(start.add(const Duration(minutes: 9))),
        notifier.resume,
      );
      expect(env.adapter.sent('GET /remote-config'), hasLength(1));

      await withClock(
        Clock.fixed(start.add(const Duration(minutes: 11))),
        notifier.resume,
      );
      expect(env.adapter.sent('GET /remote-config'), hasLength(2));
    });
  });

  group('派生状态', () {
    test('低于最低构建号时守卫强制更新', () async {
      env.adapter.on('GET /remote-config', [config()]);
      final c = await container(build: '19');
      await c.read(appBuildNumberProvider.future);
      await c.read(remoteConfigProvider.notifier).refresh();
      expect(c.read(appUpdateProvider), UpdateDecision.force);
      expect(c.read(appGateProvider), (forceUpdate: true, down: false));
    });

    test('停服维护时守卫进维护页', () async {
      env.adapter.on('GET /remote-config', [
        config(maintenance: {'mode': 'DOWN', 'message': null, 'until': null}),
      ]);
      final c = await container(build: '30');
      await c.read(appBuildNumberProvider.future);
      await c.read(remoteConfigProvider.notifier).refresh();
      expect(c.read(appGateProvider), (forceUpdate: false, down: true));
    });

    test('建议更新提示一次后不再提示，记录存在本机', () async {
      env.adapter.on('GET /remote-config', [config()]);
      final c = await container();
      c.read(noticesProvider);
      await c.read(appBuildNumberProvider.future);
      await c.read(remoteConfigProvider.notifier).refresh();
      await pumpEventQueue();
      expect(c.read(updatePromptProvider)?.latestBuild, 30);

      await c.read(noticesProvider.notifier).markPrompted(30);
      expect(c.read(updatePromptProvider), isNull);
      expect(await env.kv.read(Notices.promptedKey), '30');
    });

    test('关掉的普通公告和看过的重要公告不再出现', () async {
      env.adapter.on('GET /remote-config', [config()]);
      final c = await container();
      c.read(noticesProvider);
      await c.read(remoteConfigProvider.notifier).refresh();
      await pumpEventQueue();
      expect(c.read(bannerNoticeProvider)?.id, 2);
      expect(c.read(importantNoticeProvider)?.id, 3);

      await c.read(noticesProvider.notifier).dismiss(2);
      await c.read(noticesProvider.notifier).markSeen(3);
      expect(c.read(bannerNoticeProvider), isNull);
      expect(c.read(importantNoticeProvider), isNull);

      final next = await env.container();
      next.read(noticesProvider);
      await pumpEventQueue();
      expect(next.read(noticesProvider).dismissed, {2});
      expect(next.read(noticesProvider).seen, {3});
    });
  });
}
