import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/eat_test_app.dart';

double _sink(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(EatButton),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.transform!.getTranslation().y;
}

Color _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

void main() {
  testWidgets('点了调用 onPressed，按住时整体下沉 1px', (tester) async {
    var taps = 0;
    await pumpEat(tester, EatButton.solid('就它了', onPressed: () => taps++));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(EatButton)),
    );
    await tester.pumpAndSettle();
    expect(_sink(tester), 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_sink(tester), 0);
    expect(taps, 1);
  });

  testWidgets('补充入口按下也下沉，不可用的按钮不下沉', (tester) async {
    await pumpEat(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EatButton.add('新建一家店', onPressed: () {}),
          const EatButton.solid('账号密码登录', onPressed: null),
        ],
      ),
    );

    for (final (label, sink) in [('新建一家店', 1.0), ('账号密码登录', 0.0)]) {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(label)),
      );
      await tester.pumpAndSettle();
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(container.transform!.getTranslation().y, sink, reason: label);
      await gesture.up();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('不可用时点了没反应，读屏报不可用', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpEat(tester, const EatButton.solid('发布', onPressed: null));

    await tester.tap(find.byType(EatButton), warnIfMissed: false);
    expect(
      tester.getSemantics(find.byType(EatButton)),
      matchesSemantics(
        label: '发布',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        isFocusable: false,
      ),
    );
    expect(_labelColor(tester, '发布'), EatPalette.disabledFg);
    semantics.dispose();
  });

  testWidgets('键盘 Tab 聚焦后按回车等于点击', (tester) async {
    var taps = 0;
    await pumpEat(tester, EatButton.mist('换一个', onPressed: () => taps++));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('舞台按钮跟着舞台色：浅色舞台 ink 底舞台色字，深色舞台白底舞台色字', (tester) async {
    for (final stage in [StageColor.mango, StageColor.soy]) {
      await pumpEat(
        tester,
        Row(
          children: [
            Expanded(child: EatButton.stageGhost('换一个', onPressed: () {})),
            Expanded(child: EatButton.stageSolid('就它了', onPressed: () {})),
          ],
        ),
        stage: stage,
        disableAnimations: true,
      );
      await tester.pumpAndSettle();

      expect(_labelColor(tester, '就它了'), stage.color, reason: stage.token);
      expect(_labelColor(tester, '换一个'), stage.foreground, reason: stage.token);
    }
  });

  testWidgets('36px 的小按钮点击区域仍是 44px', (tester) async {
    await pumpEat(tester, EatButton.mist('回关', height: 36, onPressed: () {}));

    expect(tester.getSize(find.byType(EatButton)).height, 44);
  });

  testWidgets('提交中：转圈盖住文字，宽度不变，不变灰，点了没反应', (tester) async {
    var taps = 0;
    Widget button({required bool loading}) => Center(
      child: EatButton.solid('登录', loading: loading, onPressed: () => taps++),
    );
    await pumpEat(tester, button(loading: false));
    final width = tester.getSize(find.byType(EatButton)).width;

    await pumpEat(tester, button(loading: true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byType(EatButton)).width, width);
    expect(_labelColor(tester, '登录'), EatPalette.paper);
    await tester.tap(find.byType(EatButton));
    expect(taps, 0);
  });

  testWidgets('muted：样子和不可用一样、按下不下沉，点了照样响应', (tester) async {
    var taps = 0;
    await pumpEat(
      tester,
      EatButton.solid('手机号登录', muted: true, onPressed: () => taps++),
    );

    expect(_labelColor(tester, '手机号登录'), EatPalette.disabledFg);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(EatButton)),
    );
    await tester.pumpAndSettle();
    expect(_sink(tester), 0);
    await gesture.up();
    expect(taps, 1);
  });

  testWidgets('各种按钮满足点击区域和说明要求', (tester) async {
    await pumpEat(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          EatButton.solid('加一道菜', onPressed: () {}),
          EatButton.outline('导航去店里', icon: EatIcons.navigate, onPressed: () {}),
          EatButton.mist('换一个', onPressed: () {}),
          EatButton.add('新建一家店', onPressed: () {}),
          EatButton.mist('回关', height: 36, onPressed: () {}),
        ],
      ),
    );

    await expectAccessible(tester);
  });
}
