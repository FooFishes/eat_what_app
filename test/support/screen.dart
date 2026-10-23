import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 把测试窗口设成 [size]（逻辑像素），测试结束时复原。
void useScreen(
  WidgetTester tester,
  Size size, {
  EdgeInsets padding = EdgeInsets.zero,
}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  tester.view.padding = FakeViewPadding(
    left: padding.left * 3,
    top: padding.top * 3,
    right: padding.right * 3,
    bottom: padding.bottom * 3,
  );
  addTearDown(tester.view.reset);
}
