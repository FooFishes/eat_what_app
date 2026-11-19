import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

void main() {
  test('深浅和设计规范一致：tomato、redoil、soy 是深色舞台', () {
    expect(StageColor.values.where((s) => s.isDark), [
      StageColor.tomato,
      StageColor.redoil,
      StageColor.soy,
    ]);
  });

  for (final dark in [false, true]) {
    final name = dark ? '深色模式' : '浅色模式';

    test('$name: 每个舞台色上的主文字和次级文字都不低于 4.5:1', () {
      for (final stage in StageColor.values) {
        final palette = StagePalette.of(stage, dark: dark);
        final secondary = Color.alphaBlend(
          palette.secondaryForeground,
          palette.background,
        );
        expect(
          _contrast(palette.foreground, palette.background),
          greaterThanOrEqualTo(4.5),
          reason: '$name ${stage.token} 主文字',
        );
        expect(
          _contrast(secondary, palette.background),
          greaterThanOrEqualTo(4.5),
          reason: '$name ${stage.token} 次级文字',
        );
      }
    });
  }

  test('深色模式的舞台色不比浅色亮, 实心按钮的字跟着底色走', () {
    for (final stage in StageColor.values) {
      expect(
        stage.darkColor.computeLuminance(),
        lessThanOrEqualTo(stage.color.computeLuminance()),
        reason: stage.token,
      );
      final palette = StagePalette.of(stage, dark: true);
      expect(palette.background, stage.darkColor);
      expect(palette.solidForeground, stage.darkColor);
    }
  });
}
