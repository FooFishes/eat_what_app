import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// MingCute Line 图标. 未指定颜色时使用所在文字的颜色.
class EatIcon extends StatelessWidget {
  const new(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final EatIcons icon;

  /// 边长. 描边图标小于 20 时换用加粗变体, 见 [EatIcons.assetFor].
  final double size;

  /// 未指定时使用 `DefaultTextStyle` 的颜色. [EatIcons.heartOn] 默认使用 `stage-tomato`.
  final Color? color;

  /// 读屏文字.
  ///
  /// 图标单独出现时写明动作, 如 "返回" "分享".
  /// 旁边已有文字时留空, 图标作为装饰不参与读屏.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color =
        this.color ??
        (icon == EatIcons.heartOn ? StageColor.tomato.color : null) ??
        DefaultTextStyle.of(context).style.color ??
        context.eat.colors.ink;
    return SvgPicture(
      AssetBytesLoader(icon.assetFor(size)),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}

/// 有两种状态的图标, 如赞和收藏. [icon] 变化时, 新图标由小放大, 略微超过原大小后回落.
///
/// 只有一种状态的图标使用 [EatIcon]. 系统开启减少动态效果时不播放动画.
class EatIconSwap extends StatelessWidget {
  const new(this.icon, {super.key, this.size = 24, this.color});

  final EatIcons icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: context.motion(EatMotion.select),
    switchInCurve: Curves.easeOutBack,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (child, animation) =>
        ScaleTransition(scale: animation, child: child),
    child: EatIcon(icon, key: ValueKey(icon), size: size, color: color),
  );
}
