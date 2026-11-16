import 'dart:convert';

import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/data/remote_config/remote_config_api.dart';
import 'package:eat/data/remote_config/remote_config_repository.dart';
import 'package:eat/domain/models/client_config.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/remote_config_json.dart';

void main() {
  late FakeAdapter adapter;
  late MemoryKvStore kv;
  late RemoteConfigRepository repository;

  setUp(() {
    adapter = FakeAdapter();
    kv = MemoryKvStore();
    final client = ApiClient(
      baseUrl: testConfig.apiBaseUrl,
      tokens: TokenStore(MemorySecureStore()),
      adapter: adapter,
    );
    repository = RemoteConfigRepository(
      RemoteConfigApi(client),
      kv,
      loadDefaults: () async => '{"flags": {"push": {"on": false}}}',
    );
  });

  group('解析', () {
    test('完整的配置', () {
      final config = parseClientConfig(clientConfigJson(), ClientConfig.empty);
      expect(config.configVersion, 12);
      expect(config.flag(RemoteFeature.publish).on, isTrue);
      expect(config.flag(RemoteFeature.comment).on, isFalse);
      expect(config.flag(RemoteFeature.comment).reason, '评论区在调整，明天恢复');
      expect(config.params['batchSize'], 8);
      expect(config.announcements.map((a) => a.id), [3, 2]);
      expect(config.announcements.first.level, AnnouncementLevel.important);
      expect(config.announcements.last.title, isNull);
      expect(config.announcements.last.linkUrl, '/discover');
      expect(
        config.announcements.last.startsAt,
        DateTime.fromMillisecondsSinceEpoch(1763251200000),
      );
      expect(config.maintenance.mode, MaintenanceMode.readOnly);
      expect(
        config.maintenance.until,
        DateTime.fromMillisecondsSinceEpoch(1763307000000),
      );
      final android = config.versions['android']!;
      expect(android.minBuild, 20);
      expect(android.latestBuild, 30);
      expect(android.latestVersionName, '1.2.0');
      expect(android.storeUrl, 'market://details?id=you.v50to.eat');
    });

    test('某一项格式不对时只这一项退回默认值', () {
      const fallback = ClientConfig(
        maintenance: Maintenance(mode: MaintenanceMode.none),
        versions: {'ios': VersionLine(latestBuild: 5)},
      );
      final config = parseClientConfig(
        clientConfigJson(
          flags: {
            'publish': {'on': 'yes'},
            'comment': {'on': false},
          },
          maintenance: {'mode': 'SOMETIMES'},
          versions: {
            'android': {'minBuild': 'x'},
            'ios': 'broken',
          },
        ),
        fallback,
      );
      expect(config.flag(RemoteFeature.publish).on, isTrue);
      expect(config.flag(RemoteFeature.comment).on, isFalse);
      expect(config.maintenance.mode, MaintenanceMode.none);
      expect(config.versions.containsKey('android'), isFalse);
      expect(config.versions['ios']?.latestBuild, 5);
      expect(config.announcements, hasLength(2), reason: '其余项照常使用');
    });

    test('认不出的公告逐条丢弃', () {
      final config = parseClientConfig(
        clientConfigJson(
          announcements: [
            {'id': 1, 'level': 'URGENT', 'content': '未知级别'},
            {'id': 2, 'level': 'NORMAL', 'content': '  '},
            {'level': 'NORMAL', 'content': '没有 id'},
            {'id': 4, 'level': 'NORMAL', 'content': '正常'},
          ],
        ),
        ClientConfig.empty,
      );
      expect(config.announcements.map((a) => a.id), [4]);
    });

    test('数据不是对象时用默认值', () {
      const fallback = ClientConfig(configVersion: 3);
      expect(parseClientConfig('oops', fallback).configVersion, 3);
    });
  });

  group('请求', () {
    test('拿到新配置后存下快照和 ETag', () async {
      adapter.on('GET /remote-config', [
        FakeResponse(
          body: FakeAdapter.ok(clientConfigJson()),
          headers: const {'etag': '"abc"'},
        ),
      ]);
      final result = await repository.fetch(
        fallback: ClientConfig.empty,
        platform: 'android',
        build: 25,
        campusId: 1,
      );
      expect(result, isA<RemoteConfigFetched>());
      final snapshot = (result as RemoteConfigFetched).snapshot;
      expect(snapshot.etag, '"abc"');
      expect(snapshot.config.configVersion, 12);
      final request = adapter.sent('GET /remote-config').single;
      expect(request.query, {
        'platform': 'android',
        'build': 25,
        'campusId': 1,
      });
      expect(request.headers.containsKey('If-None-Match'), isFalse);

      final saved = await repository.readSnapshot(ClientConfig.empty);
      expect(saved?.etag, '"abc"');
      expect(saved?.config.configVersion, 12);
      expect(saved?.config.maintenance.mode, MaintenanceMode.readOnly);
    });

    test('带上 ETag，返回 304 时快照不变', () async {
      await kv.write(
        RemoteConfigRepository.snapshotKey,
        jsonEncode({'etag': '"abc"', 'data': clientConfigJson()}),
      );
      adapter.on('GET /remote-config', [const FakeResponse(status: 304)]);
      final result = await repository.fetch(
        fallback: ClientConfig.empty,
        etag: '"abc"',
      );
      expect(result, isA<RemoteConfigUnchanged>());
      expect(
        adapter.sent('GET /remote-config').single.headers['If-None-Match'],
        '"abc"',
      );
      final saved = await repository.readSnapshot(ClientConfig.empty);
      expect(saved?.config.configVersion, 12);
    });

    test('请求失败时抛出，快照不变', () async {
      adapter.on('GET /remote-config', [const FakeResponse.offline()]);
      await expectLater(
        repository.fetch(fallback: ClientConfig.empty),
        throwsA(isA<Object>()),
      );
      expect(await repository.readSnapshot(ClientConfig.empty), isNull);
    });
  });

  group('本机数据', () {
    test('读出内置默认值', () async {
      final defaults = await repository.defaults();
      expect(defaults.flag(RemoteFeature.push).on, isFalse);
      expect(defaults.flag(RemoteFeature.publish).on, isTrue);
    });

    test('内置默认值读不出时功能全开', () async {
      final broken = RemoteConfigRepository(
        RemoteConfigApi(
          ApiClient(
            baseUrl: testConfig.apiBaseUrl,
            tokens: TokenStore(MemorySecureStore()),
            adapter: adapter,
          ),
        ),
        kv,
        loadDefaults: () async => throw StateError('missing'),
      );
      final defaults = await broken.defaults();
      expect(defaults.flag(RemoteFeature.push).on, isTrue);
    });

    test('快照损坏时当作没有快照', () async {
      await kv.write(RemoteConfigRepository.snapshotKey, '{not json');
      expect(await repository.readSnapshot(ClientConfig.empty), isNull);
    });
  });
}
