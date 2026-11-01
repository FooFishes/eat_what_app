import 'dart:ui';

import 'package:eat/design/tokens/eat_palette.dart';

/// 舞台只能用的 9 个颜色。每个值带着自己整套配色，深浅写死，不在运行时按亮度去猜。
enum StageColor {
  broth(EatPalette.stageBroth, '汤色', isDark: false),
  mango(EatPalette.stageMango, '芒果黄', isDark: false),
  bamboo(EatPalette.stageBamboo, '竹屉', isDark: false),
  chili(EatPalette.stageChili, '辣橙', isDark: false),
  porcelain(EatPalette.stagePorcelain, '青花蓝', isDark: false),
  matcha(EatPalette.stageMatcha, '抹茶绿', isDark: false),
  tomato(EatPalette.stageTomato, '番茄红', isDark: true),
  redoil(EatPalette.stageRedoil, '红油', isDark: true),
  soy(EatPalette.stageSoy, '酱色', isDark: true);

  const new(this.color, this.label, {required this.isDark});

  /// 舞台底色。
  final Color color;

  /// 给人看的名字，「调整照片」里色圆下面写的。
  final String label;

  /// 深色舞台上文字用 `paper`，浅色舞台上用 `ink`。
  final bool isDark;

  /// 令牌名，如 `stage-broth`。接口里的舞台色字段也用这个写法。
  String get token => 'stage-$name';

  /// 按令牌名找舞台色，不认识的返回 null。
  static StageColor? fromToken(String token) {
    for (final value in values) {
      if (value.token == token) return value;
    }
    return null;
  }

  /// 舞台上的主文字：菜名、价格、按钮文字。
  Color get foreground => isDark ? EatPalette.paper : EatPalette.ink;

  /// 舞台上的次级文字：签名、说明。
  ///
  /// 次级文字平时比主文字淡一档（浅色舞台 `ink-soft`，深色舞台 85% 的 `paper`），但 `chili` 上
  /// `ink-soft` 只有 2.9:1、`tomato` 上 85% 的 `paper` 只有 3.9:1，都不到 4.5:1，这两个舞台的
  /// 次级文字和主文字同色。
  Color get secondaryForeground => switch (this) {
    chili || tomato => foreground,
    _ when isDark => _paper85,
    _ => EatPalette.inkSoft,
  };

  /// 次按钮（换一个、编辑资料）的底色，文字用 [foreground]。
  Color get ghost =>
      isDark ? EatPalette.stageGhostDark : EatPalette.stageGhostLight;

  /// 转盘桌面。
  Color get table => isDark ? EatPalette.tableDark : EatPalette.tableLight;

  /// 转盘的细边。
  Color get tableRing =>
      isDark ? EatPalette.tableRingDark : EatPalette.tableRingLight;

  /// 实心按钮渐变的顶部颜色。按钮文字用舞台色 [color]。
  Color get solidTop => isDark ? EatPalette.paper : EatPalette.inkTop;

  /// 实心按钮渐变的底部颜色。
  Color get solidBottom => isDark ? EatPalette.paperBottom : EatPalette.ink;
}

const _paper85 = Color.fromRGBO(255, 255, 255, 0.85);
