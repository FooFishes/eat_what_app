import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 屏幕宽度的三档。
enum WidthClass {
  /// 360 以下：铺满，舞台菜名、价格按宽度缩小。
  narrow,

  /// 360–599：铺满，左右边距 `space-20`。
  phone,

  /// 600 及以上：舞台铺满，抽屉变成左侧悬浮面板；白底页面居中一栏。
  wide,
}

/// 按屏幕尺寸算好的版式参数，页面和骨架从这里取，不自己算。
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

  /// 宽屏左侧悬浮面板的宽度和离屏幕边的距离。
  static const widePanelWidth = 400.0;
  static const widePanelInset = EatSpace.s16;

  /// 宽屏时导航放在面板底部，离面板左右和底部的距离。
  static const widePanelNavInset = EatSpace.s20;

  /// 宽屏白底页面那一栏的最大宽度（含左右边距）。
  static const plainMaxWidth = 480.0;

  bool get isWide => widthClass == WidthClass.wide;

  /// 手机上舞台的高度：844 高的屏幕正好 520，按屏幕高度伸缩，夹在 420 到 560 之间；
  /// 高屏多出来的高度给抽屉。宽屏的舞台铺满整个屏幕。
  double get stageHeight => isWide
      ? screen.height
      : (screen.height * EatSize.stage / 844).clamp(
          EatSize.stageMin,
          EatSize.stageMax,
        );

  /// 盘子、转盘跟着舞台高度等比缩放的系数。
  double get stageScale => stageHeight / EatSize.stage;

  /// 窄手机上舞台菜名、价格的缩小系数（菜名最小 36px 由页面再夹）。
  double get stageTextScale =>
      widthClass == WidthClass.narrow ? screen.width / narrowBreakpoint : 1;

  /// 白底页面内容两侧的留白：手机上是页面边距，宽屏时再把一栏挤到中间。
  double get plainHorizontalPadding => isWide
      ? ((screen.width - plainMaxWidth) / 2).clamp(0.0, double.infinity) +
            EatSpace.s20
      : EatSpace.s20;
}
