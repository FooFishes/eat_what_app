import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/widgets.dart';

/// 舞台上用到的一整套颜色，由 [StageColor] 算出；换舞台色时整套一起插值。
@immutable
class const StagePalette({
  required final Color background,
  required final Color foreground,
  required final Color secondaryForeground,
  required final Color ghost,
  required final Color table,
  required final Color tableRing,
  required final Color solidTop,
  required final Color solidBottom,

  /// 实心按钮的文字色，就是舞台色本身。
  required final Color solidForeground,

  /// 深色舞台：实心按钮换成白色那一套阴影，状态栏图标用浅色。过渡到一半时切换。
  required final bool isDark,
}) {
  factory StagePalette.of(StageColor stage) => StagePalette(
    background: stage.color,
    foreground: stage.foreground,
    secondaryForeground: stage.secondaryForeground,
    ghost: stage.ghost,
    table: stage.table,
    tableRing: stage.tableRing,
    solidTop: stage.solidTop,
    solidBottom: stage.solidBottom,
    solidForeground: stage.color,
    isDark: stage.isDark,
  );

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
        solidTop: Color.lerp(a.solidTop, b.solidTop, t)!,
        solidBottom: Color.lerp(a.solidBottom, b.solidBottom, t)!,
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
      other.solidTop == solidTop &&
      other.solidBottom == solidBottom &&
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
    solidTop,
    solidBottom,
    solidForeground,
    isDark,
  );
}

/// 向下提供当前舞台的颜色。舞台上的按钮、文字从这里取色，所以换舞台色时它们跟着一起变。
class StageTheme extends InheritedWidget {
  const new({super.key, required this.palette, required super.child});

  final StagePalette palette;

  /// 不在舞台里时返回 null。
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

/// 换舞台色时，底色、文字和按钮的颜色在 500ms 里一起过渡；减少动态效果时直接切换。
class AnimatedStageTheme extends StatelessWidget {
  const new({super.key, required this.stage, required this.builder});

  final StageColor stage;

  final Widget Function(BuildContext context, StagePalette palette) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<StagePalette>(
    tween: _StagePaletteTween(end: StagePalette.of(stage)),
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
