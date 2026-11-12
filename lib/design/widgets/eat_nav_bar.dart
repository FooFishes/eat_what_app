import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 三个主页面底部的悬浮导航.
///
/// - 左侧: "发现" "附近" "我的" 三个标签组成的液态玻璃胶囊, 选中指示可以拖动.
/// - 右侧: 紧邻胶囊的圆形发布按钮, 同为液态玻璃.
///
/// 本组件只绘制导航本身, 与屏幕边缘的距离和安全区由主页面外壳负责.
/// 消息不在导航中, 入口是发现页右上角的铃铛.
class EatNavBar extends StatelessWidget {
  const new({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.onPublish,
  });

  /// 当前标签的序号: 0 为发现, 1 为附近, 2 为我的.
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// 点击发布按钮的回调. 发布流程从选店开始.
  final VoidCallback onPublish;

  static const _tabs = [
    (icon: EatIcons.discover, label: '发现'),
    (icon: EatIcons.nearby, label: '附近'),
    (icon: EatIcons.me, label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    // 导航高度固定. 系统字号过大时文字会撑破胶囊, 因此限制文字缩放的上限.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: EatSize.nav,
        child: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              // 与屏幕边缘的距离由外壳负责, 因此去掉组件自带的外边距.
              // 组件把每个标签读作带选中状态的按钮, 不是 tab 角色, 因此外层不能声明 tabBar.
              child: GlassTabBar.bottom(
                tabs: [
                  for (final tab in _tabs)
                    GlassTab(
                      icon: EatIcon(tab.icon, size: 22, color: c.inkMuted),
                      activeIcon: EatIcon(tab.icon, size: 22, color: c.ink),
                      label: tab.label,
                    ),
                ],
                selectedIndex: currentIndex,
                onTabSelected: onSelected,
                settings: _barGlass(c.paper),
                indicatorSettings: _indicatorGlass(c.ink),
                indicatorColor: c.ink.withValues(alpha: 0.07),
                glowDuration: const Duration(milliseconds: 150),
                horizontalPadding: 0,
                verticalPadding: 0,
                barHeight: EatSize.nav,
                iconLabelSpacing: 1,
                textStyle: eat.text.caption,
                selectedLabelColor: c.ink,
                unselectedLabelColor: c.inkMuted,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
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

/// 胶囊和发布按钮的玻璃: `paper` 着色 78%, 模糊半径 14.
///
/// 导航悬浮在照片和舞台色上方. 着色低于该值时, 下方内容的颜色透过玻璃,
/// 未选中标签的 `ink-muted` 文字与背景的对比度不足 4.5:1.
/// 边缘的折射和高光不受着色影响, 轮廓保持玻璃质感.
LiquidGlassSettings _barGlass(Color tint) => LiquidGlassSettings(
  bodyMode: GlassBodyMode.clear,
  glassColor: tint.withValues(alpha: 0.78),
  thickness: 30,
  blur: 14,
  lightIntensity: 0.9,
  fresnelStrength: 1.4,
  refractiveIndex: 1.3,
);

/// 选中指示块的玻璃: `ink` 着色 7%, 在偏白的胶囊中显示为略深的色块.
LiquidGlassSettings _indicatorGlass(Color tint) => LiquidGlassSettings(
  bodyMode: GlassBodyMode.clear,
  glassColor: tint.withValues(alpha: 0.07),
  thickness: 24,
  blur: 2,
  lightIntensity: 1.1,
  fresnelStrength: 1.4,
  refractiveIndex: 1.3,
);

class _PublishButton extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    // 与标签胶囊同为液态玻璃. 按压时的拉伸调小, 避免牵动旁边的胶囊.
    return GlassButton.custom(
      onTap: onPressed,
      label: '发布一道菜',
      width: EatSize.nav,
      height: EatSize.nav,
      stretch: 0.15,
      useOwnLayer: true,
      settings: _barGlass(c.paper),
      child: EatIcon(EatIcons.add, size: 26, color: c.ink),
    );
  }
}
