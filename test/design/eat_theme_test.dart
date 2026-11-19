import 'package:eat/design/theme/eat_colors.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

void main() {
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

  test('eatThemeData 按深浅挂上对应的令牌', () {
    final light = eatThemeData();
    final dark = eatThemeData(Brightness.dark);

    expect(light.brightness, Brightness.light);
    expect(light.extension<EatTheme>(), same(EatTheme.light));
    expect(dark.brightness, Brightness.dark);
    expect(dark.extension<EatTheme>(), same(EatTheme.dark));
    expect(dark.scaffoldBackgroundColor, EatColors.dark.paper);
    expect(dark.colorScheme.primary, EatColors.dark.ink);
  });

  testWidgets('跟随系统: 系统切到深色时取深色令牌', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    late EatTheme seen;
    final app = MaterialApp(
      theme: eatThemeData(),
      darkTheme: eatThemeData(Brightness.dark),
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          seen = context.eat;
          return const SizedBox();
        },
      ),
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(app);
    expect(seen.colors, same(EatColors.light));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(seen.colors, same(EatColors.dark));
  });

  test('地图和调整照片页的颜色不分深浅', () {
    const l = EatColors.light;
    const d = EatColors.dark;
    expect(d.mapGround, l.mapGround);
    expect(d.mapMe, l.mapMe);
    expect(d.cropGround, l.cropGround);
    expect(d.cropPanel, l.cropPanel);
    expect(d.white, l.white);
    expect(d.shade, l.shade);
  });

  for (final colors in [EatColors.light, EatColors.dark]) {
    final name = colors.isDark ? '深色' : '浅色';

    test('$name: 文字和底色的对比度不低于 4.5:1', () {
      final pairs = {
        'ink / paper': (colors.ink, colors.paper),
        'inkMuted / paper': (colors.inkMuted, colors.paper),
        'inkSoft / paper': (colors.inkSoft, colors.paper),
        'warn / paper': (colors.warn, colors.paper),
        'ink / mist': (colors.ink, colors.mist),
        'ink / tagSelected': (colors.ink, colors.tagSelected),
        'paper / ink': (colors.paper, colors.ink),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        expect(
          _contrast(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$name $label',
        );
      }
    });
  }

  test('深色: 分类栏记号笔 (舞台色 40%) 上的 ink 不低于 4.5:1', () {
    const c = EatColors.dark;
    for (final stage in StageColor.values) {
      final marker = Color.alphaBlend(
        stage.darkColor.withValues(alpha: 0.4),
        c.paper,
      );
      expect(
        _contrast(c.ink, marker),
        greaterThanOrEqualTo(4.5),
        reason: stage.token,
      );
    }
  });
}
