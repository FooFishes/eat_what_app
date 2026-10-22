import 'package:eat/design/theme/eat_colors.dart';
import 'package:eat/design/theme/eat_shadows.dart';
import 'package:eat/design/theme/eat_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// 挂在 `ThemeData` 上的设计令牌，组件用 `context.eat` 取。
class const EatTheme({
  required final EatColors colors,
  required final EatTextStyles text,
  required final EatShadows shadows,
}) extends ThemeExtension<EatTheme> {
  static final light = EatTheme(
    colors: EatColors.light,
    text: EatTextStyles.standard,
    shadows: EatShadows.standard,
  );

  @override
  EatTheme copyWith({
    EatColors? colors,
    EatTextStyles? text,
    EatShadows? shadows,
  }) => EatTheme(
    colors: colors ?? this.colors,
    text: text ?? this.text,
    shadows: shadows ?? this.shadows,
  );

  /// 只有一套浅色主题，主题之间不会过渡，所以不做逐项插值，过半就换成目标值。
  @override
  EatTheme lerp(EatTheme? other, double t) =>
      other != null && t >= 0.5 ? other : this;
}

extension EatThemeContext on BuildContext {
  /// 当前的设计令牌。
  ///
  /// 上下文里没挂 `EatTheme` 时（比如单测里直接 pump 一个组件）退回 [EatTheme.light]：只有这一套
  /// 主题，退回去的值和挂上的一样。
  EatTheme get eat => Theme.of(this).extension<EatTheme>() ?? EatTheme.light;
}

/// 应用的 `ThemeData`：固定浅色，关掉水波纹，背景 `paper`。
///
/// 按钮、标签、开关、面板都用 `design/widgets/` 里自己的组件，这里只照顾仍会用到的 Material
/// 部件（输入框、文本选择菜单、光标），让它们取 `ink`，不混进 M3 默认的紫色。
ThemeData eatThemeData() {
  final theme = EatTheme.light;
  final colors = theme.colors;
  final textTheme = Typography.blackMountainView.apply(
    fontFamily: EatFonts.sans,
    bodyColor: colors.ink,
    displayColor: colors.ink,
  );
  return ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: colors.ink,
      onPrimary: colors.paper,
      secondary: colors.ink,
      onSecondary: colors.paper,
      error: colors.warn,
      onError: colors.paper,
      surface: colors.paper,
      onSurface: colors.ink,
    ),
    scaffoldBackgroundColor: colors.paper,
    fontFamily: EatFonts.sans,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x00000000),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.ink,
      selectionColor: colors.tagSelected,
      selectionHandleColor: colors.ink,
    ),
    extensions: [theme],
  );
}
