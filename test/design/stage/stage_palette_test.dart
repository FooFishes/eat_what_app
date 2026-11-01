import 'dart:io';

import 'package:eat/design/stage/stage_palette.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 5 张实拍示例图的预期舞台色, 与设计快照中为这几张图配的舞台色一致.
  const expected = {
    'sq_luosi': StageColor.soy,
    'sq_tieguo': StageColor.soy,
    'sq_hongshao': StageColor.soy,
    'sq_niandou': StageColor.broth,
    'sq_paigu': StageColor.bamboo,
  };

  for (final MapEntry(key: name, value: stage) in expected.entries) {
    testWidgets('$name 取色为 ${stage.name}', (tester) async {
      final bytes = File('test/fixtures/photos/$name.png').readAsBytesSync();
      final result = (await tester.runAsync(() => StagePalette.sample(bytes)))!
          .suggest();
      expect(result.reliable, isTrue);
      expect(result.top3(StageColor.broth).first, stage);
    });
  }

  test('太灰时第一个换成分类默认色，后两个取排序里的前两个', () {
    const suggestion = StageSuggestion(
      ranked: [StageColor.soy, StageColor.redoil, StageColor.chili],
      reliable: false,
    );
    expect(suggestion.top3(StageColor.matcha), [
      StageColor.matcha,
      StageColor.soy,
      StageColor.redoil,
    ]);
  });
}
