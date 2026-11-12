import 'dart:ui' show Tristate;

import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_radio_row.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/eat_test_app.dart';

FontWeight? _weight(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.fontWeight;

void main() {
  group('EatChip', () {
    testWidgets('单选分类读作单选项，选中时字重 600', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpEat(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            EatChip.choice('主食', selected: true, onTap: () {}),
            EatChip.choice('小吃', selected: false, onTap: () {}),
          ],
        ),
      );

      expect(
        tester.getSemantics(find.widgetWithText(EatChip, '主食')),
        matchesSemantics(
          label: '主食',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(_weight(tester, '主食'), FontWeight.w600);
      expect(_weight(tester, '小吃'), FontWeight.w400);
      semantics.dispose();
    });

    testWidgets('多选标签读作开关按钮', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpEat(tester, EatChip.tag('平价', selected: true, onTap: () {}));

      final data = tester.getSemantics(find.byType(EatChip)).getSemanticsData();
      expect(data.flagsCollection.isToggled, Tristate.isTrue);
      semantics.dispose();
    });

    testWidgets('看上去 36px，点击区域 44px', (tester) async {
      var taps = 0;
      await pumpEat(tester, EatChip.add('自己写', onTap: () => taps++));

      expect(tester.getSize(find.byType(EatChip)).height, 44);
      final visual = find.descendant(
        of: find.byType(EatChip),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 36,
        ),
      );
      expect(visual, findsOneWidget);

      await tester.tapAt(
        tester.getTopLeft(find.byType(EatChip)) + const Offset(20, 2),
      );
      expect(taps, 1, reason: '36px 外、44px 内也算点中');
    });

    testWidgets('「待接入」小标跟着功能名一起读出', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpEat(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text('评分'), PendingTag()],
        ),
      );

      expect(find.text('待接入'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('待接入')), findsOneWidget);
      semantics.dispose();
    });
  });

  group('EatTabs', () {
    testWidgets('选中项 600 字重，其他 400；点别的分类回调序号', (tester) async {
      final picked = <int>[];
      await pumpEat(
        tester,
        EatTabs(
          tabs: const [
            EatTabItem('上传', count: 42),
            EatTabItem('收藏', count: 117),
            EatTabItem('评论', pending: true),
          ],
          selected: 0,
          onSelected: picked.add,
        ),
      );

      expect(_weight(tester, '上传'), FontWeight.w600);
      expect(_weight(tester, '收藏'), FontWeight.w400);
      expect(find.text('117'), findsOneWidget);
      expect(find.byType(PendingTag), findsOneWidget);

      await tester.tap(find.text('收藏'));
      expect(picked, [1]);
      expect(tester.getSize(find.byType(EatTabs)).height, closeTo(44, 1));
    });

    testWidgets('放不下时横向滚动，不换行也不溢出', (tester) async {
      await pumpEat(
        tester,
        SizedBox(
          width: 200,
          child: EatTabs(
            tabs: [
              for (final name in ['今日推荐', '主食', '小吃', '饮品', '甜品', '汤', '火锅'])
                EatTabItem(name),
            ],
            selected: 0,
            onSelected: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('选中露出一半的分类后，分类栏把它滚到中间', (tester) async {
      var selected = 0;
      const names = ['今日推荐', '主食', '小吃', '饮品', '甜品', '汤', '火锅'];
      await pumpEat(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 200,
            child: EatTabs(
              tabs: [for (final name in names) EatTabItem(name)],
              selected: selected,
              onSelected: (i) => setState(() => selected = i),
            ),
          ),
        ),
        disableAnimations: true,
      );
      final strip = tester.getRect(find.byType(EatTabs));

      await tester.tap(find.text('小吃'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, 2);
      final tab = tester.getRect(find.text('小吃'));
      expect(tab.left, greaterThanOrEqualTo(strip.left));
      expect(tab.right, lessThanOrEqualTo(strip.right));
      expect(tab.center.dx, closeTo(strip.center.dx, 24));
    });
  });

  group('EatRadioRow', () {
    testWidgets('选中时铺 mist 底，读作选中的单选项', (tester) async {
      final semantics = tester.ensureSemantics();
      var picked = false;
      await pumpEat(
        tester,
        SizedBox(
          width: 360,
          child: EatRadioRow(
            title: '广告',
            selected: false,
            onSelected: () => picked = true,
          ),
        ),
      );

      expect(tester.getSize(find.byType(EatRadioRow)).height, 52);
      await tester.tap(find.byType(EatRadioRow));
      expect(picked, isTrue);
      final data = tester
          .getSemantics(find.byType(EatRadioRow))
          .getSemanticsData();
      expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      semantics.dispose();
    });
  });

  group('EatSwitch', () {
    testWidgets('整行可点，回调取反后的值', (tester) async {
      final values = <bool>[];
      await pumpEat(
        tester,
        SizedBox(
          width: 360,
          child: EatSwitch(
            label: '公开我的关注列表',
            description: '关掉后别人点开，看到的是「对方未公开」',
            value: true,
            onChanged: values.add,
          ),
        ),
      );

      await tester.tap(find.text('公开我的关注列表'));
      expect(values, [false]);
      expect(
        tester.getSize(find.byType(EatSwitch)).height,
        greaterThanOrEqualTo(64),
      );
    });

    testWidgets('待接入的开关照样画出来，点了不回调，读屏报不可用', (tester) async {
      final semantics = tester.ensureSemantics();
      final values = <bool>[];
      await pumpEat(
        tester,
        SizedBox(
          width: 360,
          child: EatSwitch(
            label: '个性化推荐',
            value: true,
            onChanged: values.add,
            pending: true,
          ),
        ),
      );

      await tester.tap(find.byType(EatSwitch));
      expect(values, isEmpty);
      expect(find.byType(PendingTag), findsOneWidget);
      final data = tester
          .getSemantics(find.byType(EatSwitch))
          .getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.flagsCollection.isToggled, Tristate.isTrue);
      semantics.dispose();
    });
  });

  testWidgets('分类、标签、单选行和开关满足点击区域和说明要求', (tester) async {
    await pumpEat(
      tester,
      SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: [
                EatChip.choice('主食', selected: true, onTap: () {}),
                EatChip.choice('小吃', selected: false, onTap: () {}),
                EatChip.tag('平价', selected: true, onTap: () {}),
                EatChip.tag('量大', selected: false, onTap: () {}),
                EatChip.add('自己写', onTap: () {}),
              ],
            ),
            EatTabs(
              tabs: const [EatTabItem('今日推荐'), EatTabItem('主食')],
              selected: 0,
              onSelected: (_) {},
            ),
            EatRadioRow(title: '广告', selected: true, onSelected: () {}),
            EatSwitch(label: '赞和收藏', value: false, onChanged: (_) {}),
          ],
        ),
      ),
    );

    await expectAccessible(tester);
  });
}
