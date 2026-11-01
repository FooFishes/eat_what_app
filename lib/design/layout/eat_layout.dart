import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 屏幕宽度分档.
enum WidthClass {
  /// 宽度小于 [EatLayout.narrowBreakpoint]. 舞台菜名和价格按宽度等比缩小.
  narrow,

  /// 宽度介于两个断点之间. 内容铺满屏幕, 左右边距为 `space-20`.
  phone,

  /// 宽度不小于 [EatLayout.wideBreakpoint].
  ///
  /// - 舞台铺满屏幕, 抽屉改为左侧悬浮面板.
  /// - 白底页面的内容收窄为居中的一栏.
  wide,
}

/// 按屏幕尺寸计算的版式参数. 页面和骨架统一使用本类, 不各自计算断点和尺寸.
@immutable
class const EatLayout({
  required final WidthClass widthClass,
  required final Size screen,
}) {
  factory EatLayout.of(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return EatLayout(
      widthClass: screen.width >= wideBreakpoint
          ? WidthClass.wide
          : screen.width < narrowBreakpoint
          ? WidthClass.narrow
          : WidthClass.phone,
      screen: screen,
    );
  }

  static const narrowBreakpoint = 360.0;
  static const wideBreakpoint = 600.0;

  /// 宽屏左侧悬浮面板的宽度. [widePanelInset] 是面板与屏幕边缘的距离.
  static const widePanelWidth = 400.0;
  static const widePanelInset = EatSpace.s16;

  /// 宽屏时导航位于面板底部. 该值是导航与面板左右边缘及底边的距离.
  static const widePanelNavInset = EatSpace.s20;

  /// 宽屏白底页面内容栏的最大宽度, 含左右边距.
  static const plainMaxWidth = 480.0;

  bool get isWide => widthClass == WidthClass.wide;

  /// 舞台高度.
  ///
  /// 手机上以 844 高的屏幕为基准, 按屏幕高度等比缩放 [EatSize.stage], 并限制在
  /// [EatSize.stageMin] 到 [EatSize.stageMax] 之间. 超出上限的屏幕高度留给抽屉.
  /// 宽屏时舞台铺满屏幕.
  double get stageHeight => isWide
      ? screen.height
      : (screen.height * EatSize.stage / 844).clamp(
          EatSize.stageMin,
          EatSize.stageMax,
        );

  /// 盘子和转盘随舞台高度等比缩放的系数.
  double get stageScale => stageHeight / EatSize.stage;

  // TODO: 舞台页未把菜名字号限制在 36px 以上, 320 宽的屏幕上三行菜名只有约 34px. 各舞台页按 36px 下限夹取字号后删除本条.
  /// 窄屏上舞台菜名和价格的缩小系数. 其余宽度为 1.
  double get stageTextScale =>
      widthClass == WidthClass.narrow ? screen.width / narrowBreakpoint : 1;

  /// 白底页面内容的左右留白.
  ///
  /// 手机上等于页面边距. 宽屏时额外加上使内容栏居中所需的留白.
  double get plainHorizontalPadding => isWide
      ? ((screen.width - plainMaxWidth) / 2).clamp(0.0, double.infinity) +
            EatSpace.s20
      : EatSpace.s20;
}
