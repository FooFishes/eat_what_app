import 'package:eat/design/theme/eat_colors.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('context.eat 取的是 ThemeData 上挂的 EatTheme', (tester) async {
    final custom = EatTheme.light.copyWith(
      colors: const EatColors(
        ink: Color(0xFF000001),
        inkMuted: Color(0xFF000002),
        inkSoft: Color(0xFF000003),
        paper: Color(0xFFFFFFFF),
        mist: Color(0xFF000004),
        inkTop: Color(0xFF000005),
        tagSelected: Color(0xFF000008),
        hairline: Color(0xFF000009),
        handle: Color(0xFF00000A),
        scrim: Color(0xFF00000B),
        lineStrong: Color(0xFF00000C),
        disabledBg: Color(0xFF00000D),
        disabledFg: Color(0xFF00000E),
        warn: Color(0xFF00000F),
        mapMe: Color(0xFF000010),
        mapGround: Color(0xFF000011),
        mapBlock: Color(0xFF000012),
        mapPark: Color(0xFF000013),
        cropGround: Color(0xFF000014),
        cropPanel: Color(0xFF000015),
        cropScrim: Color(0xFF000016),
      ),
    );
    late EatTheme seen;
    await tester.pumpWidget(
      Theme(
        data: ThemeData(extensions: [custom]),
        child: Builder(
          builder: (context) {
            seen = context.eat;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(seen.colors.ink, const Color(0xFF000001));
  });

  testWidgets('没挂 EatTheme 时退回浅色主题', (tester) async {
    late EatTheme seen;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = context.eat;
          return const SizedBox();
        },
      ),
    );

    expect(seen, same(EatTheme.light));
  });
}
