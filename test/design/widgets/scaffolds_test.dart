import 'package:eat/design/theme/eat_colors.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/design/widgets/keyboard_inset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/screen.dart';

Future<void> _pump(WidgetTester tester, Widget page) => tester.pumpWidget(
  MaterialApp(
    theme: eatThemeData(),
    home: BackFallback(fallback: () {}, child: page),
  ),
);

void main() {
  group('StageScaffold', () {
    var taps = <String>[];
    setUp(() => taps = []);

    Widget page({bool fixedStage = false}) => StageScaffold(
      stage: StageColor.broth,
      fixedStage: fixedStage,
      stageContent: Stack(
        children: [
          Positioned(
            left: 20,
            bottom: 32 + 8,
            child: EatButton.stageSolid('就它了', onPressed: () => taps.add('露出')),
          ),
          Positioned(
            right: 20,
            bottom: 0,
            child: EatButton.stageGhost(
              '压住',
              height: 30,
              onPressed: () => taps.add('压住'),
            ),
          ),
        ],
      ),
      sheetSlivers: const [
        SliverToBoxAdapter(child: SizedBox(height: 2000, child: Text('今日推荐'))),
      ],
    );

    testWidgets('抽屉画在舞台上面：露出来的按钮点得到，被压住的点不到', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(tester, page());
      await tester.pumpAndSettle();

      await tester.tap(find.text('就它了'));
      await tester.tap(find.text('压住'), warnIfMissed: false);
      expect(taps, ['露出']);
    });

    testWidgets('舞台和抽屉一起滚', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(tester, page());
      await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(195, 700), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(SheetHandle)).dy,
        520 - 32 + 10 - 300,
      );
    });

    testWidgets('fixedStage 时舞台固定在底层，抽屉上滑时盖上来', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(tester, page(fixedStage: true));
      await tester.pumpAndSettle();
      final button = tester.getTopLeft(find.text('就它了'));

      await tester.dragFrom(const Offset(195, 700), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(SheetHandle)).dy,
        lessThan(520 - 32 + 10 - 250),
        reason: '抽屉上移',
      );
      expect(tester.getTopLeft(find.text('就它了')), button, reason: '舞台不随滚动移动');

      await tester.tap(find.text('就它了'), warnIfMissed: false);
      expect(taps, isEmpty, reason: '被抽屉盖住的按钮点不到');
    });

    testWidgets('fixedStage 时顶部滑到头就停，底部继续上拉整块抽屉上移、松手回弹', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(tester, page(fixedStage: true));
      await tester.pumpAndSettle();
      final handle = find.byType(SheetHandle);
      final top = tester.getTopLeft(handle).dy;

      await tester.dragFrom(const Offset(195, 700), const Offset(0, 200));
      await tester.pump();
      expect(tester.getTopLeft(handle).dy, top, reason: '顶部不越界');
      await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(195, 700), const Offset(0, -3000));
      await tester.pumpAndSettle();
      final text = find.text('今日推荐');
      final rest = tester.getTopLeft(text).dy;
      final pull = await tester.startGesture(const Offset(195, 600));
      await pull.moveBy(const Offset(0, -40));
      await pull.moveBy(const Offset(0, -200));
      await tester.pump();
      expect(tester.getTopLeft(text).dy, lessThan(rest), reason: '底部越界');
      expect(
        rest - tester.getTopLeft(text).dy,
        lessThanOrEqualTo(128),
        reason: '越界有上限',
      );
      await pull.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(text).dy, moreOrLessEquals(rest));
    });

    testWidgets('fixedStage 时往上用力甩，停在抽屉第一行吸顶的位置；再甩才继续往下', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(
        tester,
        StageScaffold(
          stage: StageColor.broth,
          fixedStage: true,
          stageContent: const SizedBox(),
          topBar: const SizedBox(),
          sheetSlivers: const [
            SliverToBoxAdapter(child: SizedBox(height: 5000)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final handle = find.byType(SheetHandle);
      final barBottom = StageScaffold.barBottomOf(
        tester.element(find.byType(StageScaffold)),
      );

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -300),
        5000,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(handle).dy,
        moreOrLessEquals(barBottom - 28 + 10),
        reason: '把手区高 28, 把手在其中下移 10; 第一行正好贴在顶栏下方',
      );

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -300),
        5000,
      );
      await tester.pumpAndSettle();
      expect(handle, findsNothing, reason: '吸顶以后照常甩, 推荐流继续往下走');
    });

    testWidgets('fixedStage 时快速甩到底，越界后回弹到底部', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(tester, page(fixedStage: true));
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(195, 700), const Offset(0, -3000));
      await tester.pumpAndSettle();
      final text = find.text('今日推荐');
      final rest = tester.getTopLeft(text).dy;
      await tester.dragFrom(const Offset(195, 700), const Offset(0, 300));
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -600),
        4000,
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(text).dy, moreOrLessEquals(rest));
    });

    testWidgets('fixedStage 时滑到头没有拉伸效果，默认仍有', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(tester, page());
      expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);

      await _pump(tester, page(fixedStage: true));
      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    });

    Widget barPage({required VoidCallback onBack}) => StageScaffold(
      stage: StageColor.tomato,
      stageContent: const SizedBox(),
      topBar: Row(
        children: [
          EatBackButton(onPressed: onBack),
          const Expanded(child: StageBarTitle('螺蛳粉加炸蛋')),
        ],
      ),
      pinnedBottom: const SizedBox(height: 44, child: Text('今日推荐')),
      sheetSlivers: const [
        SliverToBoxAdapter(child: SizedBox(height: 44, child: Text('今日推荐'))),
        SliverToBoxAdapter(child: SizedBox(height: 2000)),
      ],
    );

    testWidgets('顶栏固定在屏幕顶部：舞台滚走后返回还点得到，标题和抽屉第一行的副本这时才出现', (tester) async {
      useScreen(tester, const Size(390, 844));
      var backs = 0;
      await _pump(tester, barPage(onBack: () => backs++));
      await tester.pumpAndSettle();

      final back = find.bySemanticsLabel('返回');
      final top = tester.getTopLeft(back).dy;
      expect(find.text('螺蛳粉加炸蛋'), findsNothing, reason: '舞台还在时菜名写在舞台上');
      expect(find.text('今日推荐'), findsOneWidget);
      expect(tester.getTopLeft(find.text('今日推荐')).dy, 520 - 32 + 28);

      await tester.dragFrom(const Offset(195, 700), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(back).dy, top, reason: '返回不随页面滚走');
      expect(find.text('螺蛳粉加炸蛋'), findsOneWidget);
      // 抽屉里的那一行已滚出屏幕, 找到的是副本. 副本在顶栏下方: 顶栏从 4 开始, 高 52.
      expect(find.text('今日推荐'), findsOneWidget);
      expect(tester.getTopLeft(find.text('今日推荐')).dy, 4 + 52);

      await tester.tap(back);
      expect(backs, 1);
    });

    testWidgets('顶栏在舞台上用舞台文字色，抽屉滚到顶栏下面后换成 ink', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(tester, barPage(onBack: () {}));
      await tester.pumpAndSettle();
      Color? barColor() =>
          DefaultTextStyle.of(tester.element(find.bySemanticsLabel('返回')))
              .style
              .color;

      expect(barColor(), StageColor.tomato.foreground);
      await tester.dragFrom(const Offset(195, 700), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(barColor(), EatColors.light.ink);
    });

    testWidgets('传了 onRefresh 才能下拉刷新，内容不满一屏也能拉', (tester) async {
      useScreen(tester, const Size(390, 844));
      var refreshes = 0;
      await _pump(
        tester,
        StageScaffold(
          stage: StageColor.broth,
          stageContent: const SizedBox(),
          onRefresh: () async => refreshes++,
          sheetSlivers: const [SliverToBoxAdapter(child: Text('只有一行'))],
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();
      expect(refreshes, 1);
    });

    testWidgets('收到再点当前标签的信号时滚回顶部', (tester) async {
      useScreen(tester, const Size(390, 844));
      final signal = ValueNotifier(0);
      addTearDown(signal.dispose);
      await _pump(tester, TabReselect(signal: signal, child: page()));
      await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(195, 700), const Offset(0, -400));
      await tester.pumpAndSettle();
      signal.value++;
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(SheetHandle)).dy, 520 - 32 + 10);
    });
  });

  group('KeyboardInset', () {
    testWidgets('键盘升降时只有留白这层重建，里面读到的键盘高度是 0', (tester) async {
      useScreen(tester, const Size(390, 844));
      var builds = 0;
      double? seen;
      final child = Builder(
        builder: (context) {
          builds++;
          seen = MediaQuery.viewInsetsOf(context).bottom;
          return const SizedBox.expand();
        },
      );
      await _pump(tester, KeyboardInset(child: child));
      expect(builds, 1);

      for (final bottom in [100.0, 200.0, 300.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: bottom * 3);
        await tester.pump();
      }
      addTearDown(tester.view.resetViewInsets);
      expect(builds, 1, reason: '键盘动画的每一帧不重建里面的内容');
      expect(seen, 0);
      expect(tester.getRect(find.byWidget(child)).bottom, 844 - 300);
    });
  });

  group('PlainScaffold', () {
    testWidgets('titleNote 紧跟在标题后面，内容从标题行下方开始', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(
        tester,
        const PlainScaffold(
          title: '消息',
          titleNote: '3 条未读',
          slivers: [SliverToBoxAdapter(child: Text('内容'))],
        ),
      );

      final title = find.textContaining('消息', findRichText: true).first;
      final titleRect = tester.getRect(title);
      expect(find.textContaining('3 条未读', findRichText: true), findsWidgets);
      expect(
        tester.getTopLeft(find.text('内容')).dy,
        greaterThan(titleRect.bottom),
      );
    });

    testWidgets('返回和大标题在同一行，点返回回调 onBack', (tester) async {
      useScreen(tester, const Size(390, 844));
      var backs = 0;
      await _pump(
        tester,
        PlainScaffold(
          title: '设置',
          onBack: () => backs++,
          slivers: const [SliverToBoxAdapter(child: Text('账号与安全'))],
        ),
      );

      final back = find.bySemanticsLabel('返回');
      final title = find.text('设置');
      expect(tester.getCenter(title).dy, tester.getCenter(back).dy);
      await tester.tap(back);
      expect(backs, 1);
    });

    testWidgets('键盘弹起时让到键盘上方，点空白处收起键盘', (tester) async {
      useScreen(tester, const Size(390, 844));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await _pump(
        tester,
        PlainScaffold(
          title: '手机号登录',
          slivers: [
            SliverToBoxAdapter(
              child: EatFormField(label: '手机号', focusNode: focus),
            ),
          ],
        ),
      );

      // 标题行固定在滚动区域上方, 滚动区域的底边贴着键盘.
      expect(tester.getRect(find.byType(CustomScrollView)).bottom, 844 - 300);
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.tapAt(const Offset(200, 500));
      await tester.pump();
      expect(focus.hasFocus, isFalse);
    });

    testWidgets('标题行固定在顶部，内容滚到下面后出现分隔线', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(
        tester,
        const PlainScaffold(
          title: '消息',
          slivers: [SliverToBoxAdapter(child: SizedBox(height: 2000))],
        ),
      );
      Color line() =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .ancestor(
                              of: find.text('消息'),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .border!
              .bottom
              .color;

      final top = tester.getTopLeft(find.text('消息')).dy;
      expect(line(), EatColors.light.paper);
      await tester.dragFrom(const Offset(195, 600), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('消息')).dy, top);
      expect(line(), EatColors.light.hairline);
    });

    testWidgets('header 代替标题排在返回按钮右边，标题只给读屏', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(
        tester,
        const PlainScaffold(title: '搜索', header: Text('搜索框')),
      );

      expect(find.text('搜索'), findsNothing);
      expect(
        tester.getCenter(find.text('搜索框')).dy,
        tester.getCenter(find.bySemanticsLabel('返回')).dy,
      );
      expect(find.bySemanticsLabel(RegExp('搜索')), findsWidgets);
    });

    testWidgets('传了 onRefresh 才能下拉刷新', (tester) async {
      useScreen(tester, const Size(390, 844));
      var refreshes = 0;
      await _pump(
        tester,
        PlainScaffold(
          title: '消息',
          onRefresh: () async => refreshes++,
          slivers: const [SliverToBoxAdapter(child: Text('一条消息'))],
        ),
      );

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();
      expect(refreshes, 1);
    });

    testWidgets('大标题不跟系统字号放大', (tester) async {
      useScreen(tester, const Size(390, 844));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, const PlainScaffold(title: '设置'));

      expect(
        tester.widget<Text>(find.text('设置')).textScaler,
        TextScaler.noScaling,
      );
    });
  });

  testWidgets('没有上一页时返回走兜底', (tester) async {
    var fallbacks = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: eatThemeData(),
        home: BackFallback(
          fallback: () => fallbacks++,
          child: const PlainScaffold(title: '发布'),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('返回'));
    expect(fallbacks, 1);
  });
}
