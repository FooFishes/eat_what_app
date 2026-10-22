import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// 一个 MingCute Line 图标。颜色默认跟着所在的文字。
class EatIcon extends StatelessWidget {
  const new(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final EatIcons icon;

  /// 边长。底部导航 22，顶栏 22–24，列表行 20–22，按钮里 18–20，文字旁 14–16。
  final double size;

  /// 不传时取 `DefaultTextStyle` 的颜色；赞过的心形默认是 `stage-tomato`。
  final Color? color;

  /// 只有图标、旁边没有文字时写上动作（「返回」「分享」）；旁边有文字时留空，图标标为装饰。
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
