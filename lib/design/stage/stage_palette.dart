import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:eat/design/tokens/stage_color.dart';

/// 从照片推荐的舞台色：9 个舞台色按离照片主色调的远近排好，外加这次取色可不可靠。
///
/// 照片太灰（[reliable] 为 false）时排第一的不作数，由 [top3] 换成分类默认色（产品 6.9）。
class const StageSuggestion({
  required final List<StageColor> ranked,
  required final bool reliable,
}) {
  /// 「调整照片」里给出的三个推荐色。不可靠时第一个是 [fallback]，后两个取排序里的前两个。
  List<StageColor> top3(StageColor fallback) => reliable
      ? ranked.take(3).toList()
      : [fallback, ...ranked.where((c) => c != fallback).take(2)];
}

/// 解码好的取色小图：长边不超过 [StagePalette.sampleSide] 的 RGBA 像素。
class const StageSample(
  final Uint8List rgba, {
  required final int width,
  required final int height,
}) {
  StageSuggestion suggest({
    double centerX = 0.5,
    double centerY = 0.5,
    double diameter = 1,
  }) => StagePalette.suggest(
    rgba,
    width: width,
    height: height,
    centerX: centerX,
    centerY: centerY,
    diameter: diameter,
  );
}

/// 舞台取色（技术架构 13.5）：只看圆内的像素，按彩度加权找主色调，再吸附到 9 个舞台色。
///
/// 不用平均色：实拍中餐的平均色几乎都是发灰的褐色。这里先把像素按色相分成 36 段、按「彩度 × 亮度系数」
/// 累计权重，找出最重的一段，再把它两侧各两段（共 50°）的像素按亮度系数平均，得到代表色。
/// 平均时不再乘彩度：乘了会被最艳的那一小块拉走，红烧肉的酱汁会把整盘拉成红油。
abstract final class StagePalette {
  /// 解码时的长边。256 像素在三端主线程上都够快，不开 isolate。
  static const sampleSide = 256;

  static const _hueBins = 36;

  /// 彩度超过它才算「有颜色」。
  static const _colorfulChroma = 0.045;

  /// 有颜色的像素在圆内（按亮度系数计）占比低于它，判为太灰。
  static const _minColorfulShare = 0.12;

  /// 吸附时亮度差的权重。实拍的明暗受光线影响大，色相才是分得开菜的依据：粘豆包很淡，
  /// 靠色相仍能分到黄色系（设计资源说明 `G-PhotoPipeline`）。
  static const _lightnessWeight = 0.5;

