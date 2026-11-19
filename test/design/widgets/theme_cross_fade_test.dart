import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/widgets/theme_cross_fade.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/eat_test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, {bool disableAnimations = false}) =>
      pumpEat(
        tester,
        const ThemeCrossFade(
          followsSystem: true,
          child: SizedBox(width: 100, height: 100, child: Text('页面')),
        ),
        disableAnimations: disableAnimations,
      );

  testWidgets('换主题前截图盖在上面，淡出后拿掉，盖着时不挡点击', (tester) async {
    await pump(tester);

    ThemeCrossFade.capture(tester.element(find.text('页面')));
    await tester.pump();
    expect(find.byType(RawImage), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(RawImage),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );

    await tester.pump(EatMotion.themeSwitch.duration ~/ 2);
    expect(find.byType(RawImage), findsOneWidget, reason: '淡出途中还在');
    await tester.pumpAndSettle();
    expect(find.byType(RawImage), findsNothing);
  });

  testWidgets('减少动态效果时不截图，直接换', (tester) async {
    await pump(tester, disableAnimations: true);

    ThemeCrossFade.capture(tester.element(find.text('页面')));
    await tester.pump();
    expect(find.byType(RawImage), findsNothing);
  });
}
