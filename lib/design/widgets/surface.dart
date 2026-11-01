import 'package:eat/design/widgets/painting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 组件的底: 上下两色的纵向渐变 (两色相同即纯色), 外阴影, 内阴影和可选的虚线描边.
///
/// 实线描边也用内阴影表示, `spreadRadius` 即线宽.
/// 这样描边颜色能与底色和阴影一起插值, 按下和选中时整体平滑过渡.
@immutable
class const SurfaceStyle({
  required final Color top,
  required final Color bottom,
  final List<BoxShadow> outer = const [],
  final List<BoxShadow> inset = const [],
  final Color? dashColor,
  final double dashWidth = 1.5,
}) {
  const SurfaceStyle.flat(Color color, {List<BoxShadow> inset = const []})
    : this(top: color, bottom: color, inset: inset);

  /// 只有虚线描边, 没有底色和厚度.
  const SurfaceStyle.dashed(Color color, {double width = 1.5})
    : this(
        top: const Color(0x00000000),
        bottom: const Color(0x00000000),
        dashColor: color,
        dashWidth: width,
      );

  static SurfaceStyle lerp(SurfaceStyle a, SurfaceStyle b, double t) =>
      SurfaceStyle(
        top: Color.lerp(a.top, b.top, t)!,
        bottom: Color.lerp(a.bottom, b.bottom, t)!,
        outer: BoxShadow.lerpList(a.outer, b.outer, t) ?? const [],
        inset: BoxShadow.lerpList(a.inset, b.inset, t) ?? const [],
        dashColor: t < 0.5 ? a.dashColor : b.dashColor,
        dashWidth: t < 0.5 ? a.dashWidth : b.dashWidth,
      );

  @override
  bool operator ==(Object other) =>
      other is SurfaceStyle &&
      other.top == top &&
      other.bottom == bottom &&
      listEquals(other.outer, outer) &&
      listEquals(other.inset, inset) &&
      other.dashColor == dashColor &&
      other.dashWidth == dashWidth;

  @override
  int get hashCode => Object.hash(
    top,
    bottom,
    Object.hashAll(outer),
    Object.hashAll(inset),
    dashColor,
    dashWidth,
  );
}

/// 按 [shape] 的轮廓绘制 [style]. [duration] 不为零时, 样式变化平滑过渡.
class Surface extends StatelessWidget {
  const new({
    super.key,
    required this.style,
    this.shape = const StadiumBorder(),
    this.duration = Duration.zero,
    this.curve = Curves.ease,
    this.child,
  });

  final SurfaceStyle style;
  final ShapeBorder shape;
  final Duration duration;
  final Curve curve;
  final Widget? child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<SurfaceStyle>(
    tween: _SurfaceTween(end: style),
    duration: duration,
    curve: curve,
    child: child,
    builder: (context, style, child) =>
        CustomPaint(painter: _SurfacePainter(style, shape), child: child),
  );
}

class _SurfaceTween extends Tween<SurfaceStyle> {
  _SurfaceTween({super.end});

  @override
  SurfaceStyle lerp(double t) => SurfaceStyle.lerp(begin ?? end!, end!, t);
}

class _SurfacePainter extends CustomPainter {
  _SurfacePainter(this.style, this.shape);

  final SurfaceStyle style;
  final ShapeBorder shape;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    for (final shadow in style.outer) {
      canvas.drawPath(
        shape.getOuterPath(
          rect.shift(shadow.offset).inflate(shadow.spreadRadius),
        ),
        shadow.toPaint(),
      );
    }
    if (style.top.a > 0 || style.bottom.a > 0) {
      canvas.drawPath(
        shape.getOuterPath(rect),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [style.top, style.bottom],
          ).createShader(rect),
      );
    }
    paintInsetShadows(canvas, rect, shape, style.inset);
    if (style.dashColor case final color?) {
      paintDashedOutline(canvas, rect, shape, color, style.dashWidth);
    }
  }

  @override
  bool shouldRepaint(_SurfacePainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.shape != shape;
}
