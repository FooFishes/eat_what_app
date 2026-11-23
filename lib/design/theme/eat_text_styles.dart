import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// 字体族. 字体文件和许可证位于 `assets/fonts/`.
///
/// 中文在安卓上使用内置的 Noto Sans SC: 各厂商的系统中文字体大小和字重差别明显, 内置后各机型显示一致.
/// iOS 使用系统的苹方. Web 无法使用浏览器的系统字体, 由引擎按需下载回落字体;
/// 不内置是因为 Web 会在首帧前下载全部声明的字体, 首屏将多出约 4 MB.
/// 数字三端都使用内置的 Inter.
abstract final class EatFonts {
  /// 安卓内置的中文字体族名.
  static const bundledSans = 'NotoSansSC';

  /// 数字字体, 仅用于价格, 距离, 统计和计数; 缺字时回落到中文字体.
  static const numeral = 'Inter';

  /// 中文字体文件. 只打进安卓包 (`pubspec.yaml` 中限定了平台), 由 [loadSans] 在启动时注册.
  ///
  /// 不写在 `fonts` 中: 那里的字体在 Web 上会于首帧前全部下载.
  static const _sansAsset = 'assets/fonts/NotoSansSC-VF.ttf';

  /// 当前平台的中文字体族; 为 null 时使用系统字体.
  static final String? sans = sansFor(defaultTargetPlatform, isWeb: kIsWeb);

  /// 给定平台的中文字体族.
  @visibleForTesting
  static String? sansFor(TargetPlatform platform, {required bool isWeb}) =>
      !isWeb && platform == TargetPlatform.android ? bundledSans : null;

  /// 注册内置的中文字体, 需在首帧前完成, 否则首帧会先用系统字体排版.
  ///
  /// 加载失败时上报错误并继续启动, 文字回落到系统字体.
  static Future<void> loadSans() async {
    final family = sans;
    if (family == null) return;
    try {
      await (FontLoader(family)..addFont(rootBundle.load(_sansAsset))).load();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'eat design',
          context: ErrorDescription('加载内置中文字体'),
        ),
      );
    }
  }
}

/// 文字样式表.
///
/// 中文分为 8 级字号, 数字分为 4 级并沿用中文的字号. 字重只用 400, 600, 700, 780:
/// 780 ([heavyWeight]) 只给舞台上的主角, 标题 700, 强调 600, 正文 400.
/// 优先使用预设; 若与预设相差不大, 应改用预设而非另写字号.
///
/// 样式不含颜色. 同一样式在白底上用 `ink`, 在舞台上用舞台文字色, 颜色由所在组件指定.
class EatTextStyles({
  /// 登录页的品牌字.
  required final TextStyle display,

  /// 舞台上的菜名和店名, 每行不超过四个字.
  required final TextStyle stage,

  /// 大标题, 用于流程页的问句和主页上的昵称.
  required final TextStyle title,

  /// 页面标题和抽屉中的分区标题.
  required final TextStyle heading,

  /// 列表行标题, 按钮文字, 菜品方块下的菜名及分类标签.
  ///
  /// 分类标签未选中时字重改为 400; 选中态通过字重区分, 而非颜色.
  required final TextStyle subhead,

  /// 正文, 用于描述, 上传者的说明和消息内容.
  required final TextStyle body,

  /// 次级信息, 搭配 `ink-muted` 或 `ink-soft`.
  required final TextStyle meta,

  /// 辅助信息, 用于时间, 数量单位, 表单说明和底部导航文字.
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
  /// 舞台主角等特粗中文使用的字重.
  ///
  /// 取值略低于 800 而非 [FontWeight.w800]: iOS 系统的苹方最粗只有 Semibold (600),
  /// 当请求字重与字体字重相差达到 200 时, SkParagraph 会启用假粗体并通过路径描边加填充模拟加粗;
  /// 部分汉字轮廓 (如 "隆") 会因路径绕向误判而在笔画内部出现镂空缝隙.
  /// 降至 780 可避免触发假粗体, 同时在安卓内置的可变字体上保持接近原 800 映射的层次.
  static const heavyWeight = FontWeight(780);

  static final standard = EatTextStyles(
    display: _sans(56, 60, heavyWeight.value, letterSpacing: -1.5),
    stage: _sans(44, 48, heavyWeight.value, letterSpacing: -1),
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
  fontFamily: EatFonts.sans,
  // 内置的中文字体不含间隔号 · (全角过宽), 由 Inter 的半宽间隔号显示, 见 tool/subset_fonts.py.
  fontFamilyFallback: [if (EatFonts.sans != null) EatFonts.numeral],
  fontSize: size,
  height: lineHeight / size,
  leadingDistribution: TextLeadingDistribution.even,
  fontWeight: FontWeight(weight),
  letterSpacing: letterSpacing,
);

/// 构造数字样式, 其光学尺寸跟随字号并限制在 Inter `opsz` 轴的 14–32 范围内.
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
  fontFamilyFallback: [?EatFonts.sans],
  fontSize: size,
  height: lineHeight / size,
  leadingDistribution: TextLeadingDistribution.even,
  fontWeight: FontWeight(weight),
  fontVariations: [FontVariation.opticalSize(size.clamp(14, 32))],
  fontFeatures: [if (tabular) const FontFeature.tabularFigures()],
  letterSpacing: letterSpacing,
);
