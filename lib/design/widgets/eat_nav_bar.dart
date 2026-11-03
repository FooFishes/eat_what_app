import 'dart:math' as math;

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 三个主页面底部的悬浮导航.
///
/// - 左侧: "发现" "附近" "我的" 三个标签组成的液态玻璃胶囊, 选中指示可以拖动.
/// - 右侧: 紧邻胶囊的圆形玻璃发布按钮.
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

  /// 胶囊和发布按钮的玻璃.
  ///
  /// 组件默认的玻璃偏薄, 压在浅色舞台和白底上几乎看不出边缘.
  /// 这里略微加厚镜片并提高高光, 让边缘处能看出背后的内容在弯折, 但不到鱼眼的程度.
  /// 白底上没有内容可折射, 靠最外圈一条比背景深一级的细线 (rimShade) 和边缘的略微变暗 (edgeAbsorption) 立住轮廓;
  /// 这两项只在 Impeller 的完整着色器上生效, Web 上没有.
  static const _barGlass = LiquidGlassSettings(
    thickness: 34,
    blur: 3,
    chromaticAberration: 0.3,
    lightIntensity: 0.8,
    refractiveIndex: 1.5,
    saturation: 0.9,
    ambientStrength: 1,
    lightAngle: 0.75 * math.pi,
    glassColor: Color(0x55EFE8E2),
    rimShade: 1,
    rimLight: 1,
    edgeAbsorption: 0.14,
  );

  /// 选中指示在按下和拖动时变成的透镜.
  ///
  /// 组件默认的透镜几乎透明, 只能看到一圈细边.
  /// 这里略微加大曲率和折射率, 让透镜下的图标和文字有可见的放大, 并压一层浅白色区分透镜与胶囊.
  static final _indicatorGlass = AnimatedGlassIndicator.baseIndicatorSettings
      .copyWith(
        thickness: 22,
        refractiveIndex: 1.15,
        chromaticAberration: 0.1,
        glassColor: const Color(0x14FFFFFF),
      );

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    // 导航高度固定. 系统字号过大时文字会撑破胶囊, 因此限制文字缩放的上限.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: EatSize.nav,
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
          // 发布按钮放在组件的附加按钮位上, 与胶囊共用一层玻璃, 靠近时边缘会相互融合.
          extraButton: GlassTabBarExtraButton(
            icon: EatIcon(EatIcons.add, size: 26, color: c.ink),
            iconColor: c.ink,
            onTap: onPublish,
            label: '发布一道菜',
            size: EatSize.nav,
          ),
          spacing: EatSpace.s10,
          horizontalPadding: 0,
          verticalPadding: 0,
          barHeight: EatSize.nav,
          settings: _barGlass.copyWith(shadow: eat.shadows.float.outer),
          indicatorSettings: _indicatorGlass,
          indicatorColor: c.ink.withValues(alpha: 0.08),
          iconLabelSpacing: 1,
          textStyle: eat.text.navLabel,
          selectedLabelColor: c.ink,
          unselectedLabelColor: c.inkMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
