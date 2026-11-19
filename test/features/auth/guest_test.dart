import 'package:eat/features/auth/auth_providers.dart';
import 'package:eat/features/discover/discover_page.dart';
import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/features/settings/about_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

/// 游客不调用的接口. 这些接口要求登录, 游客调用只会得到未登录.
const _signedInOnly = [
  '/notification',
  '/foods/my',
  '/foods/favorites',
  '/restaurant/favorites',
  '/user/info',
  '/history',
];

void _expectNoSignedInRequests(FakeAdapter adapter) {
  for (final request in adapter.requests) {
    for (final path in _signedInOnly) {
      expect(
        request.path.startsWith(path),
        isFalse,
        reason: '游客不该请求 ${request.route}',
      );
    }
  }
}

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /topics/current', [FakeAdapter.ok()])
      ..on('GET /foods/recommend', [
        FakeAdapter.ok([foodJson()]),
      ])
      ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
      ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())]);
  });

  group('先逛逛', () {
    Size cornerSize(WidgetTester tester) => tester.getSize(
      find
          .ancestor(of: find.text('先逛逛？'), matching: find.byType(CustomPaint))
          .first,
    );

    testWidgets('页角每隔几秒掀起一点再回到原样', (tester) async {
      await pumpApp(tester, env);
      final rest = cornerSize(tester);

      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3300));
      await tester.pump(const Duration(milliseconds: 270));
      expect(cornerSize(tester).height, greaterThan(rest.height));

      await tester.pump(const Duration(seconds: 1));
      expect(cornerSize(tester), rest);
    });

    testWidgets('系统开启减少动态效果时页角不动', (tester) async {
      await pumpApp(tester, env);
      final rest = cornerSize(tester);

      await tester.pump(const Duration(milliseconds: 3300));
      await tester.pump(const Duration(milliseconds: 270));
      expect(cornerSize(tester), rest);
    });

    testWidgets('没勾协议先弹对话框，同意后成为游客进发现页，并记下协议同意', (tester) async {
      final (container, router) = await pumpApp(tester, env);

      await tester.tap(find.text('先逛逛？'));
      await tester.pumpAndSettle();
      expect(find.text('同意后继续'), findsOneWidget);
      await tester.tap(find.text('同意并继续'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider), isA<Guest>());
      expect(container.read(loginAgreementProvider), isTrue);
      expect(locationOf(router), Paths.discover);
      expect(find.byType(DiscoverPage), findsOneWidget);
      expect(
        await container.read(privacyConsentStoreProvider).agreedVersion(),
        PrivacyConsentStore.currentVersion,
      );
      _expectNoSignedInRequests(env.adapter);
    });

    testWidgets('不同意时停在登录页，不成为游客，也不记同意', (tester) async {
      final (container, router) = await pumpApp(tester, env);

      await tester.tap(find.text('先逛逛？'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('不同意'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider), isA<SignedOut>());
      expect(locationOf(router), Paths.login);
      expect(env.kv.values[PrivacyConsentStore.key], isNull);
    });

    testWidgets('分享链接指向的菜：点「先逛逛」后直接到那道菜', (tester) async {
      final (container, router) = await pumpApp(
        tester,
        env,
        location: Paths.dish(1),
      );
      expect(Uri.parse(locationOf(router)).path, Paths.login);

      await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
      await tester.pump();
      await tester.tap(find.text('先逛逛？'));
      await tester.pumpAndSettle();

      expect(find.text('同意后继续'), findsNothing);
      expect(locationOf(router), Paths.dish(1));
      expect(find.byType(DishPage), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('原来要去的页面游客看不了，点「先逛逛」后进发现页', (tester) async {
      final (_, router) = await pumpApp(tester, env, location: Paths.inbox);
      expect(Uri.parse(locationOf(router)).queryParameters['from'], '/inbox');

      await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
      await tester.pump();
      await tester.tap(find.text('先逛逛？'));
      await tester.pumpAndSettle();

      expect(locationOf(router), Paths.discover);
    });
  });

  group('游客', () {
    testWidgets('点消息弹登录对话框：「先逛逛」关掉，「去登录」回登录页，还能再点「先逛逛」', (tester) async {
      final (_, router) = await pumpApp(tester, env, session: const Guest());

      await tester.tap(find.bySemanticsLabel('消息'));
      await tester.pumpAndSettle();
      expect(find.text('登录后才能看消息'), findsOneWidget);
      await tester.tap(find.text('先逛逛'));
      await tester.pumpAndSettle();
      expect(find.text('登录后才能看消息'), findsNothing);
      expect(locationOf(router), Paths.discover);

      await tester.tap(find.bySemanticsLabel('消息'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('去登录'));
      await tester.pumpAndSettle();
      expect(locationOf(router), Paths.login);

      await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
      await tester.pump();
      await tester.tap(find.text('先逛逛？'));
      await tester.pumpAndSettle();
      expect(locationOf(router), Paths.discover);
      _expectNoSignedInRequests(env.adapter);
    });

    testWidgets('点上传者弹登录对话框，「去登录」带上菜品详情的地址', (tester) async {
      final (container, router) = await pumpApp(
        tester,
        env,
        session: const Guest(),
        location: Paths.dish(1),
      );

      // 游客不能查上传者资料, 上传者写 "同学".
      await tester.scrollUntilVisible(
        find.text('同学'),
        200,
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      await tester.tap(find.text('同学'));
      await tester.pumpAndSettle();
      expect(find.text('登录后才能看主页'), findsOneWidget);
      await tester.tap(find.text('去登录'));
      await tester.pumpAndSettle();

      expect(locationOf(router), Paths.loginFrom(Paths.dish(1)));
      _expectNoSignedInRequests(env.adapter);
      await unmountApp(tester, container);
    });

    testWidgets('「我的」只有一句说明和「登录」，登录后回到「我的」', (tester) async {
      final (_, router) = await pumpApp(
        tester,
        env,
        session: const Guest(),
        location: Paths.me,
      );

      expect(find.text('登录后看你的收藏、评论和发布'), findsOneWidget);
      expect(find.text('上传'), findsNothing);
      expect(find.text('历史'), findsNothing);
      expect(find.bySemanticsLabel('编辑资料'), findsNothing);
      await expectAccessible(tester);
      _expectNoSignedInRequests(env.adapter);

      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();
      expect(locationOf(router), Paths.loginFrom(Paths.me));
    });

    testWidgets('设置里只有「关于」，关于里的「反馈」弹登录对话框', (tester) async {
      await pumpApp(
        tester,
        env,
        session: const Guest(),
        location: Paths.settings,
      );

      expect(find.text('关于与反馈'), findsOneWidget);
      expect(find.text('账号与安全'), findsNothing);
      expect(find.text('退出登录'), findsNothing);

      await tester.tap(find.text('关于与反馈'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutPage), findsOneWidget);
      await tester.tap(find.text('反馈'));
      await tester.pumpAndSettle();
      expect(find.text('登录后才能反馈'), findsOneWidget);
    });

    testWidgets('搜过的词不保存', (tester) async {
      env.adapter
        ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
        ..on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const Guest(),
        location: Paths.search,
      );

      await tester.enterText(find.byType(EditableText), '袁记');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(env.adapter.sent('GET /foods/list'), isNotEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('最近搜过'), findsNothing);
      expect(
        env.kv.values.keys.where((k) => k.startsWith('cache.search')),
        isEmpty,
      );
      await unmountApp(tester, container);
    });
  });
}
