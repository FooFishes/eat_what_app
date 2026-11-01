import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 把一道菜显示为盘子: 圆形取景的照片, 外圈为白色盘沿和投影. 实拍图和插画共用.
///
/// 照片按 "调整照片" 保存的圆形取景裁切:
/// - [centerX], [centerY]: 圆心在原图中的位置, 按原图宽高归一到 0–1.
/// - [diameter]: 直径占原图短边的比例. 默认 1, 即居中的短边内切圆.
///
/// 盘沿绘制在 [size] 之外, 宽度由 [rimFor] 按尺寸计算.
/// 图片加载完成前显示 `mist` 底.
/// 列表缩略图使用 `ListThumb`, 不使用本组件.
class DishPlate extends StatelessWidget {
  const new({
    super.key,
    required this.image,
    this.size = EatSize.plate,
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.diameter = 1,
    this.shadow = true,
    this.semanticLabel,
  }) : illustration = null;

  /// 插画自带碗盘, 原样显示, 不加盘沿和投影, 也不裁切成圆形.
  const new illustration(
    Widget this.illustration, {
    super.key,
    this.size = EatSize.plate,
    this.semanticLabel,
  }) : image = null,
       centerX = 0.5,
       centerY = 0.5,
       diameter = 1,
       shadow = false;

  final ImageProvider? image;
  final Widget? illustration;
  final double size;
  final double centerX;
  final double centerY;
  final double diameter;
  final bool shadow;

  /// 读屏文字. 菜品图单独出现时填写.
  ///
  /// 舞台主图旁已有菜名, 此时留空, 图片标记为装饰.
  final String? semanticLabel;

  /// 按盘子尺寸计算盘沿宽度. 宽度随尺寸线性变化, 两端截断.
  static double rimFor(double size) =>
      4 + 4 * ((size - 100) / (EatSize.plate - 100)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final semantics = semanticLabel;
    final Widget plate;
    if (illustration case final illustration?) {
      plate = SizedBox.square(dimension: size, child: illustration);
    } else {
      final eat = context.eat;
      final scale = math.max(size / EatSize.plate, 0.35);
      final drop = eat.shadows.plate.outer.first;
      plate = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: eat.colors.mist,
          boxShadow: [
            if (shadow)
              BoxShadow(
                offset: drop.offset * scale,
                blurRadius: drop.blurRadius * scale,
                color: drop.color,
              ),
            BoxShadow(spreadRadius: rimFor(size), color: eat.colors.paper),
          ],
        ),
        child: ClipOval(
          child: _CroppedImage(
            image: image!,
            centerX: centerX,
            centerY: centerY,
            diameter: diameter,
          ),
        ),
      );
    }
    return semantics == null
        ? ExcludeSemantics(child: plate)
        : Semantics(image: true, label: semantics, child: plate);
  }
}

/// 只绘制原图中圆形取景的外接正方形, 不先按 `cover` 铺满整张图再平移.
class _CroppedImage extends StatefulWidget {
  const new({
    required this.image,
    required this.centerX,
    required this.centerY,
    required this.diameter,
  });

  final ImageProvider image;
  final double centerX;
  final double centerY;
  final double diameter;

  @override
  State<_CroppedImage> createState() => _CroppedImageState();
}

class _CroppedImageState extends State<_CroppedImage> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final _listener = ImageStreamListener(
    (info, _) => setState(() {
      _info?.dispose();
      _info = info;
    }),
    onError: (error, stackTrace) => setState(() {
      _info?.dispose();
      _info = null;
    }),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_CroppedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _resolve();
  }

  void _resolve() {
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _info?.image;
    if (image == null) return const SizedBox.expand();
    return CustomPaint(
      size: Size.infinite,
      painter: _CropPainter(
        image,
        centerX: widget.centerX,
        centerY: widget.centerY,
        diameter: widget.diameter,
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(
    this.image, {
    required this.centerX,
    required this.centerY,
    required this.diameter,
  });

  final ui.Image image;
  final double centerX;
  final double centerY;
  final double diameter;

  @override
  void paint(Canvas canvas, Size size) {
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final side = math.min(width, height) * diameter.clamp(0.05, 1.0);
    final center = Offset(
      (centerX * width).clamp(side / 2, width - side / 2),
      (centerY * height).clamp(side / 2, height - side / 2),
    );
    canvas.drawImageRect(
      image,
      Rect.fromCenter(center: center, width: side, height: side),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.centerX != centerX ||
      oldDelegate.centerY != centerY ||
      oldDelegate.diameter != diameter;
}
