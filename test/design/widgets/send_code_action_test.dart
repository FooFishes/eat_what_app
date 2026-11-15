import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/send_code_action.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/eat_test_app.dart';

Color _labelColor(WidgetTester tester) =>
    tester.widget<Text>(find.text(SendCodeAction.label)).style!.color!;

void main() {
  testWidgets('文字按钮不带胶囊底，点击区域高 44px', (tester) async {
    var taps = 0;
    await pumpEat(
      tester,
      Center(child: SendCodeAction(secondsLeft: 0, onPressed: () => taps++)),
    );

    expect(find.byType(Surface), findsNothing);
    expect(_labelColor(tester), EatPalette.ink);
    expect(tester.getSize(find.byType(SendCodeAction)).height, EatSize.touch);

    await tester.tap(find.text(SendCodeAction.label));
    expect(taps, 1);
  });

  testWidgets('不可用时文字变灰', (tester) async {
    await pumpEat(
      tester,
      const Center(child: SendCodeAction(secondsLeft: 0, onPressed: null)),
    );

    expect(_labelColor(tester), EatPalette.disabledFg);
  });

  testWidgets('发送中显示进度圈，不响应点击', (tester) async {
    var taps = 0;
    await pumpEat(
      tester,
      Center(
        child: SendCodeAction(
          secondsLeft: 0,
          sending: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(SendCodeAction));
    expect(taps, 0);
  });

  testWidgets('倒计时中显示剩余秒数', (tester) async {
    await pumpEat(
      tester,
      Center(child: SendCodeAction(secondsLeft: 42, onPressed: () {})),
    );

    expect(find.text(SendCodeAction.label), findsNothing);
    expect(find.textContaining('秒后重发', findRichText: true), findsOneWidget);
  });
}
