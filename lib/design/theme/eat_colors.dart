import 'dart:ui';

import 'package:eat/design/tokens/eat_palette.dart';

/// 舞台以外的界面颜色集合, 涵盖白底页面, 抽屉, 面板, 地图和 "调整照片" 页 (舞台颜色取自 `StageColor`).
///
/// 分 [light] 和 [dark] 两套, 跟随系统的深浅设置. 地图和 "调整照片" 页的颜色两套相同, 舞台色的深色值在 `StageColor.darkColor`.
class const EatColors({
  /// 这套颜色的深浅, 决定白底页面上状态栏图标的色调.
  required final Brightness brightness,

  /// 主文字色, 也是主操作和选中单选标签的实心底色.
  required final Color ink,

  /// 白底上的次级文字色.
  required final Color inkMuted,

  /// 比 [inkMuted] 醒目一档的次级文字色. 浅色舞台上的次级文字取自 `StageColor`, 不用这里的值.
  required final Color inkSoft,

  /// 纸面底色, 用于抽屉, 白底页面, 面板和悬浮导航, 也是 [ink] 实心底上的文字色. 深色模式下是深色.
  required final Color paper,

  /// 次级填充色, 用于次按钮, 搜索框, 导航选中项和未选中分类标签的底色.
  required final Color mist,

  /// 开关打开时轨道渐变的顶部颜色, 向下渐变到 [ink].
  required final Color inkTop,

  /// 多选标签选中后的底色, 搭配 [ink] 描边和文字.
  required final Color tagSelected,

  /// 分隔线颜色, 包括底部操作栏的上沿.
  required final Color hairline,

  /// 低对比度的线条色, 用于抽屉把手, 输入框下划线和关闭状态的开关轨道.
  required final Color handle,

  /// 底部面板背后的遮罩色.
  required final Color scrim,

  /// 需要醒目的描边色, 用于补充入口标签, 未选中的单选圆圈和 "待接入" 标记.
  required final Color lineStrong,
  required final Color disabledBg,
  required final Color disabledFg,

  /// 提示用户需要处理的文字色. 仅用于 [paper] 底色之上, 且必须配文字说明.
  required final Color warn,
  required final Color mapMe,
  required final Color mapGround,
  required final Color mapBlock,
  required final Color mapPark,
  required final Color cropGround,
  required final Color cropPanel,
  required final Color cropScrim,

  /// 不分深浅的白色, 用于照片, 照片查看器和 "调整照片" 页上的文字和图标.
  required final Color white,

  /// 不分深浅的深色, 用于压在照片上的半透明遮罩和画出来的投影, 透明度由使用处决定.
  required final Color shade,
}) {
  bool get isDark => brightness == Brightness.dark;

  static const light = EatColors(
    brightness: Brightness.light,
    ink: EatPalette.ink,
    inkMuted: EatPalette.inkMuted,
    inkSoft: EatPalette.inkSoft,
    paper: EatPalette.paper,
    mist: EatPalette.mist,
    inkTop: EatPalette.inkTop,
    tagSelected: EatPalette.tagSelected,
    hairline: EatPalette.hairline,
    handle: EatPalette.handle,
    scrim: EatPalette.scrim,
    lineStrong: EatPalette.lineStrong,
    disabledBg: EatPalette.disabledBg,
    disabledFg: EatPalette.disabledFg,
    warn: EatPalette.warn,
    mapMe: EatPalette.mapMe,
    mapGround: EatPalette.mapGround,
    mapBlock: EatPalette.mapBlock,
    mapPark: EatPalette.mapPark,
    cropGround: EatPalette.cropGround,
    cropPanel: EatPalette.cropPanel,
    cropScrim: EatPalette.cropScrim,
    white: EatPalette.paper,
    shade: EatPalette.ink,
  );

  static const dark = EatColors(
    brightness: Brightness.dark,
    ink: EatPalette.darkInk,
    inkMuted: EatPalette.darkInkMuted,
    inkSoft: EatPalette.darkInkSoft,
    paper: EatPalette.darkPaper,
    mist: EatPalette.darkMist,
    inkTop: EatPalette.darkInkTop,
    tagSelected: EatPalette.darkTagSelected,
    hairline: EatPalette.darkHairline,
    handle: EatPalette.darkHandle,
    scrim: EatPalette.darkScrim,
    lineStrong: EatPalette.darkLineStrong,
    disabledBg: EatPalette.darkDisabledBg,
    disabledFg: EatPalette.darkDisabledFg,
    warn: EatPalette.darkWarn,
    mapMe: EatPalette.mapMe,
    mapGround: EatPalette.mapGroundDark,
    mapBlock: EatPalette.mapBlockDark,
    mapPark: EatPalette.mapParkDark,
    cropGround: EatPalette.cropGround,
    cropPanel: EatPalette.cropPanel,
    cropScrim: EatPalette.cropScrim,
    white: EatPalette.paper,
    shade: EatPalette.ink,
  );
}
