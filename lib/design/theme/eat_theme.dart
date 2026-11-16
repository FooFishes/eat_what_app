import 'package:flutter/foundation.dart';
import 'package:eat/design/theme/eat_colors.dart';
import 'package:eat/design/theme/eat_shadows.dart';
import 'package:eat/design/theme/eat_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// 挂载在 `ThemeData` 上的设计令牌, 组件通过 `context.eat` 读取.
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

  /// 应用只有一套浅色主题, 不存在主题之间的过渡, 因此不逐项插值, 而在进度过半时切换为目标值.
  @override
  EatTheme lerp(EatTheme? other, double t) =>
      other != null && t >= 0.5 ? other : this;
}

extension EatThemeContext on BuildContext {
  /// 当前的设计令牌.
  ///
  /// 上下文中没有 `EatTheme` 时回退到 [EatTheme.light] (例如单元测试中直接 pump 组件).
  /// 由于应用只有这一套主题, 回退值与挂载值完全相同.
  EatTheme get eat => Theme.of(this).extension<EatTheme>() ?? EatTheme.light;
}

/// 构建应用的 `ThemeData`, 固定为浅色, 关闭水波纹并将背景设为 `paper`.
///
/// 按钮, 标签, 开关和面板都使用 `design/widgets/` 中的自有组件.
/// 本主题只配置仍会用到的 Material 部件 (输入框, 文本选择菜单, 光标), 使其使用 `ink`, 避免出现 M3 默认的紫色.
ThemeData eatThemeData() {
  final theme = EatTheme.light;
  final colors = theme.colors;
  final textTheme = Typography.material2021(platform: defaultTargetPlatform)
      .black
      .apply(bodyColor: colors.ink, displayColor: colors.ink);
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
