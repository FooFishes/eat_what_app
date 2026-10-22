import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_layout.dart';
import 'package:flutter/widgets.dart';

/// 把一道菜显示成一个盘子：圆形取景的照片，外面一圈白色盘沿加投影。实拍图和插画都走它。
///
/// 照片按「调整照片」保存的圆心和直径裁：[centerX]、[centerY] 是圆心在原图里的位置（0–1，按原图宽高
/// 归一），[diameter] 是圆的直径占原图短边的比例，默认 1，即居中的短边内切圆。
/// 盘沿画在 [size] 外面：舞台主图 320px 配 8px 盘沿，100–200px 的预览配 4–6px，按尺寸自动取。
/// 图片没加载出来时盘子里是 `mist` 底。列表缩略图不用它，用 `ListThumb`。
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

  /// 插画本身已经画了碗盘，直接放，不加盘沿和投影，也不裁成圆。
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

  /// 单独出现的菜品图才写；舞台主图旁边已经写了菜名，留空标为装饰。
  final String? semanticLabel;

  /// 盘沿宽度：100px 以下 4，320px 以上 8，中间按尺寸线性取。
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

/// 只画原图里那块正方形（圆的外接正方形），省得先把整张图按 `cover` 铺开再挪位置。
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
