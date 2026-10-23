import 'dart:ui';

/// 间距，`space-4` 到 `space-24` 七档。
abstract final class EatSpace {
  /// 图标和文字之间、计数和标签之间。
  static const s4 = 4.0;

  /// 标签之间、紧凑的纵向堆叠。
  static const s8 = 8.0;

  /// 成对按钮之间。
  static const s10 = 10.0;

  /// 列表行里缩略图和文字之间、抽屉内的分区间距。
  static const s14 = 14.0;

  /// 悬浮导航距屏幕左右、分区之间。
  static const s16 = 16.0;

  /// 页面左右边距，所有页面统一。
  static const s20 = 20.0;

  /// 悬浮导航距屏幕底部、大分区之间。
  static const s24 = 24.0;
}

/// 圆角。
///
/// 没有 `radius-plate`：盘子、头像、地图标记永远是正圆，用 `BoxShape.circle` 或 `ClipOval`，
/// 不靠一个足够大的圆角去凑。
abstract final class EatRadius {
  /// 按钮、标签、搜索框、导航胶囊。
  static const pill = Radius.circular(999);

  /// 抽屉顶部两角、底部面板。
  static const sheet = Radius.circular(28);

  /// 菜品方块、舞台色预览卡。
  static const tile = Radius.circular(22);

  /// 64px 缩略图。
  static const thumbLg = Radius.circular(18);

  /// 48–56px 缩略图。
  static const thumb = Radius.circular(16);
}

/// 尺寸。
abstract final class EatSize {
  /// 最小点击区域，图标按钮都不小于它。
  static const touch = 44.0;

  /// 主按钮高度。
  static const button = 52.0;

  /// 分类和标签的高度，点击区域向外扩到 [touch]。
  static const chip = 36.0;

  /// 悬浮导航胶囊和发布按钮的高度。
  static const nav = 60.0;

  /// 消息里的头像。
  static const avatar = 44.0;

  /// 选店、加菜里的缩略图。
  static const thumb = 52.0;

  /// 附近列表的缩略图。
  static const thumbLg = 64.0;

  /// 844 高的屏幕上首页舞台的高度，随屏幕高度在 [stageMin] 到 [stageMax] 之间伸缩。
  static const stage = 520.0;
  static const stageMin = 420.0;
  static const stageMax = 560.0;

  /// 抽屉往上压住舞台的高度。
  static const sheetOverlap = 32.0;

  /// 舞台上主菜盘子的外框，右侧出血。
  static const plate = 320.0;

  /// 盘子的白色盘沿宽度；缩小使用时按比例缩到 4–6px。
  static const plateRim = 8.0;

  /// 转盘上菜的位置到圆心的距离。
  static const turntableRadius = 430.0;
}
