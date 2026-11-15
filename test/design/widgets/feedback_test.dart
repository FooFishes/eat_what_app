import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/turntable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/eat_test_app.dart';

double _opacityOf(WidgetTester tester, Finder child) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(of: child, matching: find.byType(AnimatedOpacity)).first,
    )
    .opacity;

void main() {
  group('按下反馈', () {
    testWidgets('列表行这类不画按下效果的组件，按住时整体变淡，松开恢复', (tester) async {
      await pumpEat(
        tester,
        EatTappable(onTap: () {}, builder: (context, _) => const Text('一行')),
      );

      expect(_opacityOf(tester, find.text('一行')), 1);
      final gesture = await tester.press(find.text('一行'));
      await tester.pump();
      expect(_opacityOf(tester, find.text('一行')), EatTappable.pressedOpacity);
      await gesture.up();
      await tester.pump();
      expect(_opacityOf(tester, find.text('一行')), 1);
    });

    testWidgets('按钮自己下沉，不再叠加变淡', (tester) async {
      await pumpEat(tester, EatButton.solid('就它了', onPressed: () {}));

      expect(
        find.ancestor(
          of: find.text('就它了'),
          matching: find.byType(AnimatedOpacity),
        ),
        findsNothing,
      );
    });

    testWidgets('不可点的组件按住不变淡', (tester) async {
      await pumpEat(
        tester,
        EatTappable(onTap: null, builder: (context, _) => const Text('一行')),
      );

      await tester.press(find.text('一行'));
      await tester.pump();
      expect(_opacityOf(tester, find.text('一行')), 1);
    });
  });

  group('图标', () {
    testWidgets('赞过的心形在按钮里用番茄红，没赞过跟按钮文字色', (tester) async {
      await pumpEat(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EatButton.mist('328', icon: EatIcons.heartOn, onPressed: () {}),
            EatButton.outline('327', icon: EatIcons.heart, onPressed: () {}),
          ],
        ),
      );

      final icons = tester.widgetList<EatIcon>(find.byType(EatIcon)).toList();
      expect(icons[0].icon, EatIcons.heartOn);
      expect(icons[0].color, isNull, reason: '不传颜色时 EatIcon 给 heartOn 用番茄红');
      expect(icons[1].color, isNotNull);
      expect(StageColor.tomato.color, const Color(0xFFC9442B));
    });

    testWidgets('图标按钮换图标时新图标从小放大', (tester) async {
      var on = false;
      await pumpEat(
        tester,
        StatefulBuilder(
          builder: (context, setState) => EatIconButton(
            on ? EatIcons.bookmarkOn : EatIcons.bookmark,
            label: on ? '取消收藏' : '收藏',
            onPressed: () => setState(() => on = !on),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('收藏'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(EatIcon), findsNWidgets(2), reason: '旧图标退场, 新图标进场');
      await tester.pumpAndSettle();
      expect(
        tester.widget<EatIcon>(find.byType(EatIcon)).icon,
        EatIcons.bookmarkOn,
      );
    });
  });

  group('触感', () {
    final calls = <String>[];
    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add(call.arguments as String);
            }
            return null;
          });
    });
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    testWidgets('转盘拖到另一道菜时给一次选中的触感，没换成不给', (tester) async {
      var index = 0;
      await pumpEat(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 390,
            height: 520,
            child: Turntable(
              items: [
                for (var i = 0; i < 6; i++) const TurntableItem(image: null),
              ],
              index: index,
              onIndexChanged: (i) => setState(() => index = i),
              plateSize: 296,
              plateCenter: const Offset(330, 300),
            ),
          ),
        ),
        stage: StageColor.broth,
        disableAnimations: true,
      );

      await tester.drag(find.byType(Turntable), const Offset(-10, 0));
      await tester.pump();
      expect(index, 0);
      expect(calls, isEmpty);

      await tester.drag(find.byType(Turntable), const Offset(-120, 0));
      await tester.pump();
      expect(index, 1);
      expect(calls, ['HapticFeedbackType.selectionClick']);
    });
  });

  testWidgets('不足 5 家不画转盘时照样能拖动换店', (tester) async {
    var index = 0;
    await pumpEat(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 390,
          height: 520,
          child: Turntable(
            items: [
              for (var i = 0; i < 3; i++) const TurntableItem(image: null),
            ],
            index: index,
            onIndexChanged: (i) => setState(() => index = i),
            plateSize: 296,
            plateCenter: const Offset(330, 300),
            spinning: false,
          ),
        ),
      ),
      stage: StageColor.broth,
      disableAnimations: true,
    );

    await tester.drag(find.byType(Turntable), const Offset(-120, 0));
    await tester.pump();
    expect(index, 1);
  });

  testWidgets('手机上转走的上一道菜不留在左下角，不压住价格和按钮', (tester) async {
    Widget table(int index) => SizedBox(
      width: 390,
      height: 520,
      child: Turntable(
        items: [for (var i = 0; i < 6; i++) const TurntableItem(image: null)],
        index: index,
        onIndexChanged: (_) {},
        plateSize: 296,
        plateCenter: const Offset(330, 300),
      ),
    );
    await pumpEat(
      tester,
      table(0),
      stage: StageColor.broth,
      disableAnimations: true,
    );
    await pumpEat(
      tester,
      table(1),
      stage: StageColor.broth,
      disableAnimations: true,
    );
    await tester.pump();

    final opacities = tester
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(Turntable),
            matching: find.byType(Opacity),
          ),
        )
        .map((o) => o.opacity)
        .toList();
    // 依次是上一道, 当前这道, 下一道.
    expect(opacities, [0, 1, 1]);
  });

  testWidgets('轻提示停留 2 秒后退场，新提示直接替换旧提示', (tester) async {
    late BuildContext context;
    await pumpEat(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );

    showToast(context, '已收藏');
    await tester.pump();
    showToast(context, '已取消收藏');
    await tester.pump();
    expect(find.text('已收藏'), findsNothing);
    expect(find.text('已取消收藏'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.text('已取消收藏'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('已取消收藏'), findsNothing);
  });

  testWidgets('面板里的操作行：圆底图标加文字，整行可点，行高不小于 44', (tester) async {
    var taps = 0;
    await pumpEat(
      tester,
      SizedBox(
        width: 350,
        child: EatPanelAction(
          icon: EatIcons.block,
          label: '屏蔽',
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('屏蔽'));
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(EatPanelAction)).height,
      greaterThanOrEqualTo(44),
    );
    await expectAccessible(tester);
  });
}
