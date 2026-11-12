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

  test('舞台菜名：三行时 36，有一行排满四个字时 40，否则 44', () {
    final layout = _layout(390, 844);
    expect(layout.stageNameSize(['螺蛳粉', '加炸蛋']), 44);
    expect(layout.stageNameSize(['芒果班戟']), 40);
    expect(layout.stageNameSize(['鲜虾蟹籽', '云吞']), 40);
    expect(layout.stageNameSize(['老坛酸菜', '牛肉手擀', '宽面加蛋']), 36);
    expect(
      _layout(320, 640).stageNameSize(['螺蛳粉']),
      closeTo(44 * 320 / 360, 1e-9),
    );
  });

  test('窄手机按宽度缩小舞台字号', () {
    expect(_layout(320, 640).widthClass, WidthClass.narrow);
    expect(_layout(320, 640).stageTextScale, closeTo(320 / 360, 1e-9));
    expect(_layout(390, 844).stageTextScale, 1);
  });
}
