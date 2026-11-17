import 'package:flutter/widgets.dart';

/// 按键盘高度给 [child] 底部留白, 让内容停在键盘上方; [child] 里读到的 `viewInsets` 底边为 0.
///
/// - 键盘升降动画的每一帧 `viewInsets` 都在变. 只有这一层订阅它, 每帧重建的只是这层留白,
///   页面把其余部分作为 [child] 传进来, 不会跟着重建.
/// - iOS 26 的键盘是半透明的圆角面板, 键盘后面的区域会透出来; 那里没有画东西时透出的是原生视图的黑底.
///   外面没有铺底色的页面传 [color], 把留白的区域涂上.
class KeyboardInset extends StatelessWidget {
  const new({super.key, this.color, required this.child});

  /// 键盘后面那块留白的颜色. 外层已经铺了底色时不传.
  final Color? color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
    return switch (color) {
      final color? => ColoredBox(color: color, child: inset),
      null => inset,
    };
  }
}
