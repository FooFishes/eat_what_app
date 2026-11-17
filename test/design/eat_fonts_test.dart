import 'package:eat/design/theme/eat_text_styles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('只有安卓 App 用内置的中文字体', () {
    expect(
      EatFonts.sansFor(TargetPlatform.android, isWeb: false),
      EatFonts.bundledSans,
    );
    expect(EatFonts.sansFor(TargetPlatform.iOS, isWeb: false), isNull);
  });

  test('Web 上即使是安卓浏览器也不用内置的中文字体', () {
    expect(EatFonts.sansFor(TargetPlatform.android, isWeb: true), isNull);
    expect(EatFonts.sansFor(TargetPlatform.iOS, isWeb: true), isNull);
  });
}
