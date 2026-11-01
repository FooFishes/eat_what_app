/// Flutter 没有内置画法的三种设计元素: CSS 内阴影, 虚线描边和键盘焦点双环.
///
/// 三者都按 `ShapeBorder` 的轮廓绘制, 因此同一套代码适用于胶囊, 圆和圆角矩形.
library;

import 'package:flutter/rendering.dart';

/// 按 CSS `box-shadow: inset` 的规则绘制内阴影.
///
/// 每条阴影为原形状减去变换后的形状, 只绘制在原形状内部.
/// 变换为按 [BoxShadow.spreadRadius] 收缩, 再按 [BoxShadow.offset] 平移.
/// 例如 `inset 0 1px 0` 是顶边的 1px 线, `inset 0 0 0 1.5px` 是贴边的描边.
void paintInsetShadows(
  Canvas canvas,
  Rect rect,
  ShapeBorder shape,
  List<BoxShadow> shadows,
) {
  if (shadows.isEmpty) return;
  final outer = shape.getOuterPath(rect);
  canvas.save();
  canvas.clipPath(outer);
  for (final shadow in shadows) {
    // 用 even-odd 填充 "形状 + 洞" 得到环形区域, 不用 Path.combine.
    // Web (CanvasKit) 上 Path.combine 对这类圆角路径算出的差集是整个形状, 内描边会变成实心.
    final hole = shape.getOuterPath(
      rect.deflate(shadow.spreadRadius).shift(shadow.offset),
    );
    final band = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outer, Offset.zero)
      ..addPath(hole, Offset.zero);
    final paint = Paint()..color = shadow.color;
    if (shadow.blurRadius > 0) {
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        Shadow.convertRadiusToSigma(shadow.blurRadius),
      );
    }
    canvas.drawPath(band, paint);
  }
  canvas.restore();
}

/// 沿形状轮廓绘制虚线. 与 CSS `border: dashed` 一致, 虚线位于形状内部, 不占外部空间.
///
/// 虚线长度和间隔按线宽的倍数取值, 与 Chrome 绘制 1–2px 虚线边框的观感接近.
void paintDashedOutline(
  Canvas canvas,
  Rect rect,
  ShapeBorder shape,
  Color color,
  double width,
) {
  final path = shape.getOuterPath(rect.deflate(width / 2));
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;
  final dash = width * 3;
  final gap = width * 2;
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = (distance + dash).clamp(0, metric.length).toDouble();
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance += dash + gap;
    }
  }
}

/// 绘制键盘焦点双环: 紧贴形状外侧先画 `paper` 环, 再画 `ink` 环, 在深浅舞台上都可见.
void paintFocusRing(
  Canvas canvas,
  Rect rect,
  ShapeBorder shape, {
  required Color inner,
  required Color outer,
}) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  canvas.drawPath(shape.getOuterPath(rect.inflate(1)), paint..color = inner);
  canvas.drawPath(shape.getOuterPath(rect.inflate(3)), paint..color = outer);
}
