import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_nav_bar.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// 三个主页面的外壳：下面是各分支的页面，上面悬浮 [EatNavBar]。
///
/// 手机上导航离屏幕左右 `space-16`、离底部 `space-24` 加安全区；宽屏时放进页面左侧悬浮面板的底部，
/// 三个页面的面板位置一样，所以切换时导航不动。安卓的返回键在附近、我的先回发现，在发现才退出。
class MainShell extends StatefulWidget {
  const new({super.key, required this.shell});

  /// go_router 给的分支外壳，里面是 [MainBranches] 排好的各分支页面。
  final StatefulNavigationShell shell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _signals = [for (var i = 0; i < 3; i++) _ReselectSignal()];

  @override
  void dispose() {
    for (final signal in _signals) {
      signal.dispose();
    }
    super.dispose();
  }

  void _select(int index) {
    final shell = widget.shell;
    final reselect = index == shell.currentIndex;
    if (reselect) _signals[index].fire();
    shell.goBranch(index, initialLocation: reselect);
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final layout = EatLayout.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final navBar = EatNavBar(
      currentIndex: shell.currentIndex,
      onSelected: _select,
      onPublish: () => context.push(Paths.publish),
    );
    final Widget positioned;
    final double inset;
    if (layout.isWide) {
      const side = EatLayout.widePanelInset + EatLayout.widePanelNavInset;
      positioned = Positioned(
        left: side,
        bottom: side,
        width: EatLayout.widePanelWidth - EatLayout.widePanelNavInset * 2,
        child: navBar,
      );
      inset = EatSize.nav + EatLayout.widePanelNavInset + EatSpace.s16;
    } else {
      positioned = Positioned(
        left: EatSpace.s16,
        right: EatSpace.s16,
        bottom: EatSpace.s24 + safeBottom,
        child: navBar,
      );
      inset = EatSize.nav + EatSpace.s24 + safeBottom + EatSpace.s16;
    }
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: _Signals(
        signals: _signals,
        child: Stack(
          children: [
            Positioned.fill(
              child: NavBarInset(bottom: inset, child: shell),
            ),
            positioned,
          ],
        ),
      ),
    );
  }
}

/// 各分支的页面叠在一起，只显示当前那个；切走的分支不销毁，滚动位置和页面状态都留着。
///
/// 和 `StatefulShellRoute.indexedStack` 自带的做法一样，看不见的分支关掉动画（`TickerMode`），
/// Riverpod 据此暂停它们的监听；另外给每个分支一个 [TabReselect]，再点当前标签时页面滚回顶部。
class MainBranches extends StatelessWidget {
  const new({super.key, required this.shell, required this.children});

  final StatefulNavigationShell shell;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final signals = context.getInheritedWidgetOfExactType<_Signals>()!.signals;
    return IndexedStack(
      index: shell.currentIndex,
      children: [
        for (final (i, child) in children.indexed)
          Offstage(
            offstage: i != shell.currentIndex,
            child: TickerMode(
              enabled: i == shell.currentIndex,
              child: TabReselect(signal: signals[i], child: child),
            ),
          ),
      ],
    );
  }
}

class _Signals extends InheritedWidget {
  const new({required this.signals, required super.child});

  final List<_ReselectSignal> signals;

  @override
  bool updateShouldNotify(_Signals oldWidget) => false;
}

class _ReselectSignal extends ChangeNotifier {
  void fire() => notifyListeners();
}
