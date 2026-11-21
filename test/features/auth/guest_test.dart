import 'package:eat/design/icons/emoji.dart';
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

  final corner = find.byKey(const ValueKey('browse-corner-hit-area'));

  group('先逛逛', () {
    final fold = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.foregroundPainter.runtimeType.toString() == '_CurlPainter',
    );
    final peel = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_PagePeel',
    );
    final paper = find.byWidgetPredicate(
      (widget) =>
          widget is ClipPath &&
          widget.clipper.runtimeType.toString() == '_LoginPaperClipper',
    );

    Size cornerSize(WidgetTester tester) => tester.getSize(corner);

    testWidgets('从我的点登录，页面转场完成后才从完整纸角逐步掀开', (tester) async {
      final (container, router) = await pumpApp(
        tester,
        env,
        session: const Guest(),
        location: Paths.me,
      );
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      await tester.tap(find.text('登录'));
      for (var i = 0; i < 5 && corner.evaluate().isEmpty; i++) {
        await tester.pump();
      }
      final pageSize = tester.getSize(paper);
      bool paperCovers(double y) => tester
          .widget<ClipPath>(paper)
          .clipper!
          .getClip(pageSize)
          .contains(Offset(pageSize.width - 1, y));
      expect(paperCovers(1), isTrue);
      expect(locationOf(router), Paths.loginFrom(Paths.me));

      final route = ModalRoute.of(tester.element(paper))!.animation!;
      expect(route.status, AnimationStatus.forward);
      await tester.pump(const Duration(milliseconds: 100));
      expect(route.status, AnimationStatus.forward);
      expect(paperCovers(1), isTrue);
      for (
        var i = 0;
        i < 24 && route.status != AnimationStatus.completed;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(route.status, AnimationStatus.completed);
      expect(paperCovers(1), isTrue);

      await tester.pump(const Duration(milliseconds: 600));
      expect(paperCovers(40), isTrue);
      await tester.pump(const Duration(milliseconds: 48));
      expect(paperCovers(4), isFalse);
      expect(paperCovers(70), isTrue);
      await tester.pump(const Duration(milliseconds: 120));
      expect(paperCovers(24), isFalse);
      expect(paperCovers(95), isTrue);
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(paperCovers(100), isFalse);
      expect(paperCovers(120), isTrue);
      await unmountApp(tester, container);
    });

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

    testWidgets('拖动沿卷起方向移动纸角，反向拖动能回到原来的位置', (tester) async {
      await pumpApp(tester, env);
      final rest = cornerSize(tester);
      final gesture = await tester.startGesture(tester.getCenter(corner));
      const delta = Offset(-30, 40);
      await gesture.moveBy(delta);
      await tester.pump();
      expect(cornerSize(tester).height - rest.height, closeTo(31.3, 0.5));
      await gesture.moveBy(-delta);
      await tester.pump();
      expect(cornerSize(tester).height, closeTo(rest.height, 0.01));
      await gesture.cancel();
    });

    testWidgets('长拖只掀开右上角，超过触发距离后仍等到松手', (tester) async {
      final (_, router) = await pumpApp(tester, env);
      final rest = cornerSize(tester);
      final gesture = await tester.startGesture(tester.getCenter(corner));
      await gesture.moveBy(const Offset(-60, 80));
      await tester.pump();
      final limited = cornerSize(tester);
      await gesture.moveBy(const Offset(-120, 160));
      await tester.pump();
      final pulled = cornerSize(tester);

      expect(pulled.width, closeTo(limited.width, 1));
      expect(pulled.height, closeTo(limited.height, 1));
      expect(pulled.width - rest.width, inInclusiveRange(60, 64.01));
      expect(pulled.height - rest.height, lessThanOrEqualTo(64.01));
      expect(find.text('松手进入'), findsOneWidget);
      expect(locationOf(router), Paths.login);
      await gesture.moveBy(const Offset(180, -240));
      await gesture.up();
      await tester.pump();
      expect(cornerSize(tester), rest);
    });

    testWidgets('拖动时只在已有同意记录后预取目标数据', (tester) async {
      final (container, router) = await pumpApp(
        tester,
        env,
        location: Paths.dish(1),
      );
      await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
      await tester.pump();
      const shortDrag = Offset(-21, 20);
      await tester.drag(corner, shortDrag);
      await tester.pumpAndSettle();
      expect(env.adapter.sent('GET /foods/detail/1'), isEmpty);
      expect(env.kv.values[PrivacyConsentStore.key], isNull);
      expect(container.read(sessionProvider), isA<SignedOut>());
      expect(locationOf(router), Paths.loginFrom(Paths.dish(1)));

      await container.read(privacyConsentStoreProvider).record(null);
      final gesture = await tester.startGesture(tester.getCenter(corner));
      await gesture.moveBy(shortDrag);
      await tester.pumpAndSettle();
      expect(env.adapter.sent('GET /foods/detail/1'), hasLength(1));
      expect(container.read(sessionProvider), isA<SignedOut>());
      expect(Uri.parse(locationOf(router)).path, Paths.login);
      await gesture.up();
      await unmountApp(tester, container);
    });

    testWidgets('转场从松手时的折痕继续卷起，底下已经挂载目标页', (tester) async {
      final (container, router) = await pumpApp(tester, env);
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
      await tester.pump();
      final gesture = await tester.startGesture(tester.getCenter(corner));
      await gesture.moveBy(const Offset(-160, 190));
      await tester.pump();
      final released = tester.widget<CustomPaint>(fold).foregroundPainter!;
      await gesture.up();
      for (var i = 0; i < 20 && peel.evaluate().isEmpty; i++) {
        await tester.pump();
      }
      expect(locationOf(router), Paths.discover);
      final peelFold = find.descendant(of: peel, matching: fold);
      final peelPaper = find.descendant(of: peel, matching: paper);
      int exposedHeight() {
        final size = tester.getSize(peelPaper);
        final clip = tester.widget<ClipPath>(peelPaper).clipper!.getClip(size);
        return List.generate(size.height.floor(), (y) => y).firstWhere(
          (y) => clip.contains(Offset(size.width - 1, y.toDouble())),
        );
      }

      final initialHeight = exposedHeight();
      final mask = find.descendant(
        of: peel,
        matching: find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_BrowseMask',
        ),
      );
      final opacity = find
          .descendant(of: mask, matching: find.byType(Opacity))
          .first;
      final first = tester.widget<CustomPaint>(peelFold).foregroundPainter!;
      final hintLabel = find.descendant(of: mask, matching: find.text('松手进入'));
      final eyes = find.descendant(of: mask, matching: find.byType(EmojiImage));
      final labelStart = tester.getCenter(hintLabel);
      final eyesStart = tester.getCenter(eyes);
      expect(first.shouldRepaint(released), isFalse);
      expect(tester.getSize(mask), tester.getSize(peelFold));
      expect(tester.widget<Opacity>(opacity).opacity, 1);
      await tester.pump();
      await tester.pump();
      expect(find.byType(DiscoverPage), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 16));
      expect(exposedHeight(), greaterThan(initialHeight + 4));
      await tester.pump(const Duration(milliseconds: 284));
      final moving = tester.widget<CustomPaint>(peelFold).foregroundPainter!;
      expect(moving.shouldRepaint(first), isTrue);
      final middleOpacity = tester.widget<Opacity>(opacity).opacity;
      expect(middleOpacity, inExclusiveRange(0.0, 1.0));
      expect(tester.getCenter(hintLabel).dx, greaterThan(labelStart.dx));
      expect(tester.getCenter(eyes).dx, greaterThan(eyesStart.dx));
      await tester.pump(const Duration(milliseconds: 340));
      expect(peel, findsOneWidget);
      expect(tester.widget<Opacity>(opacity).opacity, lessThan(middleOpacity));
      await tester.pump(const Duration(seconds: 2));
      expect(peel, findsNothing);
      await unmountApp(tester, container);
    });

    testWidgets('拖动卷角超过阈值后先确认协议', (tester) async {
      final (container, router) = await pumpApp(tester, env);
      await tester.drag(corner, const Offset(-160, 160));
      await tester.pumpAndSettle();
      expect(find.text('同意后继续'), findsOneWidget);
      expect(container.read(sessionProvider), isA<SignedOut>());
      await tester.tap(find.text('同意并继续'));
      await tester.pumpAndSettle();
      expect(container.read(sessionProvider), isA<Guest>());
      expect(locationOf(router), Paths.discover);
    });

    testWidgets('没勾协议先弹对话框，同意后成为游客进发现页，并记下协议同意', (tester) async {
      final (container, router) = await pumpApp(tester, env);

      await tester.tap(corner);
      await tester.pumpAndSettle();
      expect(find.text('同意后继续'), findsOneWidget);
      await tester.tap(find.text('同意并继续'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider), isA<Guest>());
      expect(container.read(loginAgreementProvider), isTrue);
      expect(locationOf(router), Paths.discover);
      expect(find.byType(DiscoverPage), findsOneWidget);
      final store = container.read(privacyConsentStoreProvider);
      expect(await store.agreed(), isTrue);
      expect(await store.agreedVersion(), isNull, reason: '先逛逛时没有服务端版本');
      _expectNoSignedInRequests(env.adapter);
    });

    testWidgets('不同意时停在登录页，不成为游客，也不记同意', (tester) async {
      final (container, router) = await pumpApp(tester, env);

      await tester.tap(corner);
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
      await tester.tap(corner);
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
      await tester.tap(corner);
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
      await tester.tap(corner);
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
