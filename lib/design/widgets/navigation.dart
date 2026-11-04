import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 悬浮导航在页面底部占用的高度, 由主页面外壳提供.
///
/// 滚动内容末尾须留出这段高度, 否则最后一项会被导航遮挡.
/// 不在主页面中 (详情页, 流程页) 时为 0.
class NavBarInset extends InheritedWidget {
  const new({super.key, required this.bottom, required super.child});

  final double bottom;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavBarInset>()?.bottom ?? 0;

  @override
  bool updateShouldNotify(NavBarInset oldWidget) => bottom != oldWidget.bottom;
}

/// 再次点击当前标签时发出的信号. 主页面收到后滚动到顶部.
class TabReselect extends InheritedWidget {
  const new({super.key, required this.signal, required super.child});

  final Listenable signal;

  /// 不在主页面中时返回 null.
  ///
  /// 只读取信号, 不建立依赖, 信号触发时页面不会重建.
  static Listenable? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabReselect>()?.signal;

  @override
  bool updateShouldNotify(TabReselect oldWidget) => signal != oldWidget.signal;
}

/// 返回的后备行为. 有上一页时返回上一页, 否则调用 [fallback], 通常为前往发现页.
///
/// 从分享链接直接打开或在 Web 上刷新页面时, 没有上一页.
/// 由 App 根部提供, 组件无需知道后备目标.
class BackFallback extends InheritedWidget {
  const new({super.key, required this.fallback, required super.child});

  final VoidCallback fallback;

  /// 返回上一页. 没有上一页时执行后备行为.
  static void back(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.getInheritedWidgetOfExactType<BackFallback>()?.fallback();
  }

  @override
  bool updateShouldNotify(BackFallback oldWidget) => false;
}

/// 页面左上角的返回按钮, 按 [BackFallback] 的规则返回.
///
/// 点击区域为 [extent] 见方, 比普通图标按钮大, 方便单手点到屏幕角落.
class EatBackButton extends StatelessWidget {
  const new({super.key, this.onPressed});

  /// 点击区域的边长.
  static const extent = 52.0;

  /// 图标与点击区域左边缘的距离. 父组件左移这段距离, 图标即与页面边距对齐.
  static const inset = (extent - _iconSize) / 2;

  static const _iconSize = 24.0;

  /// 点击回调. 不传时按 [BackFallback.back] 返回.
  ///
  /// 发布流程等需要先确认的页面自行处理返回.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => EatTappable(
    onTap: onPressed ?? () => BackFallback.back(context),
    label: '返回',
    focusShape: const CircleBorder(),
    builder: (context, _) => const SizedBox.square(
      dimension: extent,
      child: Center(child: EatIcon(EatIcons.back, size: _iconSize)),
    ),
  );
}

/// 页面骨架共用的混入: 持有页面的滚动控制器, 收到 [TabReselect] 信号时滚动到顶部.
mixin ScrollToTopOnReselect<T extends StatefulWidget> on State<T> {
  final scrollController = ScrollController();
  Listenable? _signal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = TabReselect.maybeOf(context);
    if (signal == _signal) return;
    _signal?.removeListener(_scrollToTop);
    _signal = signal?..addListener(_scrollToTop);
  }

  @override
  void dispose() {
    _signal?.removeListener(_scrollToTop);
    scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (!scrollController.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      scrollController.jumpTo(0);
    } else {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }
}
