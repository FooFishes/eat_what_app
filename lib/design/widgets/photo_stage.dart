import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 照片舞台的底: 照片按 cover 铺满, 加载完淡入, 顶部压一道淡的暗色渐变.
///
/// 加载中和加载失败时露出 `shade` 深色底, 舞台上的白字照样看得清. 由 [StageScaffold] 按 `stagePhoto` 铺在舞台底层.
class PhotoBackdrop extends StatelessWidget {
  const new({super.key, required this.image, this.topShade = 0});

  final ImageProvider image;

  /// 顶部暗色渐变的高度, 让顶栏的按钮在浅色照片上也看得清. 为 0 时不画.
  final double topShade;

  /// 顶部暗色渐变最深处的不透明度.
  static const _topShadeAlpha = 0.36;

  @override
  Widget build(BuildContext context) {
    final shade = context.eat.colors.shade;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: shade),
        Image(
          image: image,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, synchronous) => synchronous
              ? child
              : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: context.motion(EatMotion.morph),
                  curve: EatMotion.morph.curve,
                  child: child,
                ),
          errorBuilder: (_, _, _) => const SizedBox(),
        ),
        if (topShade > 0)
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: topShade,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    shade.withValues(alpha: _topShadeAlpha),
                    shade.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 压在照片舞台下沿的文字 (如店名和地址), 子树的默认文字色是 `white`.
///
/// 文字背后的照片往下渐渐变成毛玻璃, 毛玻璃上再压一层淡的 `shade`: 只靠模糊时, 浅色照片上的白字对比度不够.
/// 不叠舞台色, 照片本身的颜色透出来. 底部让出被抽屉压住的 [EatSize.sheetOverlap].
class PhotoCaption extends StatelessWidget {
  const new({super.key, required this.child});

  final Widget child;

  /// 毛玻璃的模糊半径.
  static const _blur = 24.0;

  /// 毛玻璃从上沿往下渐显的距离, 文字排在这段之下.
  static const _fade = 80.0;

  /// 毛玻璃上 `shade` 的不透明度.
  static const _tint = 0.42;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: FadingBlur(
                  sigma: _blur,
                  fade: _fade,
                  fadeAtTop: true,
                  tint: c.shade.withValues(alpha: _tint),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EatSpace.s20,
                _fade,
                EatSpace.s20,
                EatSize.sheetOverlap + EatSpace.s20,
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: c.white),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 铺满自身的毛玻璃, 靠 [fadeAtTop] 那一侧的 [fade] 内模糊逐级减弱到没有, 和后面的内容之间没有硬边. [tint] 是压在上面的颜色, 跟着一起淡出.
///
/// 模糊不能用 `ShaderMask` 做渐变: 它另开一层绘制, 里面的 [BackdropFilter] 读到的背景是空的, 什么也模糊不到.
/// 所以把渐变段切成几条, 每条单独模糊, 半径一条比一条小.
class FadingBlur extends StatelessWidget {
  const new({
    super.key,
    required this.sigma,
    required this.fade,
    this.fadeAtTop = false,
    this.tint,
  });

  /// 完全模糊处的模糊半径.
  final double sigma;

  /// 模糊逐级减弱的距离.
  final double fade;

  /// 为 true 时上沿淡出, 否则下沿淡出.
  final bool fadeAtTop;

  final Color? tint;

  /// 渐变段切成的条数. 条数越多过渡越顺, 但每条都要单独读一次背景.
  static const _steps = 8;

  static double _falloff(double t) => t * t;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = constraints.maxHeight;
      final fade = math.min(this.fade, height);
      Widget blur(double sigma, {double? height}) => SizedBox(
        height: height,
        child: sigma <= 0
            ? null
            : ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: const SizedBox.expand(),
                ),
              ),
      );
      // 从完全模糊的一侧往外, 半径逐条减小; 按平方减, 最外几条已经很弱, 和清晰处之间看不出台阶.
      final ramp = [
        for (var i = 0; i < _steps; i++)
          blur(sigma * _falloff(1 - (i + 0.5) / _steps), height: fade / _steps),
      ];
      final solid = Expanded(child: blur(sigma));
      final tint = this.tint;
      final edge = height == 0 ? 0.0 : fade / height;
      return Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: fadeAtTop ? [...ramp.reversed, solid] : [solid, ...ramp],
          ),
          if (tint != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: fadeAtTop
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  end: fadeAtTop ? Alignment.bottomCenter : Alignment.topCenter,
                  colors: [tint.withValues(alpha: 0), tint],
                  stops: [0, edge],
                ),
              ),
            ),
        ],
      );
    },
  );
}
