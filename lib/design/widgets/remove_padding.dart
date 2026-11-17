import 'package:flutter/widgets.dart';

/// 去掉 [child] 读到的上边或下边的安全区, 效果同 `MediaQuery.removePadding`.
///
/// `MediaQuery.removePadding(context: context, ...)` 用调用方的 context 读整份屏幕信息,
/// 调用方因此订阅了全部字段, 键盘升降动画的每一帧都会整个重建.
/// 这里换成在自己的 context 里读, 每帧重建的只有这一层, [child] 由调用方传入, 不跟着重建.
class RemovePadding extends StatelessWidget {
  const new({
    super.key,
    this.removeTop = false,
    this.removeBottom = false,
    required this.child,
  });

  final bool removeTop;
  final bool removeBottom;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.removePadding(
    context: context,
    removeTop: removeTop,
    removeBottom: removeBottom,
    child: child,
  );
}
