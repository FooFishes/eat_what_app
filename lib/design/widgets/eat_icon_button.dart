import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 纯图标按钮 (如返回, 关闭, 分享和收藏), 点击区域为 44×44 且无底色.
///
/// [label] 必须写明动作 (如 "返回", "关闭", "分享"), 读屏只朗读 [label].
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

  /// 图标边长. 顶栏常用 22–24, 列表行常用 20–22.
  final double size;

  /// 图标颜色, 不传时继承所在文字的颜色.
  final Color? color;

  @override
  Widget build(BuildContext context) => EatTappable(
    onTap: onPressed,
    label: label,
    focusShape: const CircleBorder(),
    builder: (context, _) => SizedBox.square(
      dimension: EatSize.touch,
      child: Center(
        child: EatIconSwap(icon, size: size, color: color),
      ),
    ),
  );
}
