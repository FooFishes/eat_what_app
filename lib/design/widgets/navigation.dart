import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:flutter/widgets.dart';

/// 主页面外壳告诉页面：悬浮导航占了底部多高，滚动内容最后要留出这段，最后一项才不会被盖住。
///
/// 不在主页面里（详情页、流程页）时是 0。
class NavBarInset extends InheritedWidget {
  const new({super.key, required this.bottom, required super.child});

  final double bottom;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavBarInset>()?.bottom ?? 0;

  @override
  bool updateShouldNotify(NavBarInset oldWidget) => bottom != oldWidget.bottom;
}

/// 在当前所在的标签上再点一次时发出的信号，主页面收到后滚回顶部。
class TabReselect extends InheritedWidget {
  const new({super.key, required this.signal, required super.child});

  final Listenable signal;

  /// 不在主页面里时返回 null。只取信号、不建立依赖，信号触发时页面不重建。
  static Listenable? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabReselect>()?.signal;

  @override
  bool updateShouldNotify(TabReselect oldWidget) => signal != oldWidget.signal;
}

/// 返回的兜底：有上一页就回上一页，没有时（从分享链接直接打开、Web 上刷新了页面）调用 [fallback]，
/// 一般是回到发现页。由 App 根部提供，组件不用知道兜底去哪。
class BackFallback extends InheritedWidget {
  const new({super.key, required this.fallback, required super.child});

  final VoidCallback fallback;

  /// 返回上一页，没有上一页时走兜底。
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

/// 页面左上角 44×44 的返回，按 [BackFallback] 的规则回去。
class EatBackButton extends StatelessWidget {
  const new({super.key, this.onPressed});

  /// 不传时返回上一页或走兜底；发布流程这类要先确认的页面自己处理。
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => EatIconButton(
    EatIcons.back,
    label: '返回',
    size: 24,
    onPressed: onPressed ?? () => BackFallback.back(context),
  );
}

/// 页面骨架共用：持有页面的滚动控制器，收到 [TabReselect] 的信号时滚回顶部。
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
