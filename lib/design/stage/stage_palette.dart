import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:eat/design/tokens/stage_color.dart';

/// 从照片推荐的舞台色.
///
/// [ranked] 是全部舞台色按与照片主色调的距离由近到远的排序.
/// [reliable] 为 false 表示照片过灰, 排序第一的颜色不可采用, 由 [top3] 替换为分类默认色.
class const StageSuggestion({
  required final List<StageColor> ranked,
  required final bool reliable,
}) {
  /// "调整照片" 中给出的三个推荐色.
  ///
  /// 不可靠时第一个为 [fallback], 其后为排序中除 [fallback] 以外的前两个.
  List<StageColor> top3(StageColor fallback) => reliable
      ? ranked.take(3).toList()
      : [fallback, ...ranked.where((c) => c != fallback).take(2)];
}

/// 解码后的取色小图, 保存长边不超过 [StagePalette.sampleSide] 的 RGBA 像素数据.
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

/// 从圆形取景内的像素提取主色调并吸附到最近的舞台色.
///
/// 不使用平均色, 因为实拍中餐的平均色几乎都是发灰的褐色.
///
/// 求主色调的步骤:
/// 1. 按色相把像素分为 36 段, 以 "彩度 × 亮度系数" 累计每段的权重.
/// 2. 取权重最大的一段及其两侧各两段, 共 50°.
/// 3. 对这 5 段的像素按亮度系数求平均, 得到代表色.
///
/// 第 3 步不再乘以彩度, 因为乘以彩度会使结果偏向面积很小的高彩度区域 (例如红烧肉的酱汁会使整盘菜被判为红油色).
abstract final class StagePalette {
  /// 解码后的长边像素数. 该尺寸在三端主线程上的取色耗时都可以接受, 因此不使用 isolate.
  static const sampleSide = 256;

  static const _hueBins = 36;

  /// 彩度阈值, 超过该值的像素计为有颜色.
  static const _colorfulChroma = 0.045;

  /// 按亮度系数加权的有颜色像素在圆内的最低占比, 低于该比例时判定为过灰.
  static const _minColorfulShare = 0.12;

  /// 吸附时亮度差的权重.
  ///
  /// 实拍照片的明暗受光线影响大, 区分菜品主要依靠色相.
  /// 例如粘豆包颜色很淡, 降低亮度权重后仍能吸附到黄色系.
  static const _lightnessWeight = 0.5;

  /// 把任意编码的图片 [bytes] 解码为长边不超过 [sampleSide] 的取色小图.
  ///
  /// "调整照片" 中每次调整裁切都会重新取色, 因此解码只执行一次, 后续仅调用 [StageSample.suggest] 重新计算.
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

  /// 根据 [width] × [height] 的 [rgba] 像素推荐舞台色.
  ///
  /// 取景圆的参数与 `DishPlate` 的裁切参数一致:
  /// [centerX] 和 [centerY] 是圆心占宽高的比例, [diameter] 是直径占短边的比例.
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

  /// 计算亮度权重系数, 对过暗 (阴影, 碗沿) 和过亮 (反光, 桌布) 的像素降权, 亮度到达两端时系数为 0.
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

/// OKLab 色彩空间中的颜色.
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
