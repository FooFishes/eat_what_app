import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/router/page_analytics.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../support/analytics.dart';
import '../support/app.dart';
import '../support/fakes.dart';

/// 测试用的可拨动时钟.
class _Time {
  var now = DateTime(2026, 11, 16, 12);

  void pass(Duration d) => now = now.add(d);
}

void main() {
  test('路由模板对应的页面分类', () {
    const cases = {
      Paths.discover: AnalyticsPage.home,
      Paths.topics: AnalyticsPage.recommend,
      Paths.topicPattern: AnalyticsPage.recommend,
      Paths.search: AnalyticsPage.search,
      Paths.shopPattern: AnalyticsPage.restaurant,
      Paths.shopHistoryPattern: AnalyticsPage.restaurant,
      Paths.dishPattern: AnalyticsPage.food,
      Paths.commentsPattern: AnalyticsPage.food,
      Paths.inbox: AnalyticsPage.message,
      Paths.me: AnalyticsPage.profile,
      Paths.history: AnalyticsPage.profile,
      Paths.userPattern: AnalyticsPage.profile,
      Paths.followsPattern: AnalyticsPage.profile,
      Paths.nearby: AnalyticsPage.other,
      Paths.settings: AnalyticsPage.other,
      Paths.publish: AnalyticsPage.other,
      Paths.login: AnalyticsPage.other,
      '/messages': AnalyticsPage.other,
    };
    for (final MapEntry(key: path, value: page) in cases.entries) {
      expect(analyticsPageOf(path), page, reason: path);
    }
    expect(analyticsPageOf(null), AnalyticsPage.other);
  });

  group('页面停留和加载失败', () {
    late _Time time;
    late List<AnalyticsEvent> events;
    late GoRouter router;
    late PageAnalytics pages;

    Future<void> pump(WidgetTester tester) async {
      time = _Time();
      events = [];
      router = GoRouter(
        initialLocation: Paths.discover,
        routes: [
          GoRoute(path: Paths.discover, builder: (_, _) => const Text('发现')),
          GoRoute(
            path: Paths.dishPattern,
            builder: (_, _) =>
                FailureState(error: AppFailure.fromCode(40001), onRetry: () {}),
          ),
          GoRoute(path: Paths.shopPattern, builder: (_, _) => const Text('店')),
        ],
      );
      await withClock(Clock(() => time.now), () async {
        pages = PageAnalytics(router, events.add);
        addTearDown(pages.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: eatThemeData(),
            routerConfig: router,
            builder: (_, child) =>
                LoadFailureObserver(onShown: pages.loadFailed, child: child!),
          ),
        );
        await tester.pumpAndSettle();
      });
    }

    Future<void> go(WidgetTester tester, String location) =>
        withClock(Clock(() => time.now), () async {
          router.go(location);
          await tester.pumpAndSettle();
        });

    Future<void> lifecycle(WidgetTester tester, AppLifecycleState state) =>
        withClock(Clock(() => time.now), () async {
          tester.binding.handleAppLifecycleStateChanged(state);
          await tester.pump();
        });

    List<Map<String, Object>> sent() => [
      for (final e in events) e.toProperties(),
    ];

    testWidgets('离开页面时记上一个页面的停留时长，查询参数变化不算换页', (tester) async {
      await pump(tester);
      expect(pages.page, AnalyticsPage.home);
      expect(events, isEmpty, reason: '还没离开发现页');

      time.pass(const Duration(seconds: 12));
      await go(tester, Paths.shop(7));
      time.pass(const Duration(seconds: 3));
      await go(tester, '${Paths.shop(7)}?tab=1');
      time.pass(const Duration(seconds: 2));
      await go(tester, Paths.shop(8));

      expect(sent(), [
        {'event': 'page_view', 'page': 'HOME', 'durationMs': 12000},
        {'event': 'page_view', 'page': 'RESTAURANT', 'durationMs': 5000},
      ]);
    });

    testWidgets('进后台时结束当前页面的计时，回前台重新开始', (tester) async {
      await pump(tester);

      time.pass(const Duration(seconds: 4));
      await lifecycle(tester, AppLifecycleState.inactive);
      await lifecycle(tester, AppLifecycleState.hidden);
      time.pass(const Duration(minutes: 30));
      await lifecycle(tester, AppLifecycleState.inactive);
      await lifecycle(tester, AppLifecycleState.resumed);
      time.pass(const Duration(seconds: 6));
      await go(tester, Paths.shop(7));

      expect(sent(), [
        {'event': 'page_view', 'page': 'HOME', 'durationMs': 4000},
        {'event': 'page_view', 'page': 'HOME', 'durationMs': 6000},
      ]);
    });

    testWidgets('显示「加载失败」时按所在页面和业务码记一次，重建不重复记', (tester) async {
      await pump(tester);

      await go(tester, Paths.dish(1));
      expect(find.text('加载失败'), findsOneWidget);
      tester.element(find.byType(LoadFailureReport)).markNeedsBuild();
      await tester.pump();

      expect(sent().where((e) => e['event'] == 'load_failed'), [
        {'event': 'load_failed', 'page': 'FOOD', 'code': 40001},
      ]);
    });

    testWidgets('底部面板里的「加载失败」记到下面的页面', (tester) async {
      await pump(tester);
      await go(tester, Paths.shop(7));

      final context = tester.element(find.text('店'));
      unawaited(
        showPanel<void>(
          context,
          builder: (_) => FailureState(
            error: const AppFailure(FailureKind.server, code: 502),
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(sent().where((e) => e['event'] == 'load_failed'), [
        {'event': 'load_failed', 'page': 'RESTAURANT', 'code': 502},
      ]);
    });
  });

  testWidgets('App 里切换页面时记 page_view，加载失败记 load_failed', (tester) async {
    final env = TestEnv();
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      overrides: [recordAnalytics],
    );
    router.push(Paths.inbox);
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    final recorded = recordedIn(container);

    expect(recorded.propertiesOf<PageViewEvent>().map((e) => e['page']), [
      'HOME',
      'MESSAGE',
    ]);
    expect(
      recorded.propertiesOf<LoadFailedEvent>(),
      contains(
        equals({'event': 'load_failed', 'page': 'MESSAGE', 'code': 404}),
      ),
      reason: '模拟网络对没登记的接口返回 404，消息页显示加载失败',
    );
    await unmountApp(tester, container);
  });
}
