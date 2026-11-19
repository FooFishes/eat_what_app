import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 由主页面外壳提供的悬浮导航底部占用高度.
///
/// 滚动内容末尾须保留该高度以免最后一项被导航栏遮挡; 在详情页, 流程页等非主页面中其值为 0.
class NavBarInset extends InheritedWidget {
  const new({super.key, required this.bottom, required super.child});

  final double bottom;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavBarInset>()?.bottom ?? 0;

  @override
  bool updateShouldNotify(NavBarInset oldWidget) => bottom != oldWidget.bottom;
}

/// 再次点击当前标签时触发的信号, 主页面收到后应滚动回顶部.
class TabReselect extends InheritedWidget {
  const new({super.key, required this.signal, required super.child});

  final Listenable signal;

  /// 读取再次点击标签的信号, 不在主页面中时返回 null.
  ///
  /// 仅读取信号而不建立依赖, 避免信号触发时引起页面重建.
  static Listenable? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabReselect>()?.signal;

  @override
  bool updateShouldNotify(TabReselect oldWidget) => signal != oldWidget.signal;
}

/// 提供页面返回的后备行为: 存在上一页时正常返回, 否则调用 [fallback] (通常跳转至发现页).
///
/// 从分享链接直接打开或在 Web 上刷新页面时路由栈中没有上一页; 由 App 根部注入后备逻辑, 使子组件无需感知具体目标.
class BackFallback extends InheritedWidget {
  const new({super.key, required this.fallback, required super.child});

  final VoidCallback fallback;

  /// 返回上一页, 若导航栈无可退页面则执行后备行为.
  ///
  /// 和系统返回一样走 [Navigator.maybePop], 页面里的 [PopScope] (如没发出的评论) 能先拦下来确认.
  static void back(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.maybePop();
      return;
    }
    context.getInheritedWidgetOfExactType<BackFallback>()?.fallback();
  }

  @override
  bool updateShouldNotify(BackFallback oldWidget) => false;
}

/// 页面左上角的返回按钮, 按 [BackFallback] 规则执行返回.
///
/// 点击区域为 [extent] 见方, 大于普通图标按钮以方便单手触及屏幕角落.
class EatBackButton extends StatelessWidget {
  const new({super.key, this.onPressed});

  /// 点击区域边长.
  static const extent = 52.0;

  /// 图标与点击区域左边缘的距离; 父组件左移该距离即可使图标与页面边距对齐.
  static const inset = (extent - _iconSize) / 2;

  static const _iconSize = 24.0;

  /// 点击回调, 未传入时按 [BackFallback.back] 执行默认返回.
  ///
  /// 发布流程等离开前需弹窗确认的页面应传入自定义回调.
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

/// 页面骨架共用的混入, 负责管理滚动控制器并在收到 [TabReselect] 信号时滚动回顶部.
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
