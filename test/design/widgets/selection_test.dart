import 'dart:ui' show SemanticsAction, Tristate;

import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_radio_row.dart';
import 'package:eat/design/widgets/eat_segment_slider.dart';
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

    testWidgets('放得下时等分整行、字在格里居中，未选中的小一号；记号笔从左往右画到选中项下面', (tester) async {
      var selected = 0;
      await pumpEat(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 360,
            child: EatTabs(
              tabs: const [
                EatTabItem('上传'),
                EatTabItem('收藏'),
                EatTabItem('赞过'),
              ],
              selected: selected,
              onSelected: (i) => setState(() => selected = i),
            ),
          ),
        ),
      );
      final strip = tester.getRect(find.byType(EatTabs));
      final column = strip.width / 3;
      for (final (i, name) in ['上传', '收藏', '赞过'].indexed) {
        expect(
          tester.getCenter(find.text(name)).dx,
          closeTo(strip.left + column * (i + 0.5), 0.5),
          reason: '每项等分一格, 字在格里居中',
        );
      }
      expect(tester.widget<Text>(find.text('上传')).style!.fontSize, 18);
      expect(tester.widget<Text>(find.text('收藏')).style!.fontSize, 15);

      Finder marker(String text) => find.descendant(
        of: find.ancestor(of: find.text(text), matching: find.byType(Stack)),
        matching: find.byType(ClipRect),
      );
      expect(marker('上传'), findsOneWidget);
      expect(marker('收藏'), findsNothing);

      await tester.tap(find.text('收藏'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final drawing = tester.getSize(marker('收藏')).width;
      await tester.pumpAndSettle();
      expect(drawing, lessThan(tester.getSize(marker('收藏')).width));
      expect(marker('上传'), findsNothing);
    });

    testWidgets('等分整行时切换分类，外面的页面不跟着滚', (tester) async {
      var selected = 0;
      final page = ScrollController(initialScrollOffset: 300);
      addTearDown(page.dispose);
      await pumpEat(
        tester,
        SizedBox(
          height: 400,
          child: StatefulBuilder(
            builder: (context, setState) => ListView(
              controller: page,
              children: [
                const SizedBox(height: 500),
                EatTabs(
                  tabs: const [EatTabItem('上传'), EatTabItem('收藏')],
                  selected: selected,
                  onSelected: (i) => setState(() => selected = i),
                ),
                const SizedBox(height: 800),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('收藏'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(page.offset, 300);
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

  group('EatSegmentSlider', () {
    const labels = ['500 m', '1 km', '2 km', '不限'];

    /// 三种造型共用一套操作, 下面的用例每种都跑一遍.
    final looks =
        <
          String,
          (
            double,
            EatSegmentSlider Function(int selected, ValueChanged<int> changed),
          )
        >{
          '胶囊': (
            44,
            (selected, changed) => EatSegmentSlider(
              semanticsLabel: '最远距离',
              labels: labels,
              selected: selected,
              onChanged: changed,
            ),
          ),
          '路线': (
            76,
            (selected, changed) => EatSegmentSlider.route(
              semanticsLabel: '最远距离',
              labels: labels,
              selected: selected,
              onChanged: changed,
            ),
          ),
          '硬币': (
            76,
            (selected, changed) => EatSegmentSlider.coins(
              semanticsLabel: '最远距离',
              labels: labels,
              allIndex: 3,
              selected: selected,
              onChanged: changed,
            ),
          ),
        };

    Future<List<int>> pumpSlider(
      WidgetTester tester,
      EatSegmentSlider Function(int, ValueChanged<int>) build, {
      int selected = 0,
    }) async {
      final picked = <int>[];
      await pumpEat(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 320,
            child: build(
              selected,
              (i) => setState(() {
                selected = i;
                picked.add(i);
              }),
            ),
          ),
        ),
      );
      return picked;
    }

    /// 选中的那段的文字: 胶囊造型是滑块上的字, 另外两种是下面那行里加粗的字, 都是 600 字重.
    String current(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .firstWhere((t) => t.style?.fontWeight == FontWeight.w600)
        .data!;

    for (final MapEntry(key: name, value: (height, build)) in looks.entries) {
      testWidgets('$name: 点哪段选哪段, 高 ${height.toInt()}px', (tester) async {
        final picked = await pumpSlider(tester, build);

        expect(tester.getSize(find.byType(EatSegmentSlider)).height, height);
        await tester.tap(find.text('2 km').last);
        await tester.pumpAndSettle();
        expect(picked, [2]);
        expect(current(tester), '2 km');
      });

      testWidgets('$name: 拖动时跟手, 松手吸附到最近一段, 只回调一次', (tester) async {
        final picked = await pumpSlider(tester, build);
        final rect = tester.getRect(find.byType(EatSegmentSlider));
        final segment = rect.width / labels.length;

        final gesture = await tester.startGesture(
          rect.centerLeft + Offset(segment / 2, 0),
        );
        await gesture.moveBy(const Offset(20, 0));
        await gesture.moveBy(Offset(segment * 2.2 - 20, 0));
        await tester.pump();
        expect(picked, isEmpty, reason: '拖动中不回调');
        expect(current(tester), '2 km');
        await gesture.up();
        await tester.pumpAndSettle();
        expect(picked, [2]);
      });
    }

    testWidgets('读屏当作滑块, 能加一段减一段', (tester) async {
      final semantics = tester.ensureSemantics();
      final picked = await pumpSlider(tester, looks['路线']!.$2, selected: 1);

      final node = tester.getSemantics(find.byType(EatSegmentSlider));
      expect(node.label, '最远距离');
      expect(node.value, '1 km');
      expect(node.increasedValue, '2 km');
      expect(node.decreasedValue, '500 m');
      tester.semantics.performAction(
        find.semantics.byLabel('最远距离'),
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      expect(picked, [2]);
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

  testWidgets('分类、标签、单选行、开关和分段条满足点击区域和说明要求', (tester) async {
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
            EatSegmentSlider.coins(
              semanticsLabel: '人均价位',
              labels: const ['¥ 15 以下', '¥ 15–30', '¥ 30 以上', '不限'],
              allIndex: 3,
              selected: 2,
              onChanged: (_) {},
            ),
            EatSegmentSlider.route(
              semanticsLabel: '最远距离',
              labels: const ['500 m', '1 km', '不限'],
              selected: 1,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );

    await expectAccessible(tester);
  });
}
