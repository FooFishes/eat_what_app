import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('深浅和设计规范一致：tomato、redoil、soy 是深色舞台', () {
    expect(StageColor.values.where((s) => s.isDark), [
      StageColor.tomato,
      StageColor.redoil,
      StageColor.soy,
    ]);
  });

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
}
