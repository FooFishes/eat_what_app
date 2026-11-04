import 'package:eat/design/layout/eat_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

EatLayout _layout(double width, double height) => EatLayout(
  widthClass: width >= EatLayout.wideBreakpoint
      ? WidthClass.wide
      : width < EatLayout.narrowBreakpoint
      ? WidthClass.narrow
      : WidthClass.phone,
  screen: Size(width, height),
);

void main() {
  test('宽屏的舞台铺满屏幕；白底页面挤到居中一栏', () {
    final wide = _layout(1280, 800);
    expect(wide.isWide, isTrue);
    expect(wide.stageHeight, 800);
    expect(wide.plainHorizontalPadding, (1280 - 480) / 2 + 20);
    expect(_layout(390, 844).plainHorizontalPadding, 20);
  });

  test('窄手机按宽度缩小舞台字号', () {
    expect(_layout(320, 640).widthClass, WidthClass.narrow);
    expect(_layout(320, 640).stageTextScale, closeTo(320 / 360, 1e-9));
    expect(_layout(390, 844).stageTextScale, 1);
  });
}
