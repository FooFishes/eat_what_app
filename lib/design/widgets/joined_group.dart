import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 连成一组的卡片, 照 Material 3 Expressive 的分段列表: 卡片之间只隔一道窄缝,
/// 整组外侧四个角是大圆角, 相邻卡片接缝处是小圆角, 看上去像一块被切开的面.
///
/// 组里的卡片用 [JoinedSurface] 画底色, 圆角由所在位置决定.
class JoinedGroup extends StatelessWidget {
  const new(this.children, {super.key});

  final List<Widget> children;

  /// 卡片之间的窄缝.
  static const gap = 2.0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: gap,
    children: [
      for (final (i, child) in children.indexed)
        _JoinedSlot(
          radius: BorderRadius.vertical(
            top: i == 0 ? EatRadius.tile : EatRadius.joined,
            bottom: i == children.length - 1
                ? EatRadius.tile
                : EatRadius.joined,
          ),
          child: child,
        ),
    ],
  );

  /// [context] 所在卡片的圆角. 不在组里时四角都是 `radius-tile`.
  static BorderRadius radiusOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_JoinedSlot>()?.radius ??
      const BorderRadius.all(EatRadius.tile);
}

class _JoinedSlot extends InheritedWidget {
  const new({required this.radius, required super.child});

  final BorderRadius radius;

  @override
  bool updateShouldNotify(_JoinedSlot oldWidget) => oldWidget.radius != radius;
}

/// [JoinedGroup] 里一张卡片的 `mist` 底色. 按下时四个角一起变成大圆角, 从组里 "浮" 出来, 松开后回到原位的形状.
class JoinedSurface extends StatelessWidget {
  const new({super.key, this.pressed = false, required this.child});

  final bool pressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = pressed
        ? const BorderRadius.all(EatRadius.tile)
        : JoinedGroup.radiusOf(context);
    return AnimatedContainer(
      duration: context.motion(EatMotion.select),
      curve: EatMotion.select.curve,
      decoration: BoxDecoration(
        color: context.eat.colors.mist,
        borderRadius: radius,
      ),
      child: child,
    );
  }
}