  /// 把 [bytes]（任意编码的图片）按 [sampleSide] 解码成取色用的小图。
  ///
  /// 「调整照片」里裁切一变就要重算，解码只做一次，之后用 [StageSample.suggest]。
  static Future<StageSample> sample(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final scale = math.min(
      1.0,
      sampleSide / math.max(descriptor.width, descriptor.height),
    );
    final codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * scale).round()),
      targetHeight: math.max(1, (descriptor.height * scale).round()),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final data = await image.toByteData();
      return StageSample(
        data!.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
    } finally {
      image.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }

  /// [rgba] 是 [width] × [height] 的 RGBA 像素。圆按 `DishPlate` 的裁切参数：圆心占宽高的比例，
  /// 直径占短边的比例。
  static StageSuggestion suggest(
    Uint8List rgba, {
    required int width,
    required int height,
    double centerX = 0.5,
    double centerY = 0.5,
    double diameter = 1,
  }) {
    final radius = math.min(width, height) * diameter.clamp(0.05, 1.0) / 2;
    final cx = (centerX * width).clamp(radius, width - radius);
    final cy = (centerY * height).clamp(radius, height - radius);
    final r2 = radius * radius;

    final binWeight = List<double>.filled(_hueBins, 0);
    final binCount = List<double>.filled(_hueBins, 0);
    final binL = List<double>.filled(_hueBins, 0);
    final binA = List<double>.filled(_hueBins, 0);
    final binB = List<double>.filled(_hueBins, 0);
    var total = 0.0;
    var colorful = 0.0;

    final x0 = math.max(0, (cx - radius).floor());
    final x1 = math.min(width - 1, (cx + radius).ceil());
    final y0 = math.max(0, (cy - radius).floor());
    final y1 = math.min(height - 1, (cy + radius).ceil());
    for (var y = y0; y <= y1; y++) {
      final dy = y + 0.5 - cy;
      for (var x = x0; x <= x1; x++) {
        final dx = x + 0.5 - cx;
        if (dx * dx + dy * dy > r2) continue;
        final i = (y * width + x) * 4;
        if (rgba[i + 3] < 128) continue;
        final lab = _Lab.fromRgb(rgba[i], rgba[i + 1], rgba[i + 2]);
        final light = _lightnessFactor(lab.l);
        if (light == 0) continue;
        total += light;
        final chroma = math.sqrt(lab.a * lab.a + lab.b * lab.b);
        if (chroma > _colorfulChroma) colorful += light;
        final weight = chroma * light;
        if (weight == 0) continue;
        final hue = math.atan2(lab.b, lab.a);
        final bin =
            ((hue + math.pi) / (2 * math.pi) * _hueBins).floor() % _hueBins;
        binWeight[bin] += weight;
        binCount[bin] += light;
        binL[bin] += lab.l * light;
        binA[bin] += lab.a * light;
        binB[bin] += lab.b * light;
      }
    }

    var best = 0;
    for (var i = 1; i < _hueBins; i++) {
      if (binWeight[i] > binWeight[best]) best = i;
    }
    var w = 0.0, l = 0.0, a = 0.0, b = 0.0;
    for (final offset in const [-2, -1, 0, 1, 2]) {
      final i = (best + offset + _hueBins) % _hueBins;
      w += binCount[i];
      l += binL[i];
      a += binA[i];
      b += binB[i];
    }
    final reliable =
        total > 0 && w > 0 && colorful / total >= _minColorfulShare;
    final target = w > 0 ? _Lab(l / w, a / w, b / w) : const _Lab(0.75, 0, 0);
    final ranked = [...StageColor.values]
      ..sort(
        (p, q) => _distance(
          target,
          _stageLab[p]!,
        ).compareTo(_distance(target, _stageLab[q]!)),
      );
    return StageSuggestion(ranked: ranked, reliable: reliable);
  }

  /// 太黑（阴影、碗沿）和太白（反光、桌布）的像素降权，到两头时不算。
  static double _lightnessFactor(double l) =>
      _smoothstep(0.12, 0.32, l) * (1 - _smoothstep(0.86, 0.97, l));

  static double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static double _distance(_Lab p, _Lab q) {
    final dl = (p.l - q.l) * _lightnessWeight;
    final da = p.a - q.a;
    final db = p.b - q.b;
    return dl * dl + da * da + db * db;
  }

  static final _stageLab = {
    for (final stage in StageColor.values)
      stage: _Lab.fromRgb(
        (stage.color.r * 255).round(),
        (stage.color.g * 255).round(),
        (stage.color.b * 255).round(),
      ),
  };
}

/// OKLab 颜色。
class const _Lab(final double l, final double a, final double b) {
  factory _Lab.fromRgb(int r, int g, int b) {
    final lr = _linear(r), lg = _linear(g), lb = _linear(b);
    final l = _cbrt(0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb);
    final m = _cbrt(0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb);
    final s = _cbrt(0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb);
    return _Lab(
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    );
  }

  static final _linearTable = [
    for (var i = 0; i < 256; i++)
      i / 255 <= 0.04045
          ? i / 255 / 12.92
          : math.pow((i / 255 + 0.055) / 1.055, 2.4).toDouble(),
  ];

  static double _linear(int channel) => _linearTable[channel];

  static double _cbrt(double x) => math.pow(x, 1 / 3).toDouble();
}
