import 'dart:ui';

/// 间距令牌, 对应设计令牌 `space-*`.
abstract final class EatSpace {
  /// 最紧凑的间距, 用于图标与文字之间, 计数与标签之间.
  static const s4 = 4.0;

  /// 标签之间的间距, 也用于紧凑的纵向堆叠.
  static const s8 = 8.0;

  /// 成对按钮之间的间距.
  static const s10 = 10.0;

  /// 列表行中缩略图与文字之间的间距, 也是抽屉内的分区间距.
  static const s14 = 14.0;

  /// 悬浮导航与屏幕左右边缘的距离, 也用于分区之间.
  static const s16 = 16.0;

  /// 页面左右边距, 所有页面统一使用.
  static const s20 = 20.0;

  /// 悬浮导航与屏幕底边的距离, 也用于大分区之间.
  static const s24 = 24.0;
}

/// 圆角令牌.
///
/// 不提供 `radius-plate`. 盘子, 头像和地图标记必须是正圆, 使用 `BoxShape.circle` 或 `ClipOval` 实现,
/// 不使用足够大的圆角近似.
abstract final class EatRadius {
  /// 胶囊形圆角, 用于按钮, 标签, 搜索框和导航胶囊.
  static const pill = Radius.circular(999);

  /// 抽屉顶部两角和底部面板的圆角.
  static const sheet = Radius.circular(28);

  /// 菜品方块和舞台色预览卡的圆角.
  static const tile = Radius.circular(22);

  /// [EatSize.thumbLg] 尺寸缩略图的圆角.
  static const thumbLg = Radius.circular(18);

  /// 48–56px 缩略图的圆角.
  static const thumb = Radius.circular(16);
}

/// 尺寸令牌.
abstract final class EatSize {
  /// 最小点击区域. 所有可点击元素的点击区域都不小于该值.
  static const touch = 44.0;

  /// 主按钮高度.
  static const button = 52.0;

  /// 分类和标签的高度. 点击区域向外扩展到 [touch].
  static const chip = 36.0;

  /// 悬浮导航胶囊和发布按钮的高度.
  static const nav = 60.0;

  /// 消息列表中的头像直径.
  static const avatar = 44.0;

  /// 选店和加菜页中的缩略图边长.
  static const thumb = 52.0;

  /// 附近列表中的缩略图边长.
  static const thumbLg = 64.0;

  /// 844 高的屏幕上首页舞台的高度.
  ///
  /// 其他屏幕按高度等比缩放, 并限制在 [stageMin] 到 [stageMax] 之间.
  static const stage = 520.0;
  static const stageMin = 420.0;
  static const stageMax = 560.0;

  /// 抽屉向上覆盖舞台的高度.
  static const sheetOverlap = 32.0;

  /// 舞台上主菜盘子的外框尺寸. 盘子在舞台右侧出血.
  static const plate = 320.0;

  /// 舞台主图盘子的白色盘沿宽度. 较小的盘子按尺寸缩小盘沿, 见 `DishPlate`.
  static const plateRim = 8.0;

  /// 转盘上菜品中心到转盘圆心的距离.
  static const turntableRadius = 430.0;
}
