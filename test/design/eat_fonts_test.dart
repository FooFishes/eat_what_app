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

  test('预设字重均低于 800，避免在 iOS 苹方上触发假粗体', () {
    final t = EatTextStyles.standard;
    final styles = [
      t.display,
      t.stage,
      t.title,
      t.heading,
      t.subhead,
      t.body,
      t.meta,
      t.caption,
      t.priceHero,
      t.stat,
      t.priceInline,
      t.count,
    ];
    expect(EatTextStyles.heavyWeight.value, lessThan(800));
    expect(EatTextStyles.heavyWeight.value, greaterThan(700));
    for (final style in styles) {
      expect(style.fontWeight!.value, lessThan(800));
    }
  });
}
