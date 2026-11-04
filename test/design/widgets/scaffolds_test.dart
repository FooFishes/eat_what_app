import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
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

    Widget page() => StageScaffold(
      stage: StageColor.broth,
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

  group('PlainScaffold', () {
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
              child: Material(
                type: MaterialType.transparency,
                child: TextField(focusNode: focus),
              ),
            ),
          ],
        ),
      );

      expect(tester.getSize(find.byType(CustomScrollView)).height, 844 - 300);
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.tapAt(const Offset(200, 500));
      await tester.pump();
      expect(focus.hasFocus, isFalse);
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
