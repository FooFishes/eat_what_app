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

    testWidgets('844 高的屏幕上舞台 520，抽屉从 488 开始压住舞台 32px', (tester) async {
      useScreen(tester, const Size(390, 844));
      await _pump(tester, page());
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byType(SheetHandle)).dy, 520 - 32 + 10);
      final stageBox = tester.getSize(
        find.ancestor(of: find.text('就它了'), matching: find.byType(Stack)).first,
      );
      expect(stageBox.height, 520);
    });

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

    testWidgets('宽屏时舞台铺满，抽屉变成左侧 400 宽的悬浮面板', (tester) async {
      useScreen(tester, const Size(1280, 800));
      await _pump(tester, page());
      await tester.pumpAndSettle();

      final panel = tester.getRect(
        find
            .ancestor(of: find.text('今日推荐'), matching: find.byType(ClipRRect))
            .first,
      );
      expect(panel.left, 16);
      expect(panel.top, 16);
      expect(panel.width, 400);
      expect(panel.bottom, 800 - 16);
      expect(find.byType(SheetHandle), findsNothing);
      expect(tester.getTopLeft(find.text('就它了')).dx, greaterThan(416));
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
    testWidgets('左上角 44px 的返回，下面大标题，左右边距 20', (tester) async {
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
      expect(tester.getSize(back), const Size(44, 44));
      expect(tester.getTopLeft(back).dx, 8);
      expect(tester.getTopLeft(find.text('设置')).dx, 20);
      expect(tester.getTopLeft(find.text('账号与安全')).dx, 20);
      await tester.tap(back);
      expect(backs, 1);
    });

    testWidgets('宽屏时挤到居中一栏，最宽 480', (tester) async {
      useScreen(tester, const Size(1280, 800));
      await _pump(tester, const PlainScaffold(title: '设置'));

      expect(tester.getTopLeft(find.text('设置')).dx, (1280 - 480) / 2 + 20);
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
