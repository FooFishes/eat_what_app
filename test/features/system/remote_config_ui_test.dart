import 'dart:convert';

import 'package:eat/core/platform/app_info.dart';
import 'package:eat/core/platform/app_store.dart';
import 'package:eat/data/remote_config/remote_config_repository.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/remote_config.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:go_router/go_router.dart';

import '../../support/app.dart';
import '../../support/fakes.dart';
import '../../support/recommend_json.dart';
import '../../support/remote_config_json.dart';

class _FakeAppStore implements AppStore {
  final opened = <String?>[];

  @override
  Future<bool> open(String? storeUrl) async {
    opened.add(storeUrl);
    return true;
  }
}

const _noVersions = <String, Object?>{};
const _noMaintenance = {'mode': 'NONE'};

void main() {
  late TestEnv env;
  late _FakeAppStore store;

  setUp(() {
    env = TestEnv();
    store = _FakeAppStore();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /notification/cards/unread/count', [
        FakeAdapter.ok({'cards': 0, 'members': 0}),
      ])
      ..on('GET /recommend', [FakeAdapter.ok(feedJson(const []))]);
  });

  /// 写入本机快照后启动 App, 再按 `bootstrap` 的做法读出快照.
  Future<(ProviderContainer, GoRouter)> launch(
    WidgetTester tester, {
    Object? announcements = const <Object>[],
    Object? maintenance = _noMaintenance,
    Object? versions = _noVersions,
    Map<String, Object?>? flags,
    String build = '25',
  }) async {
    await env.kv.write(
      RemoteConfigRepository.snapshotKey,
      jsonEncode({
        'data': clientConfigJson(
          flags: flags,
          announcements: announcements,
          maintenance: maintenance,
          versions: versions,
        ),
      }),
    );
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      overrides: [
        appBuildNumberProvider.overrideWith((ref) async => build),
        appVersionProvider.overrideWith((ref) async => '0.1.0'),
        appStoreProvider.overrideWithValue(store),
      ],
    );
    // 内置默认值由 rootBundle 读取并缓存. 缓存的 Future 在首个测试的模拟时钟中完成,
    // 后续测试若仍在模拟时钟中等待它将无法继续, 因此改在真实异步环境中读取.
    await tester.runAsync(
      () => container.read(remoteConfigProvider.notifier).restore(),
    );
    await tester.pumpAndSettle();
    return (container, router);
  }

  testWidgets('停服维护时进维护页，维护结束后「再试一次」回到发现页', (tester) async {
    final until = DateTime.now().add(const Duration(minutes: 1));
    final (container, router) = await launch(
      tester,
      maintenance: {
        'mode': 'DOWN',
        'message': null,
        'until': until.millisecondsSinceEpoch,
      },
    );
    expect(locationOf(router), Paths.maintenance);
    expect(find.text('正在维护'), findsOneWidget);
    expect(find.text('预计恢复'), findsOneWidget);

    router.go(Paths.me);
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.maintenance, reason: '维护中哪里都去不了');

    env.adapter.on('GET /remote-config', [
      FakeAdapter.ok(
        clientConfigJson(
          announcements: const [],
          maintenance: _noMaintenance,
          versions: _noVersions,
        ),
      ),
    ]);
    await tester.tap(find.text('再试一次'));
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.discover);
    await unmountApp(tester, container);
  });

  testWidgets('低于最低构建号时进更新页，「去更新」打开商店', (tester) async {
    final (container, router) = await launch(
      tester,
      build: '10',
      versions: {
        'android': {
          'minBuild': 20,
          'latestBuild': 30,
          'latestVersionName': '1.2.0',
          'storeUrl': 'market://details?id=you.v50to.eat',
        },
      },
    );
    expect(locationOf(router), Paths.update);
    expect(find.text('该更新了'), findsOneWidget);
    expect(find.text('你现在是 0.1.0'), findsOneWidget);
    expect(find.text('最新 1.2.0'), findsOneWidget);

    await tester.tap(find.text('去更新'));
    await tester.pumpAndSettle();
    expect(store.opened, ['market://details?id=you.v50to.eat']);
    await unmountApp(tester, container);
  });

  testWidgets('全站只读时点发布只提示，不进入发布流程', (tester) async {
    final until = DateTime.now();
    final hm =
        '${until.hour.toString().padLeft(2, '0')}:'
        '${until.minute.toString().padLeft(2, '0')}';
    final (container, router) = await launch(
      tester,
      maintenance: {
        'mode': 'READ_ONLY',
        'message': null,
        'until': until.millisecondsSinceEpoch,
      },
    );
    await tester.tap(find.bySemanticsLabel('发布一道菜').first);
    await tester.pump();
    expect(find.text('系统维护中，暂停发布，预计 $hm 恢复'), findsOneWidget);
    // 等轻提示停留结束, 否则测试结束时计时器仍未触发.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.discover);
    await unmountApp(tester, container);
  });

  testWidgets('发布关掉时点发布提示原因', (tester) async {
    final (container, router) = await launch(
      tester,
      flags: {
        'publish': {'on': false, 'reason': '发布功能在升级'},
      },
    );
    await tester.tap(find.bySemanticsLabel('发布一道菜').first);
    await tester.pump();
    expect(find.text('该功能暂时关闭，发布功能在升级'), findsOneWidget);
    // 等轻提示停留结束, 否则测试结束时计时器仍未触发.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.discover);
    await unmountApp(tester, container);
  });

  testWidgets('重要公告打开 App 时弹一次', (tester) async {
    final (container, _) = await launch(
      tester,
      announcements: [
        {
          'id': 3,
          'level': 'IMPORTANT',
          'title': '食堂调整',
          'content': '一食堂二楼周末不开',
        },
      ],
    );
    expect(find.text('食堂调整'), findsOneWidget);
    expect(find.text('一食堂二楼周末不开'), findsOneWidget);
    expect(await env.kv.read(Notices.seenKey), '[3]');

    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(find.text('食堂调整'), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('普通公告在发现页抽屉顶部，关掉后不再出现', (tester) async {
    final (container, _) = await launch(
      tester,
      announcements: [
        {'id': 2, 'level': 'NORMAL', 'content': '西门小吃街周五晚上修路'},
      ],
    );
    expect(find.text('西门小吃街周五晚上修路'), findsOneWidget);

    await tester.tap(find.text('西门小吃街周五晚上修路'));
    await tester.pumpAndSettle();
    expect(find.text('公告'), findsOneWidget, reason: '点公告条看全文');
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('关掉这条公告'));
    await tester.pumpAndSettle();
    expect(find.text('西门小吃街周五晚上修路'), findsNothing);
    expect(await env.kv.read(Notices.dismissedKey), '[2]');
    await unmountApp(tester, container);
  });

  testWidgets('有新版本时发现页提示一次', (tester) async {
    final (container, _) = await launch(
      tester,
      versions: {
        'android': {
          'minBuild': 0,
          'latestBuild': 30,
          'latestVersionName': '1.2.0',
          'storeUrl': 'market://details?id=you.v50to.eat',
          'releaseNotes': '修了几个问题',
        },
      },
    );
    expect(find.text('有新版本'), findsOneWidget);
    expect(find.text('0.1.0 升到 1.2.0'), findsOneWidget);
    expect(find.text('修了几个问题'), findsOneWidget);
    expect(await env.kv.read(Notices.promptedKey), '30');

    await tester.tap(find.text('下次再说'));
    await tester.pumpAndSettle();
    expect(find.text('有新版本'), findsNothing);
    await unmountApp(tester, container);
  });

  group('设置里检查更新', () {
    const newer = {
      'android': {
        'minBuild': 0,
        'latestBuild': 30,
        'latestVersionName': '1.2.0',
        'storeUrl': 'market://details?id=you.v50to.eat',
        'releaseNotes': null,
      },
    };

    Future<(ProviderContainer, GoRouter)> openSettings(
      WidgetTester tester,
    ) async {
      final (container, router) = await launch(tester);
      router.go(Paths.settings);
      await tester.pumpAndSettle();
      return (container, router);
    }

    testWidgets('有新版本时弹「有新版本」，版本号和「有新版本」用提醒色', (tester) async {
      final (container, router) = await openSettings(tester);
      expect(find.text('有新版本'), findsNothing);

      env.adapter.on('GET /remote-config', [
        FakeAdapter.ok(
          clientConfigJson(
            announcements: const [],
            maintenance: _noMaintenance,
            versions: newer,
          ),
        ),
      ]);
      await tester.tap(find.text('检查更新'));
      await tester.pumpAndSettle();
      expect(find.text('0.1.0 升到 1.2.0'), findsOneWidget);
      await tester.tap(find.text('下次再说'));
      await tester.pumpAndSettle();

      final warn = tester.element(find.text('检查更新')).eat.colors.warn;
      expect(tester.widget<Text>(find.text('有新版本')).style?.color, warn);
      expect(tester.widget<Text>(find.text('0.1.0')).style?.color, warn);

      router.go(Paths.settingsAbout);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('0.1.0')).style?.color, warn);
      expect(find.text('构建 25  有新版本'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('商店没有新版本但有新补丁时下载补丁，提示重新打开后生效', (tester) async {
      env.updater
        ..isAvailable = true
        ..status = UpdateStatus.outdated;
      final (container, _) = await openSettings(tester);
      env.adapter.on('GET /remote-config', [
        FakeAdapter.ok(
          clientConfigJson(
            announcements: const [],
            maintenance: _noMaintenance,
            versions: _noVersions,
          ),
        ),
      ]);
      final updates = env.updater.updates;
      await tester.tap(find.text('检查更新'));
      await tester.pumpAndSettle();
      expect(env.updater.updates, updates + 1);
      expect(find.text('更新已下载，重新打开 App 后生效'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await unmountApp(tester, container);
    });

    testWidgets('已是最新时提示，请求失败时提示重试', (tester) async {
      final (container, _) = await openSettings(tester);
      env.adapter.on('GET /remote-config', [
        FakeAdapter.ok(
          clientConfigJson(
            announcements: const [],
            maintenance: _noMaintenance,
            versions: _noVersions,
          ),
        ),
        const FakeResponse.offline(),
      ]);
      await tester.tap(find.text('检查更新'));
      await tester.pumpAndSettle();
      expect(find.text('已是最新版本'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('检查更新'));
      await tester.pumpAndSettle();
      expect(find.text('检查更新失败，请重试'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });
  });
}
