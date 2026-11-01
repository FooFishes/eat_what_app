import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 舞台下方的白色抽屉. 顶部两角为 `radius-sheet`, 顶部居中显示把手, 内容左右留白 `space-20`.
///
/// - 抽屉是页面的一部分, 随页面滚动. 抽屉与舞台的重叠由页面骨架负责.
/// - 抽屉内不嵌套卡片, 分区之间用 `section-title` 和留白分隔.
/// - 位于舞台色上时不加阴影. [onMap] 为 true 时位于地图上, 加 `shadow-sheet`.
class EatSheet extends StatelessWidget {
  const new({super.key, required this.child, this.onMap = false});

  final Widget child;
  final bool onMap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: eat.colors.paper,
        borderRadius: const BorderRadius.vertical(top: EatRadius.sheet),
        boxShadow: onMap ? eat.shadows.sheet.outer : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(EatSpace.s20, 10, EatSpace.s20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: EatSpace.s14,
          children: [const SheetHandle(), child],
        ),
      ),
    );
  }
}

/// 抽屉和底部面板顶部的把手. 仅作示意, 不响应操作.
class SheetHandle extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: context.eat.colors.handle,
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
    ),
  );
}
