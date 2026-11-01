import 'dart:ui';

import 'package:eat/design/tokens/eat_palette.dart';

/// 舞台以外的颜色: 白底页面, 抽屉, 面板, 地图和 "调整照片" 页. 舞台上的颜色取自 `StageColor`.
class const EatColors({
  /// 主文字色, 也是主操作和选中单选标签的实心底色.
  required final Color ink,

  /// 白底上的次级文字色.
  required final Color inkMuted,

  /// 浅色舞台上的次级文字色.
  required final Color inkSoft,

  /// 纸面底色, 用于抽屉, 白底页面和悬浮导航. 也是深色舞台上的文字色.
  required final Color paper,

  /// 次级填充色, 用于次按钮, 搜索框, 导航选中项和未选中分类标签的底色.
  required final Color mist,

  /// 实心按钮渐变的顶部颜色, 向下渐变到 [ink].
  required final Color inkTop,

  /// 雾面按钮渐变的顶部颜色, 向下渐变到 [mist].
  required final Color mistTop,

  /// 深色舞台上白色实心按钮渐变的底部颜色.
  required final Color paperBottom,

  /// 多选标签选中后的底色, 搭配 [ink] 描边和文字.
  required final Color tagSelected,

  /// 分隔线颜色, 包括底部操作栏的上沿.
  required final Color hairline,

  /// 低对比度的线条色, 用于抽屉把手, 输入框下划线和关闭状态的开关轨道.
  required final Color handle,

  /// 底部面板背后的遮罩色.
  required final Color scrim,

  /// 需要醒目的描边色, 用于虚线按钮, 未选中的单选圆圈和 "待接入" 标记.
  required final Color lineStrong,
  required final Color disabledBg,
  required final Color disabledFg,

  /// 提示用户需要处理的文字色. 只用在 [paper] 上, 且必须配文字说明.
  required final Color warn,
  required final Color mapMe,
  required final Color mapGround,
  required final Color mapBlock,
  required final Color mapPark,
  required final Color cropGround,
  required final Color cropPanel,
  required final Color cropScrim,
}) {
  static const light = EatColors(
    ink: EatPalette.ink,
    inkMuted: EatPalette.inkMuted,
    inkSoft: EatPalette.inkSoft,
    paper: EatPalette.paper,
    mist: EatPalette.mist,
    inkTop: EatPalette.inkTop,
    mistTop: EatPalette.mistTop,
    paperBottom: EatPalette.paperBottom,
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
  );
}
