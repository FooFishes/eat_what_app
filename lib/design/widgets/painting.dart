/// 设计规范里 Flutter 没有现成画法的三样东西：CSS 的内阴影、虚线描边和键盘焦点的双环。
///
/// 三者都按 `ShapeBorder` 的轮廓画，同一套代码给胶囊、圆和圆角矩形用。
library;

import 'package:flutter/rendering.dart';

/// 按 CSS `box-shadow: inset` 的规则画内阴影。
///
/// 每条阴影是「形状」减去「收缩 [BoxShadow.spreadRadius]、平移 [BoxShadow.offset] 后的形状」，
/// 只画在形状里面：`inset 0 1px 0` 是顶边一道 1px 的线，`inset 0 0 0 1.5px` 是贴边一圈描边。
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
    // 用 even-odd 填充「形状 + 洞」得到中间那圈，不用 Path.combine：Web（CanvasKit）上
    // 它对这类圆角路径算出的差集是整个形状，内描边会变成实心。
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

/// 沿形状轮廓画虚线，线画在形状里面，和 CSS 的 `border: dashed` 一样不占外面的位置。
///
/// 虚线长度取线宽的 3 倍、间隔取 2 倍，和 Chrome 画 1–2px 虚线边框的观感接近。
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

/// 键盘焦点：贴着形状外面先一圈 2px `paper`，再一圈 2px `ink`，深浅舞台上都看得见。
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
