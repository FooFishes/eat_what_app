import 'package:flutter/painting.dart';

/// 内置的两个字体族，文件和许可证在 `assets/fonts/`。
abstract final class EatFonts {
  /// 全部中文。
  static const sans = 'NotoSansSC';

  /// 只排数字：价格、距离、统计、计数。
  static const numeral = 'BricolageGrotesque';
}

/// 设计规范里的 20 个文字样式。
///
/// 样式不带颜色：同一个样式在白底上用 `ink`，在舞台上用舞台文字色，颜色由所在的组件给。
class EatTextStyles({
  /// 舞台上的菜名、店名，每行不超过四个字。
  required final TextStyle stageDish,

  /// 只用在登录页的品牌字。
  required final TextStyle loginDisplay,

  /// 白底页面的大标题。
  required final TextStyle pageTitle,

  /// 流程页用一句问话当标题。
  required final TextStyle questionTitle,

  /// 「我的」和他人主页上的昵称。
  required final TextStyle profileName,

  /// 抽屉里的分区标题。
  required final TextStyle sectionTitle,

  /// 分类标签的选中项。选中靠字重，不靠颜色。
  required final TextStyle tabActive,

  /// 分类标签的未选中项，配 `ink-muted`。
  required final TextStyle tab,

  /// 列表行的主标题。
  required final TextStyle rowTitle,

  /// 菜品方块下方的菜名。
  required final TextStyle tileTitle,

  /// 描述、上传者说的话、消息正文。
  required final TextStyle body,

  /// 52px 高的按钮文字。
  required final TextStyle buttonLabel,

  /// 次级信息，配 `ink-muted` 或 `ink-soft`。
  required final TextStyle meta,

  /// 时间、数量单位、表单标签下的说明。
  required final TextStyle caption,

  /// 底部导航文字，选中时换成 700。
  required final TextStyle navLabel,

  /// 舞台上的价格。
  required final TextStyle priceHero,

  /// 主页统计数字。
  required final TextStyle stat,

  /// 列表和方块里的价格。
  required final TextStyle priceInline,

  /// 距离，数字和单位之间留一个空格。
  required final TextStyle distance,

  /// 跟在文字后面的计数：标签次数、赞数。
  required final TextStyle count,
}) {
  static final standard = EatTextStyles(
    stageDish: _sans(46, 50, 900, letterSpacing: -1),
    loginDisplay: _sans(60, 64, 900, letterSpacing: -1.5),
    pageTitle: _sans(34, 42, 900),
    questionTitle: _sans(32, 40, 900),
    profileName: _sans(30, 38, 900, letterSpacing: -0.5),
    sectionTitle: _sans(20, 28, 900),
    tabActive: _sans(17, 24, 900),
    tab: _sans(15, 24, 400),
    rowTitle: _sans(16, 24, 700),
    tileTitle: _sans(15, 22, 600),
    body: _sans(15, 24, 400),
    buttonLabel: _sans(16, 24, 600),
    meta: _sans(13, 20, 400),
    caption: _sans(12, 18, 400),
    navLabel: _sans(11, 16, 500),
    priceHero: _numeral(60, 60, 800, letterSpacing: -2),
    stat: _numeral(30, 32, 800),
    priceInline: _numeral(18, 24, 800),
    distance: _numeral(14, 20, 600),
    count: _numeral(13, 18, 800),
  );
}

TextStyle _sans(
  double size,
  double lineHeight,
  int weight, {
  double? letterSpacing,
}) => TextStyle(
  fontFamily: EatFonts.sans,
  fontSize: size,
  height: lineHeight / size,
  leadingDistribution: TextLeadingDistribution.even,
  fontWeight: FontWeight(weight),
  letterSpacing: letterSpacing,
);

/// 光学尺寸取字号：设计稿在浏览器里按字号自动选 `opsz`，这里照做才和画板一致。
TextStyle _numeral(
  double size,
  double lineHeight,
  int weight, {
  double? letterSpacing,
}) => TextStyle(
  fontFamily: EatFonts.numeral,
  fontFamilyFallback: const [EatFonts.sans],
  fontSize: size,
  height: lineHeight / size,
  leadingDistribution: TextLeadingDistribution.even,
  fontWeight: FontWeight(weight),
  fontVariations: [FontVariation.opticalSize(size)],
  letterSpacing: letterSpacing,
);
