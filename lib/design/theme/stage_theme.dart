import 'package:eat/design/theme/eat_colors.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/widgets.dart';

/// 舞台使用的整套颜色, 由 [StageColor] 计算得出.
///
/// 切换舞台色或系统深浅时整套颜色同步插值.
@immutable
class const StagePalette({
  required final Color background,
  required final Color foreground,
  required final Color secondaryForeground,
  required final Color ghost,
  required final Color table,
  required final Color tableRing,
  required final Color solid,

  /// 实心按钮的文字色, 等于舞台色本身.
  required final Color solidForeground,

  /// 是否为深色舞台. 深色舞台的实心按钮使用白色按钮的阴影, 状态栏图标使用浅色.
  ///
  /// 插值时在进度过半处切换.
  required final bool isDark,
}) {
  /// [dark] 为 true 时取系统深色模式下压暗的舞台底色, 次按钮和转盘桌面是半透明的白, 叠在底色上跟着变.
  factory StagePalette.of(StageColor stage, {bool dark = false}) =>
      StagePalette(
        background: stage.colorIn(dark: dark),
        foreground: stage.foreground,
        secondaryForeground: stage.secondaryForeground,
        ghost: stage.ghost,
        table: stage.table,
        tableRing: stage.tableRing,
        solid: stage.solid,
        solidForeground: stage.colorIn(dark: dark),
        isDark: stage.isDark,
      );

  /// 舞台铺着照片时的配色: 白字, 胶囊是半透明的深色. 照片的颜色不定, 白字压在深色渐变上最稳.
  ///
  /// [background] 是 `shade`, 照片加载出来之前和顶栏滚动时垫的都是它, 和照片顶部的暗色渐变接得上.
  factory StagePalette.photo(EatColors c) {
    final ghost = c.shade.withValues(alpha: photoGhostAlpha);
    return StagePalette(
      background: c.shade,
      foreground: c.white,
      secondaryForeground: c.white,
      ghost: ghost,
      table: ghost,
      tableRing: ghost,
      solid: c.white,
      solidForeground: c.shade,
      isDark: true,
    );
  }

  /// 照片上胶囊底色的不透明度.
  static const photoGhostAlpha = 0.32;

  static StagePalette lerp(StagePalette a, StagePalette b, double t) =>
      StagePalette(
        background: Color.lerp(a.background, b.background, t)!,
        foreground: Color.lerp(a.foreground, b.foreground, t)!,
        secondaryForeground: Color.lerp(
          a.secondaryForeground,
          b.secondaryForeground,
          t,
        )!,
        ghost: Color.lerp(a.ghost, b.ghost, t)!,
        table: Color.lerp(a.table, b.table, t)!,
        tableRing: Color.lerp(a.tableRing, b.tableRing, t)!,
        solid: Color.lerp(a.solid, b.solid, t)!,
        solidForeground: Color.lerp(a.solidForeground, b.solidForeground, t)!,
        isDark: t < 0.5 ? a.isDark : b.isDark,
      );

  @override
  bool operator ==(Object other) =>
      other is StagePalette &&
      other.background == background &&
      other.foreground == foreground &&
      other.secondaryForeground == secondaryForeground &&
      other.ghost == ghost &&
      other.table == table &&
      other.tableRing == tableRing &&
      other.solid == solid &&
      other.solidForeground == solidForeground &&
      other.isDark == isDark;

  @override
  int get hashCode => Object.hash(
    background,
    foreground,
    secondaryForeground,
    ghost,
    table,
    tableRing,
    solid,
    solidForeground,
    isDark,
  );
}

/// 向子树提供当前舞台的颜色.
///
/// 舞台上的按钮和文字从本组件取色, 因此切换舞台色时可同步变化.
class StageTheme extends InheritedWidget {
  const new({super.key, required this.palette, required super.child});

  final StagePalette palette;

  /// 获取当前舞台配色, 不在舞台内时返回 null.
  static StagePalette? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StageTheme>()?.palette;

  static StagePalette of(BuildContext context) {
    final palette = maybeOf(context);
    assert(palette != null, '舞台按钮只能放在 EatStage 或 AnimatedStageTheme 里面');
    return palette!;
  }

  @override
  bool updateShouldNotify(StageTheme oldWidget) => palette != oldWidget.palette;
}

/// 切换舞台色时, 按 [EatMotion.stageColor] 同步过渡底色, 文字和按钮的颜色.
///
/// 系统开启减少动态效果时直接切换.
class AnimatedStageTheme extends StatelessWidget {
  const new({
    super.key,
    required this.stage,
    this.onPhoto = false,
    required this.builder,
  });

  final StageColor stage;

  /// 舞台上是否铺着照片. 为 true 时用 [StagePalette.photo], 不用 [stage] 的配色.
  final bool onPhoto;

  final Widget Function(BuildContext context, StagePalette palette) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<StagePalette>(
    tween: _StagePaletteTween(
      end: onPhoto
          ? StagePalette.photo(context.eat.colors)
          : StagePalette.of(stage, dark: context.eat.colors.isDark),
    ),
    duration: context.motion(EatMotion.stageColor),
    curve: EatMotion.stageColor.curve,
    builder: (context, palette, _) => StageTheme(
      palette: palette,
      child: Builder(builder: (context) => builder(context, palette)),
    ),
  );
}

class _StagePaletteTween extends Tween<StagePalette> {
  _StagePaletteTween({super.end});

  @override
  StagePalette lerp(double t) => StagePalette.lerp(begin ?? end!, end!, t);
}
