import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 三个主页面底部的悬浮导航.
///
/// - 左侧: "发现" "附近" "我的" 三个标签组成的液态玻璃胶囊, 选中指示可以拖动.
///   选中的标签用实心图标和加粗的文字. 拖动时指示块经过哪个标签, 哪个标签就显示为选中的样子,
///   松手后才真正切换, 与 iOS 的标签栏一致.
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
    required this.transparency,
  });

  /// 当前标签的序号: 0 为发现, 1 为附近, 2 为我的.
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// 点击发布按钮的回调. 发布流程从选店开始.
  final VoidCallback onPublish;

  /// 玻璃的透明度, 0 为不透明, 1 为完全透明. 由用户在设置中调整, 见 [_barGlass].
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
    // 导航高度固定. 系统字号过大时文字会撑破胶囊, 因此限制文字缩放的上限.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: EatSize.nav,
        child: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              // 纵向滑动由外层的手势接收并忽略. 组件只注册了横向拖动手势,
              // 没有其他手势竞争时, 从胶囊上开始的上下滑动会在松手时切换到手指下方的标签.
              child: GestureDetector(
                onVerticalDragStart: (_) {},
                excludeFromSemantics: true,
                // 与屏幕边缘的距离由外壳负责, 因此去掉组件自带的外边距.
                // 组件把每个标签读作带选中状态的按钮, 不是 tab 角色, 因此外层不能声明 tabBar.
                child: GlassTabBar.bottom(
                  tabs: [
                    for (final tab in _tabs)
                      // 组件把选中样式单独画一层, 只露出指示块盖住的部分. 指示块移动时,
                      // 经过的标签就露出这一层的实心图标和加粗文字.
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
                  // 选中态靠指示块和字重区分. 未选中也用 ink, 玻璃才能保持通透, 见 [_barGlass].
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

/// 胶囊和发布按钮的玻璃: 透明度同时决定 `paper` 着色和模糊.
///
/// 看起来是否通透主要取决于模糊: 模糊稍大, 下方的内容就糊成一片, 着色再淡也像磨砂.
/// 因此模糊按透明度的平方衰减, 透明度 70% 时只剩 1 左右, 下方的轮廓清晰可辨; 100% 时不着色也不模糊,
/// 只剩边缘的折射和高光勾出玻璃的形状.
///
/// 导航文字的对比度随之下降: 文字和图标都用 `ink`, 透明度不高于 35% 时压在纯黑上也不低于 4.5:1.
/// 更高的透明度是用户在设置里自己选的.
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
  const new({required this.onPressed, required this.transparency});

  final VoidCallback onPressed;
  final double transparency;

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
      settings: _barGlass(c.paper, transparency),
      child: EatIcon(EatIcons.add, size: 26, color: c.ink),
    );
  }
}
