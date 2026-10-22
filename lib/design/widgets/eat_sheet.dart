import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_layout.dart';
import 'package:flutter/widgets.dart';

/// 舞台下方的白色抽屉：顶部两角 `radius-sheet`，顶部居中一个把手，内容左右留 `space-20`。
///
/// 抽屉是页面的一部分，跟着页面一起滚；它往上压住舞台 32px 由页面骨架负责。抽屉里不再套卡片，
/// 分区靠 `section-title` 和留白隔开。压在舞台色上不加阴影，压在地图上时 [onMap] 加 `shadow-sheet`。
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

/// 抽屉和底部面板顶部的 36×4 把手，只是示意，不承载操作。
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
