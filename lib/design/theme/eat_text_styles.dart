import 'package:flutter/painting.dart';

/// 内置字体族. 字体文件和许可证位于 `assets/fonts/`.
abstract final class EatFonts {
  /// 中文字体, 用于全部中文文字.
  static const sans = 'NotoSansSC';

  /// 数字字体, 只用于价格, 距离, 统计和计数.
  static const numeral = 'Inter';
}

/// 设计规范中的文字样式.
///
/// 样式不含颜色. 同一样式在白底上用 `ink`, 在舞台上用舞台文字色, 颜色由所在组件指定.
class EatTextStyles({
  /// 舞台上的菜名和店名. 每行不超过四个字.
  required final TextStyle stageDish,

  /// 登录页的品牌字, 不用于其他位置.
  required final TextStyle loginDisplay,

  /// 白底页面的大标题.
  required final TextStyle pageTitle,

  /// 流程页的问句式标题.
  required final TextStyle questionTitle,

  /// "我的" 和他人主页上的昵称.
  required final TextStyle profileName,

  /// 抽屉中的分区标题.
  required final TextStyle sectionTitle,

  /// 分类标签的选中项. 选中态通过字重区分, 不通过颜色区分.
  required final TextStyle tabActive,

  /// 分类标签的未选中项, 搭配 `ink-muted`.
  required final TextStyle tab,

  /// 列表行的主标题.
  required final TextStyle rowTitle,

  /// 菜品方块下方的菜名.
  required final TextStyle tileTitle,

  /// 正文: 描述, 上传者的说明, 消息内容.
  required final TextStyle body,

  /// 主按钮文字.
  required final TextStyle buttonLabel,

  /// 次级信息, 搭配 `ink-muted` 或 `ink-soft`.
  required final TextStyle meta,

  /// 辅助信息: 时间, 数量单位, 表单标签下的说明.
  required final TextStyle caption,

  /// 底部导航文字. 选中项的字重改为 700.
  required final TextStyle navLabel,

  /// 舞台上的价格.
  required final TextStyle priceHero,

  /// 主页的统计数字.
  required final TextStyle stat,

  /// 列表和菜品方块中的价格.
  required final TextStyle priceInline,

  /// 距离. 数字和单位之间留一个空格.
  required final TextStyle distance,

  /// 跟在文字后面的计数, 如标签次数和赞数.
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
    priceHero: _numeral(60, 60, 800, letterSpacing: -1),
    stat: _numeral(30, 32, 800),
    priceInline: _numeral(18, 24, 800),
    distance: _numeral(14, 20, 600),
    count: _numeral(13, 18, 800, tabular: true),
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

/// 数字样式. 光学尺寸跟随字号, 超出 Inter `opsz` 轴的 14–32 范围时取端点值.
///
/// [tabular] 启用等宽数字, 用于原地变化的计数, 避免数字变化时宽度跳动.
TextStyle _numeral(
  double size,
  double lineHeight,
  int weight, {
  double? letterSpacing,
  bool tabular = false,
}) => TextStyle(
  fontFamily: EatFonts.numeral,
  fontFamilyFallback: const [EatFonts.sans],
  fontSize: size,
  height: lineHeight / size,
  leadingDistribution: TextLeadingDistribution.even,
  fontWeight: FontWeight(weight),
  fontVariations: [FontVariation.opticalSize(size.clamp(14, 32))],
  fontFeatures: [if (tabular) const FontFeature.tabularFigures()],
  letterSpacing: letterSpacing,
);
