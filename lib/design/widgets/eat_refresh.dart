import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:material_ui/material_ui.dart';

/// 下拉刷新. 包裹页面的滚动视图. 下拉超过阈值后松手时调用 [onRefresh], 完成前进度圈停留在顶部.
///
/// - 进度圈为 `paper` 底和 `ink` 线条, 不使用舞台色. 该配色在舞台和白底上的对比度都足够.
/// - 只响应页面自身的纵向滚动. 页面内横向滚动的分类栏不会触发刷新.
/// - 刷新期间页面保留原有内容, 不显示加载占位.
class EatRefresh extends StatelessWidget {
  const new({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;

  /// 进度圈出现的位置与滚动视图顶部的距离. 页面顶部有固定顶栏时传入顶栏底边的纵坐标.
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
