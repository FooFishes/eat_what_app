import 'dart:ui';

import 'package:eat/design/tokens/eat_palette.dart';

/// 舞台可用的全部颜色.
///
/// 每个枚举值自带整套配色, 深浅固定声明在枚举上, 不在运行时按亮度推断.
///
/// 系统深色模式下舞台底色换成压暗的 [darkColor], 文字色和舞台的深浅分类不变; 照片取色只和 [color] 比较.
enum StageColor {
  broth(EatPalette.stageBroth, EatPalette.stageBrothDark, '汤色', isDark: false),
  mango(EatPalette.stageMango, EatPalette.stageMangoDark, '芒果黄', isDark: false),
  bamboo(
    EatPalette.stageBamboo,
    EatPalette.stageBambooDark,
    '竹屉',
    isDark: false,
  ),
  chili(EatPalette.stageChili, EatPalette.stageChiliDark, '辣橙', isDark: false),
  porcelain(
    EatPalette.stagePorcelain,
    EatPalette.stagePorcelainDark,
    '青花蓝',
    isDark: false,
  ),
  matcha(
    EatPalette.stageMatcha,
    EatPalette.stageMatchaDark,
    '抹茶绿',
    isDark: false,
  ),
  tomato(
    EatPalette.stageTomato,
    EatPalette.stageTomatoDark,
    '番茄红',
    isDark: true,
  ),
  redoil(
    EatPalette.stageRedoil,
    EatPalette.stageRedoilDark,
    '红油',
    isDark: true,
  ),
  soy(EatPalette.stageSoy, EatPalette.stageSoyDark, '酱色', isDark: true);

  const new(this.color, this.darkColor, this.label, {required this.isDark});

  /// 舞台底色.
  final Color color;

  /// 系统深色模式下的舞台底色.
  final Color darkColor;

  /// 按界面深浅取舞台底色.
  Color colorIn({required bool dark}) => dark ? darkColor : color;

  /// 界面上显示的颜色名, 出现在 "调整照片" 的色圆下方.
  final String label;

  /// 是否为深色舞台. 深色舞台上的文字使用 `paper`, 浅色舞台上使用 `ink`.
  final bool isDark;

  /// 令牌名 (如 `stage-broth`), 接口中的舞台色字段使用相同写法.
  String get token => 'stage-$name';

  /// 按令牌名查找舞台色, 无法识别时返回 null.
  static StageColor? fromToken(String token) {
    for (final value in values) {
      if (value.token == token) return value;
    }
    return null;
  }

  /// 舞台上的主文字色, 用于菜名, 价格和按钮文字.
  Color get foreground => isDark ? EatPalette.paper : EatPalette.ink;

  /// 舞台上的次级文字色, 用于签名和说明.
  ///
  /// 次级文字通常比主文字淡一档: 浅色舞台用 `ink-soft`, 深色舞台用 85% 不透明度的 `paper`.
  /// `chili` 和 `tomato` 例外, 次级文字与主文字同色, 因为 `ink-soft` 在 `chili` 上的对比度只有 2.9:1,
  /// 85% 不透明度的 `paper` 在 `tomato` 上只有 3.9:1, 均低于 4.5:1.
  Color get secondaryForeground => switch (this) {
    chili || tomato => foreground,
    _ when isDark => _paper85,
    _ => EatPalette.inkSoft,
  };

  /// 舞台上次按钮的底色 (如 "换一个", "编辑资料"), 文字使用 [foreground].
  Color get ghost =>
      isDark ? EatPalette.stageGhostDark : EatPalette.stageGhostLight;

  /// 转盘桌面的颜色.
  Color get table => isDark ? EatPalette.tableDark : EatPalette.tableLight;

  /// 转盘细边的颜色.
  Color get tableRing =>
      isDark ? EatPalette.tableRingDark : EatPalette.tableRingLight;

  /// 实心按钮的底色, 按钮文字使用舞台色 [color].
  Color get solid => isDark ? EatPalette.paper : EatPalette.ink;
}

const _paper85 = Color.fromRGBO(255, 255, 255, 0.85);
