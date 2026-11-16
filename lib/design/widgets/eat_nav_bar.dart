import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 显示在三个主页面底部的悬浮导航栏.
///
/// - 左侧: "发现" "附近" "我的" 三个标签组成的液态玻璃胶囊, 选中指示块可拖动.
///   选中的标签使用实心图标和加粗文字; 拖动期间指示块经过的标签会即时呈现选中样式,
///   松手后才触发切换, 与 iOS 标签栏交互一致.
/// - 右侧: 紧邻胶囊的圆形发布按钮, 同为液态玻璃材质.
///
/// 本组件仅负责绘制导航自身, 与屏幕边缘的距离及安全区留白由主页面外壳处理.
/// 消息入口不在导航栏中, 位于发现页右上角的铃铛按钮.
class EatNavBar extends StatelessWidget {
  const new({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.onPublish,
    required this.transparency,
  });

  /// 当前标签的序号: 0 为发现, 1 为附近, 2 为我的.
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// 点击发布按钮的回调. 发布流程从选店开始.
  final VoidCallback onPublish;

  /// 玻璃透明度 (0 为不透明, 1 为完全透明), 由用户在设置中调整, 具体效果见 [_barGlass].
  final double transparency;

  static const _tabs = [
    (icon: EatIcons.discover, activeIcon: EatIcons.discoverOn, label: '发现'),
    (icon: EatIcons.nearby, activeIcon: EatIcons.nearbyOn, label: '附近'),
    (icon: EatIcons.me, activeIcon: EatIcons.meOn, label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    // 导航高度固定, 为避免系统字号过大时文字撑破胶囊, 需限制文字缩放上限.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: EatSize.nav,
        child: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              // 由外层手势接收并忽略纵向滑动: 因为底层组件只注册了横向拖动手势,
              // 若无其他手势竞争, 在胶囊上上下滑动后松手会误切换到手指下方的标签.
              child: GestureDetector(
                onVerticalDragStart: (_) {},
                excludeFromSemantics: true,
                // 与屏幕边缘的距离由页面外壳负责, 因此去掉组件自带的外边距.
                // 底层组件将每个标签读作带选中状态的按钮而非 tab 角色, 因此外层不能声明 tabBar.
                child: GlassTabBar.bottom(
                  tabs: [
                    for (final tab in _tabs)
                      // 底层组件将选中样式单独绘制为一层, 仅透出指示块覆盖的区域;
                      // 指示块移动时, 经过的标签会随之露出该层的实心图标和加粗文字.
                      GlassTab(
                        icon: EatIcon(tab.icon, size: 22, color: c.ink),
                        activeIcon: EatIcon(
                          tab.activeIcon,
                          size: 22,
                          color: c.ink,
                        ),
                        label: tab.label,
                      ),
                  ],
                  selectedIndex: currentIndex,
                  onTabSelected: onSelected,
                  settings: _barGlass(c.paper, transparency),
                  indicatorSettings: _indicatorGlass(c.ink),
                  indicatorColor: c.ink.withValues(alpha: 0.07),
                  glowDuration: const Duration(milliseconds: 150),
                  horizontalPadding: 0,
                  verticalPadding: 0,
                  barHeight: EatSize.nav,
                  iconLabelSpacing: 1,
                  textStyle: eat.text.caption,
                  // 选中态通过指示块和字重区分; 未选中态同样使用 ink, 以保持玻璃的通透观感, 见 [_barGlass].
                  selectedLabelColor: c.ink,
                  unselectedLabelColor: c.ink,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            _PublishButton(onPressed: onPublish, transparency: transparency),
          ],
        ),
      ),
    );
  }
}

/// 生成标签胶囊和发布按钮共用的液态玻璃配置, 透明度同时控制 `paper` 着色与模糊度.
///
/// 通透感主要取决于模糊半径: 若模糊稍大, 即使着色很淡也会遮糊下方内容而显得像磨砂.
/// 因此模糊度按不透明度的平方衰减: 透明度 70% 时模糊度降至约 1, 下方轮廓仍清晰可辨;
/// 100% 时则不着色也不模糊, 仅由边缘的折射与高光勾勒轮廓.
///
/// 降低不透明度会使导航文字对比度下降: 文字和图标均采用 `ink`, 透明度不高于 35% 时叠加在纯黑背景上仍不低于 4.5:1;
/// 更高的透明度由用户在设置中主动选择.
LiquidGlassSettings _barGlass(Color tint, double transparency) {
  final opacity = 1 - transparency;
  return LiquidGlassSettings(
    bodyMode: GlassBodyMode.clear,
    glassColor: tint.withValues(alpha: 0.85 * opacity),
    thickness: 30,
    blur: 12 * opacity * opacity,
    lightIntensity: 0.9,
    fresnelStrength: 1.4,
    refractiveIndex: 1.3,
  );
}

/// 选中指示块的液态玻璃配置, 以 7% 透明度的 `ink` 着色, 在偏白的胶囊内呈现为略深的色块.
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
  const new({required this.onPressed, required this.transparency});

  final VoidCallback onPressed;
  final double transparency;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    // 与标签胶囊共用液态玻璃配置, 但减小按压拉伸幅度以避免视觉上牵动相邻胶囊.
    return GlassButton.custom(
      onTap: onPressed,
      label: '发布一道菜',
      width: EatSize.nav,
      height: EatSize.nav,
      stretch: 0.15,
      useOwnLayer: true,
      settings: _barGlass(c.paper, transparency),
      child: EatIcon(EatIcons.add, size: 26, color: c.ink),
    );
  }
}
