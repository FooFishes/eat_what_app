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
}
