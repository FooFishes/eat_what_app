import 'package:flutter/widgets.dart';

/// 按键盘高度给 [child] 底部留白, 让内容停在键盘上方; [child] 里读到的 `viewInsets` 底边为 0.
///
/// 键盘升降动画的每一帧 `viewInsets` 都在变. 只有这一层订阅它, 每帧重建的只是这层留白,
/// 页面把其余部分作为 [child] 传进来, 不会跟着重建.
class KeyboardInset extends StatelessWidget {
  const new({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: child,
    ),
  );
}
