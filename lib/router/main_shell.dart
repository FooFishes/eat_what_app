import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_nav_bar.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/appearance.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 三个主页面的外壳: 下层是各分支的页面, 上层悬浮 [EatNavBar].
///
/// - 手机: 导航与屏幕左右相距 `space-16`, 与底部相距 `space-24` 加安全区.
/// - 宽屏: 导航放在页面左侧悬浮面板的底部. 三个页面的面板位置相同, 因此切换时导航不移动.
///
/// 安卓返回键在附近页和 "我的" 页先回到发现页, 在发现页才退出应用.
class MainShell extends ConsumerStatefulWidget {
  const new({super.key, required this.shell});

  /// go_router 提供的分支外壳, 包含由 [MainBranches] 排列的各分支页面.
  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
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
      transparency: ref.watch(navGlassTransparencyProvider),
      onPublish: () async {
        // 未认证或封禁中的账号在入口处拦截, 不进入发布流程.
        if (await guardAction(context, ref, Capability.publishDish) &&
            context.mounted) {
          await context.push(Paths.publish);
        }
      },
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

/// 叠放各分支的页面, 只显示当前分支. 切走的分支不销毁, 保留滚动位置和页面状态.
///
/// 与 `StatefulShellRoute.indexedStack` 的默认实现相同, 不可见的分支通过 `TickerMode` 关闭动画.
/// Riverpod 据此暂停这些分支的监听.
///
/// 另外为每个分支提供 [TabReselect], 再次点击当前标签时页面滚回顶部.
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
