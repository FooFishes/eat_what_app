import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:flutter/widgets.dart';

/// 补充入口文字前的圆形加号: [color] 实心圆, 中间 [plus] 色的加号.
///
/// 用于 `EatButton.add` 和 `EatChip.add`, 文字里不再写 "+".
class AddMark extends StatelessWidget {
  const new({
    super.key,
    required this.size,
    required this.color,
    required this.plus,
  });

  final double size;
  final Color color;
  final Color plus;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: EatIcon(EatIcons.add, size: size * 0.7, color: plus),
  );
}
