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
  static const mist = Color(0xFFF4EFEB);
  static const inkTop = Color(0xFF3B312B);
  static const mistTop = Color(0xFFFBF8F6);
  static const paperBottom = Color(0xFFEFE8E2);
  static const tagSelected = Color(0xFFFBEFD9);
  static const hairline = Color(0xFFEFE9E4);
  static const handle = Color(0xFFE6DED8);
  static const scrim = Color.fromRGBO(35, 28, 24, 0.45);
  static const lineStrong = Color(0xFF9A8B80);
  static const disabledBg = Color(0xFFE9E2DC);
  static const disabledFg = Color(0xFF8A7E76);
  static const warn = Color(0xFFA8321C);

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
