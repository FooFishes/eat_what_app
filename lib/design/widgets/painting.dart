/// 提供 Flutter 未内置的三种设计绘制能力: CSS 内阴影, 虚线描边和键盘焦点双环.
///
/// 三者均基于 `ShapeBorder` 的轮廓绘制, 因此同一套实现可通用于胶囊, 圆形和圆角矩形.
library;

import 'package:flutter/rendering.dart';

/// 按 CSS `box-shadow: inset` 规则绘制内阴影.
///
/// 每条阴影通过原形状减去变换后形状的差集绘制在原形状内部; 变换先按 [BoxShadow.spreadRadius] 收缩, 再按 [BoxShadow.offset] 平移.
/// 例如 `inset 0 1px 0` 绘制为顶边 1px 线, `inset 0 0 0 1.5px` 绘制为贴边内描边.
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
    // 采用 even-odd 填充 "外框 + 内部镂空" 得到环形区域而不使用 Path.combine,
    // 避免在 Web (CanvasKit) 上对圆角路径求差集时误算为整个实心形状.
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

/// 沿形状轮廓内侧绘制虚线描边, 与 CSS `border: dashed` 一致且不占用外部空间.
///
/// 虚线线段与间隔按线宽的倍数取值, 观感接近 Chrome 对 1–2px 虚线边框的渲染效果.
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

/// 绘制键盘焦点双环: 紧贴形状外侧先绘 `paper` 内环再绘 `ink` 外环, 确保在深浅舞台上均清晰可见.
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
