import 'dart:ui' show Tristate;

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_nav_bar.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_radio_row.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/eat_stage.dart';
import 'package:eat/design/widgets/fact_list.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/eat_test_app.dart';

void main() {
  group('EatStage', () {
    StagePalette palette(WidgetTester tester) =>
        StageTheme.of(tester.element(find.byKey(const Key('probe'))));

    Widget stage(StageColor color) => SizedBox(
      width: 390,
      height: 300,
      child: EatStage(
        stage: color,
        child: const Text('鲜虾蟹籽云吞', key: Key('probe')),
      ),
    );

    testWidgets('文字默认用舞台文字色，深色舞台状态栏用浅色图标', (tester) async {
      await pumpEat(tester, stage(StageColor.soy));
      await tester.pumpAndSettle();

      expect(palette(tester).background, StageColor.soy.color);
      expect(
        DefaultTextStyle.of(tester.element(find.byKey(const Key('probe'))))
            .style
            .color,
        EatPalette.paper,
      );
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(region.value, SystemUiOverlayStyle.light);
    });

    testWidgets('换舞台色时 500ms 一起过渡', (tester) async {
      await pumpEat(tester, stage(StageColor.broth));
      await tester.pumpAndSettle();
      await pumpEat(tester, stage(StageColor.redoil));

      await tester.pump(const Duration(milliseconds: 250));
      final halfway = palette(tester).background;
      expect(halfway, isNot(StageColor.broth.color));
      expect(halfway, isNot(StageColor.redoil.color));

      await tester.pump(const Duration(milliseconds: 260));
      expect(palette(tester).background, StageColor.redoil.color);
    });

    testWidgets('减少动态效果时直接换色', (tester) async {
      await pumpEat(tester, stage(StageColor.broth), disableAnimations: true);
      await pumpEat(tester, stage(StageColor.redoil), disableAnimations: true);
      await tester.pump();

      expect(palette(tester).background, StageColor.redoil.color);
    });
  });

  testWidgets('抽屉只有压在地图上才有阴影', (tester) async {
    BoxDecoration decoration() =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(EatSheet),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;

    await pumpEat(tester, const EatSheet(child: Text('今日推荐')));
    expect(decoration().boxShadow, isNull);
    expect(find.byType(SheetHandle), findsOneWidget);

    await pumpEat(tester, const EatSheet(onMap: true, child: Text('附近')));
    expect(decoration().boxShadow, isNotEmpty);
  });

  group('面板', () {
    Future<void> open(WidgetTester tester, WidgetBuilder builder) async {
      await pumpEat(
        tester,
        Builder(
          builder: (context) => EatButton.solid(
            '举报',
            onPressed: () => showPanel<void>(context, builder: builder),
          ),
        ),
      );
      await tester.tap(find.text('举报'));
      await tester.pumpAndSettle();
    }

    testWidgets('点关闭或点遮罩都收起面板', (tester) async {
      Widget panel(BuildContext context) => EatPanel(
        title: '举报这道菜',
        actions: EatButton.solid('提交', onPressed: () {}),
        child: EatRadioRow(title: '广告', selected: true, onSelected: () {}),
      );

      await open(tester, panel);
      expect(find.text('举报这道菜'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('关闭'));
      await tester.pumpAndSettle();
      expect(find.text('举报这道菜'), findsNothing);

      await open(tester, panel);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('举报这道菜'), findsNothing);
    });

    testWidgets('提示类面板左边是圆底图标，没有关闭按钮', (tester) async {
      await open(
        tester,
        (context) => EatPanel(
          icon: EatIcons.block,
          title: '暂时不能发布',
          actions: EatButton.solid('知道了', onPressed: () {}),
          child: const FactList([
            (label: '原因', value: '多次发布和菜无关的图片', strong: false),
            (label: '恢复', value: '10 月 25 日 12:00', strong: true),
          ]),
        ),
      );

      expect(find.text('暂时不能发布'), findsOneWidget);
      expect(find.bySemanticsLabel('关闭'), findsNothing);
      expect(find.text('恢复'), findsOneWidget);
      await expectAccessible(tester);
    });

    testWidgets('内容再多，面板也不超过屏幕的 85%', (tester) async {
      await open(
        tester,
        (context) => EatPanel(
          title: '选店',
          child: Column(
            children: [
              for (var i = 0; i < 40; i++)
                EatRadioRow(
                  title: '第 $i 家',
                  selected: i == 0,
                  onSelected: () {},
                ),
            ],
          ),
        ),
      );

      final screen = tester.getSize(find.byType(Scaffold).first).height;
      expect(
        tester.getSize(find.byType(EatPanel)).height,
        lessThanOrEqualTo(screen * 0.85),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('对话框', () {
    Future<void> open(
      WidgetTester tester,
      WidgetBuilder builder, {
      ValueSetter<Object?>? onResult,
    }) async {
      await pumpEat(
        tester,
        Builder(
          builder: (context) => EatButton.solid(
            '删除',
            onPressed: () async {
              final result = await showEatDialog<bool>(
                context,
                builder: builder,
              );
              onResult?.call(result);
            },
          ),
        ),
      );
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
    }

    Widget confirm(BuildContext context) => EatDialog(
      title: '删除这条评论？',
      subtitle: '删除后不能恢复。',
      actions: Row(
        children: [
          Expanded(
            child: EatButton.mist(
              '先不删',
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          Expanded(
            child: EatButton.solid(
              '删掉',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    );

    testWidgets('居中显示，不超过最大宽度，按钮小一号并返回结果', (tester) async {
      final results = <Object?>[];
      await open(tester, confirm, onResult: results.add);

      final screen = tester.getSize(find.byType(Scaffold).first);
      final rect = tester.getRect(find.byType(Material).last);
      expect(rect.width, lessThanOrEqualTo(EatDialog.maxWidth));
      expect(rect.center.dx, closeTo(screen.width / 2, 1));
      expect(rect.center.dy, closeTo(screen.height / 2, 1));
      expect(find.bySemanticsLabel('关闭'), findsNothing);
      expect(
        tester.getSize(find.widgetWithText(EatButton, '删掉')).height,
        EatSize.dialogButton,
      );
      await expectAccessible(tester);

      await tester.tap(find.text('删掉'));
      await tester.pumpAndSettle();
      expect(find.text('删除这条评论？'), findsNothing);
      expect(results, [true]);
    });

    testWidgets('点遮罩关闭，结果为空', (tester) async {
      final results = <Object?>[];
      await open(tester, confirm, onResult: results.add);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('删除这条评论？'), findsNothing);
      expect(results, [null]);
    });

    testWidgets('减少动态效果时没有进场动画', (tester) async {
      await pumpEat(
        tester,
        Builder(
          builder: (context) => EatButton.solid(
            '删除',
            onPressed: () => showEatDialog<void>(context, builder: confirm),
          ),
        ),
        disableAnimations: true,
      );
      await tester.tap(find.text('删除'));
      await tester.pump();
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('删除这条评论？'), findsOneWidget);
    });

    testWidgets('提示类对话框上方是圆底图标，信息行左右对齐', (tester) async {
      await open(
        tester,
        (context) => EatDialog(
          icon: EatIcons.block,
          title: '账号封禁中，暂时不能评论',
          actions: EatButton.solid('知道了', onPressed: () {}),
          child: const FactList([
            (label: '原因', value: '多次发布和菜无关的图片', strong: false),
            (label: '期限', value: '永久封禁', strong: false),
          ]),
        ),
      );

      expect(
        tester.getTopLeft(find.byType(EatIcon)).dy,
        lessThan(tester.getTopLeft(find.text('账号封禁中，暂时不能评论')).dy),
      );
      expect(find.text('永久封禁'), findsOneWidget);
      await expectAccessible(tester);
    });
  });

  group('EatNavBar', () {
    testWidgets('三个标签读作按钮，当前项是选中的；发布按钮有说明', (tester) async {
      final picked = <int>[];
      var published = 0;
      await pumpEat(
        tester,
        SizedBox(
          width: 358,
          child: EatNavBar(
            currentIndex: 0,
            onSelected: picked.add,
            onPublish: () => published++,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('附近'));
      await tester.tap(find.bySemanticsLabel('发布一道菜'));
      expect(picked, [1]);
      expect(published, 1);
      expect(tester.getSize(find.byType(EatNavBar)).height, 60);

      final selected = tester
          .getSemantics(find.bySemanticsLabel('发现'))
          .getSemanticsData()
          .flagsCollection
          .isSelected;
      expect(selected, Tristate.isTrue);
      await expectAccessible(tester);
    });

    testWidgets('从导航上开始的上下滑动不切换标签，点一下照常切换', (tester) async {
      final picked = <int>[];
      await pumpEat(
        tester,
        SizedBox(
          width: 358,
          child: EatNavBar(
            currentIndex: 0,
            onSelected: picked.add,
            onPublish: () {},
          ),
        ),
      );

      await tester.drag(find.bySemanticsLabel('附近'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(picked, isEmpty, reason: '往上滑是想滚动页面, 不是点「附近」');

      await tester.tap(find.bySemanticsLabel('我的'));
      await tester.pumpAndSettle();
      expect(picked, [2]);
    });
  });
}
