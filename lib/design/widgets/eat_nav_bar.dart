import 'dart:ui';

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 三个主页面底部的悬浮导航：左边「发现 / 附近 / 我的」三个标签组成的胶囊，右边紧挨一个黑色圆形发布按钮。
///
/// 只画导航本身，高 `size-nav`；离屏幕左右 `space-16`、离底部 `space-24` 加安全区由主页面外壳摆放。
/// 消息不在导航里，入口是发现页右上角的铃铛。
class EatNavBar extends StatelessWidget {
  const new({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.onPublish,
  });

  /// 0 发现，1 附近，2 我的。
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// 发布第 1 步：选店。
  final VoidCallback onPublish;

  static const _tabs = [
    (icon: EatIcons.discover, label: '发现'),
    (icon: EatIcons.nearby, label: '附近'),
    (icon: EatIcons.me, label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    // 固定高度的控件，系统字号最多跟到 1.3 倍，再大会撑破 60px 的胶囊。
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: EatSize.nav,
        child: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: Semantics(
                role: SemanticsRole.tabBar,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    shadows: eat.shadows.float.outer,
                  ),
                  child: ClipPath(
                    clipper: const ShapeBorderClipper(shape: StadiumBorder()),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: ColoredBox(
                        color: eat.colors.paper.withValues(alpha: 0.94),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            spacing: 2,
                            children: [
                              for (final (i, tab) in _tabs.indexed)
                                Expanded(
                                  child: _NavTab(
                                    icon: tab.icon,
                                    label: tab.label,
                                    selected: i == currentIndex,
                                    onTap: () => onSelected(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _PublishButton(onPressed: onPublish),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final EatIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final color = selected ? c.ink : c.inkMuted;
    return EatTappable(
      onTap: onTap,
      button: false,
      role: SemanticsRole.tab,
      selected: selected,
      builder: (context, _) => AnimatedContainer(
        duration: context.motion(EatMotion.select),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: selected ? c.mist : c.mist.withValues(alpha: 0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 1,
          children: [
            EatIcon(icon, size: 22, color: color),
            Text(
              label,
              style: eat.text.navLabel.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return EatTappable(
      onTap: onPressed,
      label: '发布一道菜',
      focusShape: const CircleBorder(),
      builder: (context, pressed) => AnimatedContainer(
        duration: context.motion(EatMotion.press),
        transform: Matrix4.translationValues(
          0,
          pressed ? EatMotion.pressOffset : 0,
          0,
        ),
        child: Surface(
          shape: const CircleBorder(),
          style: SurfaceStyle(
            top: c.inkTop,
            bottom: c.ink,
            outer: eat.shadows.fab.outer,
            inset: eat.shadows.fab.inset,
          ),
          child: SizedBox.square(
            dimension: EatSize.nav,
            child: Center(
              child: EatIcon(EatIcons.add, size: 26, color: c.paper),
            ),
          ),
        ),
      ),
    );
  }
}
