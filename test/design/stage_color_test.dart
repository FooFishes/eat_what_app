import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 对比度. 半透明的前景色先与背景色混合, 再计算对比度.
double contrast(Color foreground, Color background) {
  final a = Color.alphaBlend(foreground, background).computeLuminance();
  final b = background.computeLuminance();
  return (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
}

void main() {
  test('深浅和设计规范一致：tomato、redoil、soy 是深色舞台', () {
    expect(StageColor.values.where((s) => s.isDark), [
      StageColor.tomato,
      StageColor.redoil,
      StageColor.soy,
    ]);
  });

  for (final stage in StageColor.values) {
    test('${stage.token} 上的主文字和次级文字不低于 4.5:1', () {
      expect(
        contrast(stage.foreground, stage.color),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(stage.secondaryForeground, stage.color),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  test('浅色舞台用 ink 系文字和 ink 实心按钮，深色舞台用 paper', () {
    for (final stage in StageColor.values) {
      expect(
        stage.foreground,
        stage.isDark ? EatPalette.paper : EatPalette.ink,
      );
      expect(
        stage.ghost,
        stage.isDark ? EatPalette.stageGhostDark : EatPalette.stageGhostLight,
      );
      expect(
        (stage.solidTop, stage.solidBottom),
        stage.isDark
            ? (EatPalette.paper, EatPalette.paperBottom)
            : (EatPalette.inkTop, EatPalette.ink),
      );
    }
  });

  test('令牌名和枚举互相转换', () {
    for (final stage in StageColor.values) {
      expect(StageColor.fromToken(stage.token), stage);
    }
    expect(StageColor.broth.token, 'stage-broth');
    expect(StageColor.fromToken('stage-unknown'), isNull);
  });
}
