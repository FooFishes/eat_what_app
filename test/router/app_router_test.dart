import 'package:eat/app.dart';
import 'package:eat/design/widgets/eat_nav_bar.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/features/discover/discover_page.dart';
import 'package:eat/features/kit/kit_page.dart';
import 'package:eat/features/nearby/nearby_page.dart';
import 'package:eat/features/profile/me_page.dart';
import 'package:eat/features/publish/publish_page.dart';
import 'package:eat/features/system/not_found_page.dart';
import 'package:eat/router/app_router.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/screen.dart';

Future<GoRouter> _start(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  EdgeInsets padding = EdgeInsets.zero,
  CurrentUser user = testUser,
}) async {
  useScreen(tester, size, padding: padding);
  final container = await TestEnv().container(session: SignedIn(user: user));
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const EatApp()),
  );
  await tester.pumpAndSettle();
  return container.read(appRouterProvider);
}

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

Finder _visible(Type type) => find.byType(type).hitTestable();

/// 页面本身的纵向滚动，不算分类栏这类横向滚动。
final _verticalScrollable = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

void main() {
  testWidgets('启动进入发现页，导航悬浮在底部，离左右 16、离底部 24 加安全区', (tester) async {
    final router = await _start(
      tester,
      padding: const EdgeInsets.only(top: 47, bottom: 34),
    );

    expect(_location(router), Paths.discover);
    expect(find.byType(DiscoverPage), findsOneWidget);
    final nav = tester.getRect(find.byType(EatNavBar));
    expect(nav.left, 16);
    expect(nav.right, 390 - 16);
    expect(nav.bottom, 844 - 24 - 34);
  });

  for (final path in [Paths.discover, Paths.nearby, Paths.me, Paths.publish]) {
    testWidgets('$path 上的文字都有样式，不会显示成红字加下划线的兜底样子', (tester) async {
      final router = await _start(tester);
      router.go(path);
      await tester.pumpAndSettle();

      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      );
      expect(paragraphs, isNotEmpty);
      for (final paragraph in paragraphs) {
        final style = (paragraph.text as TextSpan).style;
        expect(style?.decoration, isNot(TextDecoration.underline));
        expect(
          style?.fontFamily,
          isNotNull,
          reason: paragraph.text.toPlainText(),
        );
      }
    });
  }

  testWidgets('切换主页面时各页的状态留着', (tester) async {
    await _start(tester);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.byType(MePage), findsOneWidget);
    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(195, 700), const Offset(0, -200));
    await tester.pumpAndSettle();
    final discoverOffset = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(DiscoverPage),
            matching: _verticalScrollable,
          ),
        )
        .position
        .pixels;
    expect(discoverOffset, greaterThan(0));

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    final tabs = tester.widget<EatTabs>(find.byType(EatTabs));
    expect(tabs.selected, 1, reason: '回到「我的」时还停在「收藏」');

    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();
    final back = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(DiscoverPage),
            matching: _verticalScrollable,
          ),
        )
        .position
        .pixels;
    expect(back, discoverOffset, reason: '回到发现时滚动位置不变');
  });

  testWidgets('再点一次当前标签，页面滚回顶部', (tester) async {
    await _start(tester);
    await tester.dragFrom(const Offset(195, 700), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(DiscoverPage),
        matching: _verticalScrollable,
      ),
    );
    expect(scrollable.position.pixels, 0);
  });

  testWidgets('发布按钮打开发布页，盖住导航；返回回到原来的页面', (tester) async {
    final router = await _start(tester, user: verifiedUser);
    await tester.tap(find.text('附近'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('发布一道菜'));
    await tester.pumpAndSettle();
    expect(_visible(PublishPage), findsOneWidget);
    expect(_visible(EatNavBar), findsNothing);

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    expect(_location(router), Paths.nearby);
    expect(_visible(NearbyPage), findsOneWidget);
    expect(_visible(EatNavBar), findsOneWidget);
  });

  testWidgets('直接打开的页面没有上一页，返回去发现页', (tester) async {
    final router = await _start(tester);
    router.go(Paths.publish);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    expect(_location(router), Paths.discover);
  });

  testWidgets('安卓返回键：在附近先回发现', (tester) async {
    final router = await _start(tester);
    await tester.tap(find.text('附近'));
    await tester.pumpAndSettle();
    expect(find.byType(NearbyPage).hitTestable(), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_location(router), Paths.discover);
  });

  testWidgets('根地址进发现页，对不上的地址显示「页面不存在」', (tester) async {
    final router = await _start(tester);
    router.go('/');
    await tester.pumpAndSettle();
    expect(_location(router), Paths.discover);

    router.go('/dishes/nope');
    await tester.pumpAndSettle();
    expect(find.byType(NotFoundPage), findsOneWidget);
    await tester.tap(find.text('回到发现'));
    await tester.pumpAndSettle();
    expect(_location(router), Paths.discover);
  });

  testWidgets('宽屏时导航放在左侧面板底部', (tester) async {
    await _start(tester, size: const Size(1280, 800));

    final nav = tester.getRect(find.byType(EatNavBar));
    expect(nav.left, 36);
    expect(nav.width, 360);
    expect(nav.bottom, 800 - 36);
    final panel = tester.getRect(
      find
          .descendant(
            of: find.byType(StageScaffold),
            matching: find.byType(ClipRRect),
          )
          .first,
    );
    expect(panel.left, 16);
    expect(panel.width, 400);
  });

  testWidgets('组件页在 debug 构建里打得开，没有布局溢出', (tester) async {
    final router = await _start(tester);
    router.go(Paths.kit);
    await tester.pumpAndSettle();

    expect(find.byType(KitPage), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await tester.dragFrom(const Offset(195, 700), const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  for (final path in [Paths.discover, Paths.nearby, Paths.me, Paths.publish]) {
    testWidgets('系统字号 2 倍时 $path 不溢出', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = await _start(tester);
      router.go(path);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
