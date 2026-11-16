import 'dart:math' as math;

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:material_ui/material_ui.dart';

/// 照片上的圆形取景区域.
///
/// [centerX] 和 [centerY] 是圆心按照片宽高归一化到 0–1 的位置, [diameter] 是直径占照片短边的比例.
typedef CircleCrop = ({double centerX, double centerY, double diameter});

/// 取景圈直径占照片短边比例的下限, 决定最大放大倍数.
const minCropDiameter = 0.25;

/// 把取景限制在照片范围内, 将直径限制在 [minCropDiameter] 到 1 之间并确保取景圈不超出照片边缘.
CircleCrop clampCircleCrop(
  CircleCrop crop, {
  required int width,
  required int height,
}) {
  final diameter = crop.diameter.clamp(minCropDiameter, 1.0);
  final short = math.min(width, height).toDouble();
  final rx = diameter * short / 2 / width;
  final ry = diameter * short / 2 / height;
  return (
    centerX: crop.centerX.clamp(rx, 1 - rx),
    centerY: crop.centerY.clamp(ry, 1 - ry),
    diameter: diameter,
  );
}

/// 圆形取景器组件, 支持拖动移动照片和双指缩放. 照片位于取景圈下方, 圈外覆盖 `crop-scrim`.
///
/// 用于深色全屏的 "调整照片" 和换头像页. [onChanged] 收到的取景结果已经过 [clampCircleCrop] 限制.
class CropViewport extends StatefulWidget {
  const new({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    required this.crop,
    required this.onChanged,
  });

  final ImageProvider image;

  /// 照片的像素宽度; [height] 为像素高度.
  final int width;
  final int height;
  final CircleCrop crop;
  final ValueChanged<CircleCrop> onChanged;

  @override
  State<CropViewport> createState() => _CropViewportState();
}

class _CropViewportState extends State<CropViewport> {
  CircleCrop? _gestureStart;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    final crop = widget.crop;
    return LayoutBuilder(
      builder: (context, constraints) {
        final circle = math.min(
          math.min(constraints.maxWidth - 48, 320),
          constraints.maxHeight - 48,
        );
        final short = math.min(widget.width, widget.height);
        final pxPerImage = circle / (crop.diameter * short);
        final center = constraints.biggest.center(Offset.zero);
        final w = widget.width * pxPerImage;
        final h = widget.height * pxPerImage;
        return Semantics(
          label: '照片取景，拖动调整位置，双指缩放',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (_) => _gestureStart = crop,
            onScaleUpdate: (d) {
              final start = _gestureStart ?? crop;
              widget.onChanged(
                clampCircleCrop(
                  (
                    centerX:
                        crop.centerX -
                        d.focalPointDelta.dx / pxPerImage / widget.width,
                    centerY:
                        crop.centerY -
                        d.focalPointDelta.dy / pxPerImage / widget.height,
                    diameter: start.diameter / d.scale,
                  ),
                  width: widget.width,
                  height: widget.height,
                ),
              );
            },
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: center.dx - crop.centerX * w,
                    top: center.dy - crop.centerY * h,
                    width: w,
                    height: h,
                    child: Image(
                      image: widget.image,
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                      gaplessPlayback: true,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScrimPainter(
                        center: center,
                        radius: circle / 2,
                        scrim: c.cropScrim,
                        ring: c.paper,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.center,
    required this.radius,
    required this.scrim,
    required this.ring,
  });

  final Offset center;
  final double radius;
  final Color scrim;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = Rect.fromCircle(center: center, radius: radius);
    canvas
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addOval(hole),
        Paint()..color = scrim,
      )
      ..drawOval(
        hole,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ring,
      );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.center != center ||
      old.radius != radius ||
      old.scrim != scrim ||
      old.ring != ring;
}

/// 取景的缩放滑条, 作为双指缩放的非手势替代操作以满足无障碍要求.
///
/// 内部使用 Material 的 `Slider`, 需要祖先中存在 `Material`.
class CropZoomSlider extends StatelessWidget {
  const new({
    super.key,
    required this.crop,
    required this.width,
    required this.height,
    required this.onChanged,
  });

  final CircleCrop crop;
  final int width;
  final int height;
  final ValueChanged<CircleCrop> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    const max = 1 / minCropDiameter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
      child: Row(
        children: [
          ExcludeSemantics(
            child: EatIcon(EatIcons.image, size: 16, color: c.paper),
          ),
          Expanded(
            child: Slider(
              value: (1 / crop.diameter).clamp(1.0, max),
              min: 1,
              max: max,
              activeColor: c.paper,
              inactiveColor: c.paper.withValues(alpha: 0.25),
              thumbColor: c.paper,
              semanticFormatterCallback: (v) => '放大 ${v.toStringAsFixed(1)} 倍',
              onChanged: (zoom) => onChanged(
                clampCircleCrop(
                  (
                    centerX: crop.centerX,
                    centerY: crop.centerY,
                    diameter: 1 / zoom,
                  ),
                  width: width,
                  height: height,
                ),
              ),
            ),
          ),
          ExcludeSemantics(
            child: EatIcon(EatIcons.image, size: 22, color: c.paper),
          ),
        ],
      ),
    );
  }
}
