import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:material_ui/material_ui.dart';

/// 下拉刷新容器, 包裹页面滚动视图并在下拉松手超过阈值时调用 [onRefresh], 完成前顶部持续显示进度圈.
///
/// - 进度圈采用 `paper` 底色与 `ink` 线条而不使用舞台色, 确保在舞台和白底上均有足够对比度.
/// - 仅响应页面自身的纵向滚动, 不会因页面内横向滚动的分类栏而误触发.
/// - 刷新期间保留页面原有内容, 不替换成加载占位.
class EatRefresh extends StatelessWidget {
  const new({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;

  /// 进度圈出现位置与滚动视图顶部的偏移距离, 页面顶部有固定顶栏时传入顶栏底边的纵坐标.
  final double edgeOffset;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return RefreshIndicator(
      onRefresh: () {
        EatHaptics.light();
        return onRefresh();
      },
      color: c.ink,
      backgroundColor: c.paper,
      edgeOffset: edgeOffset,
      displacement: 28,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
