import 'dart:ui';

import 'package:eat/design/tokens/eat_palette.dart';

/// 舞台以外的颜色：白底页面、抽屉、面板、地图和调整照片页。舞台上的颜色从 `StageColor` 取。
class const EatColors({
  /// 主文字、实心按钮底、选中的单选标签底。
  required final Color ink,

  /// 白底上的次级文字：店名、距离说明、时间、未选中的分类。
  required final Color inkMuted,

  /// 浅色舞台上的次级文字。
  required final Color inkSoft,

  /// 抽屉、白底页面、悬浮导航的底色；深色舞台上的文字。
  required final Color paper,

  /// 次按钮底、搜索框底、导航选中项底、未选中的分类标签底。
  required final Color mist,

  /// 实心按钮渐变的顶部颜色，往下渐变到 [ink]。
  required final Color inkTop,

  /// 雾面按钮渐变的顶部颜色，往下渐变到 [mist]。
  required final Color mistTop,

  /// 深色舞台上白色实心按钮渐变的底部颜色。
  required final Color paperBottom,

  /// 多选标签选中后的底色，配 [ink] 描边和文字。
  required final Color tagSelected,

  /// 分隔线、底部操作栏上沿。
  required final Color hairline,

  /// 抽屉把手、输入框下划线、开关关着时的轨道。
  required final Color handle,

  /// 底部面板背后的遮罩。
  required final Color scrim,

  /// 需要被看见的描边：虚线按钮、未选中的单选圆圈、「待接入」标记。
  required final Color lineStrong,
  required final Color disabledBg,
  required final Color disabledFg,

  /// 需要用户处理的提示文字，只用在 [paper] 上，一定配文字说明。
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
