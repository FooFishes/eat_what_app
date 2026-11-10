import 'package:flutter/painting.dart';

/// 字体族.
///
/// 文字默认使用系统字体: 安卓为 Roboto 加系统中文字体, iOS 为 SF 加苹方, 因此中文样式不指定字体族.
/// 只有数字使用内置的 Inter, 字体文件和许可证位于 `assets/fonts/`.
abstract final class EatFonts {
  /// 数字字体, 只用于价格, 距离, 统计和计数. 缺字时回落到系统字体.
  static const numeral = 'Inter';
}

/// 文字样式.
///
/// 中文 8 级字号, 数字 4 级并沿用中文的字号. 字重只用 400, 600, 700, 800:
/// 800 只给舞台上的主角, 标题 700, 强调 600, 正文 400.
/// 先用预设; 和预设差得不多的地方, 优先改用预设而不是另写字号.
///
/// 样式不含颜色. 同一样式在白底上用 `ink`, 在舞台上用舞台文字色, 颜色由所在组件指定.
class EatTextStyles({
  /// 登录页的品牌字.
  required final TextStyle display,

  /// 舞台上的菜名和店名. 每行不超过四个字.
  required final TextStyle stage,

  /// 大标题: 流程页的问句, 主页上的昵称.
  required final TextStyle title,

  /// 页面标题和抽屉中的分区标题.
  required final TextStyle heading,

  /// 列表行标题, 按钮文字, 菜品方块下的菜名, 分类标签.
  ///
  /// 分类标签未选中时字重改为 400. 选中态通过字重区分, 不通过颜色区分.
  required final TextStyle subhead,

  /// 正文: 描述, 上传者的说明, 消息内容.
  required final TextStyle body,

  /// 次级信息, 搭配 `ink-muted` 或 `ink-soft`.
  required final TextStyle meta,

  /// 辅助信息: 时间, 数量单位, 表单说明, 底部导航文字.
  required final TextStyle caption,

  /// 舞台上的价格.
  required final TextStyle priceHero,

  /// 主页的统计数字.
  required final TextStyle stat,

  /// 列表和菜品方块中的价格.
  required final TextStyle priceInline,

  /// 距离和跟在文字后面的计数. 距离的数字和单位之间留一个空格.
  required final TextStyle count,
}) {
  static final standard = EatTextStyles(
    display: _sans(56, 60, 800, letterSpacing: -1.5),
    stage: _sans(44, 48, 800, letterSpacing: -1),
    title: _sans(26, 34, 700, letterSpacing: -0.5),
    heading: _sans(20, 28, 700),
    subhead: _sans(16, 24, 600),
    body: _sans(15, 22, 400),
    meta: _sans(13, 20, 400),
    caption: _sans(12, 16, 400),
    priceHero: _numeral(56, 56, 700, letterSpacing: -1),
    stat: _numeral(26, 32, 700),
    priceInline: _numeral(16, 24, 700),
    count: _numeral(13, 18, 600, tabular: true),
  );
}

TextStyle _sans(
  double size,
  double lineHeight,
  int weight, {
  double? letterSpacing,
}) => TextStyle(
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
  fontSize: size,
  height: lineHeight / size,
  leadingDistribution: TextLeadingDistribution.even,
  fontWeight: FontWeight(weight),
  fontVariations: [FontVariation.opticalSize(size.clamp(14, 32))],
  fontFeatures: [if (tabular) const FontFeature.tabularFigures()],
  letterSpacing: letterSpacing,
);
