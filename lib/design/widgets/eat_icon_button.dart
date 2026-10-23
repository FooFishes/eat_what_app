import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 只有图标的按钮：返回、关闭、分享、收藏。点击区域 44×44，没有底色。
///
/// [label] 必须写清动作（「返回」「关闭」「分享」），读屏只读这一句。
class EatIconButton extends StatelessWidget {
  const new(
    this.icon, {
    super.key,
    required this.label,
    required this.onPressed,
    this.size = 22,
    this.color,
  });

  final EatIcons icon;
  final String label;
  final VoidCallback? onPressed;

  /// 顶栏 22–24，列表行 20–22。
  final double size;

  /// 不传时跟着所在的文字。
  final Color? color;

  @override
  Widget build(BuildContext context) => EatTappable(
    onTap: onPressed,
    label: label,
    focusShape: const CircleBorder(),
    builder: (context, _) => SizedBox.square(
      dimension: EatSize.touch,
      child: Center(
        child: EatIcon(icon, size: size, color: color),
      ),
    ),
  );
}
