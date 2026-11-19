import 'dart:ui';

/// 全部颜色的原始值. 命名沿用设计令牌, 去掉连字符并改为驼峰, 如 `ink-muted` 对应 `inkMuted`.
///
/// 组件不直接读取本类: 白底页面的颜色取自 `context.eat.colors`, 舞台上的颜色取自 `StageColor`.
/// 本类只供上述两处引用, 因为 `EatColors.light.ink` 这类取值不是常量表达式, 无法用于 `StageColor` 的 const 构造.
abstract final class EatPalette {
  static const ink = Color(0xFF231C18);
  static const inkMuted = Color(0xFF6E625B);
  static const inkSoft = Color(0xFF4A3C31);
  static const paper = Color(0xFFFFFFFF);
  static const mist = Color(0xFFF3F2F0);
  static const inkTop = Color(0xFF3B312B);
  static const tagSelected = Color(0xFFFBEFD9);
  static const hairline = Color(0xFFEFE9E4);
  static const handle = Color(0xFFE6DED8);
  static const scrim = Color.fromRGBO(35, 28, 24, 0.45);
  static const lineStrong = Color(0xFF9A8B80);
  static const disabledBg = Color(0xFFEFEEEC);
  static const disabledFg = Color(0xFFB0ADA9);
  static const warn = Color(0xFFA8321C);

  /// 深色模式的界面颜色, 和上面同名的浅色值一一对应. 地图和 "调整照片" 页的颜色不分深浅.
  static const darkInk = Color(0xFFF2ECE7);
  static const darkInkMuted = Color(0xFFA89D95);
  static const darkInkSoft = Color(0xFFD2C7BF);
  static const darkPaper = Color(0xFF171210);
  static const darkMist = Color(0xFF282220);
  static const darkInkTop = Color(0xFFFFFFFF);
  static const darkTagSelected = Color(0xFF3A2E1C);
  static const darkHairline = Color(0xFF2C2623);
  static const darkHandle = Color(0xFF3E3632);
  static const darkScrim = Color.fromRGBO(0, 0, 0, 0.6);
  static const darkLineStrong = Color(0xFF847770);
  static const darkDisabledBg = Color(0xFF26211E);
  static const darkDisabledFg = Color(0xFF5F5853);
  static const darkWarn = Color(0xFFE35B3F);

  static const mapMe = Color(0xFF2F6FEB);
  static const mapGround = Color(0xFFECE5D8);
  static const mapBlock = Color(0xFFE2D9C8);
  static const mapPark = Color(0xFFD2E1C2);

  static const stageBroth = Color(0xFFF3C46E);
  static const stageMango = Color(0xFFFFCB45);
  static const stageBamboo = Color(0xFFD8B27A);
  static const stageChili = Color(0xFFD9632B);
  static const stageTomato = Color(0xFFC9442B);
  static const stageRedoil = Color(0xFFA8321C);
  static const stageSoy = Color(0xFF8F5B24);
  static const stagePorcelain = Color(0xFF9DB8D9);
  static const stageMatcha = Color(0xFF9DBF7A);

  /// 深色模式下的舞台色: 在上面的值里混入黑色压暗, 浅色舞台最多 15%, 以 `ink` 和 `ink-soft` 仍不低于 4.5:1 为限;
  /// 深色舞台 15%. `chili` 的 `ink` 只有 4.6:1, 再暗就不够, 所以不变.
  static const stageBrothDark = Color(0xFFCFA75E);
  static const stageMangoDark = Color(0xFFD9AD3B);
  static const stageBambooDark = Color(0xFFC7A470);
  static const stageChiliDark = stageChili;
  static const stageTomatoDark = Color(0xFFAB3A25);
  static const stageRedoilDark = Color(0xFF8F2A18);
  static const stageSoyDark = Color(0xFF7A4D1F);
  static const stagePorcelainDark = Color(0xFF94ADCC);
  static const stageMatchaDark = Color(0xFF94B473);
  static const stageGhostLight = Color.fromRGBO(255, 255, 255, 0.42);
  static const stageGhostDark = Color.fromRGBO(255, 255, 255, 0.18);
  static const tableLight = Color.fromRGBO(255, 255, 255, 0.22);
  static const tableDark = Color.fromRGBO(255, 255, 255, 0.07);
  static const tableRingLight = Color.fromRGBO(255, 255, 255, 0.55);
  static const tableRingDark = Color.fromRGBO(255, 255, 255, 0.22);

  static const cropGround = Color(0xFF15110E);
  static const cropPanel = Color(0xFF221C18);
  static const cropScrim = Color.fromRGBO(21, 17, 14, 0.66);
}
