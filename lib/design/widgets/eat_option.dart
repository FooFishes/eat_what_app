import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// 面板里的一个单选项. 未选中时 `mist` 底, 选中时 `ink` 实心底 `paper` 字, 文字加粗.
///
/// [detail] 是名字旁的数字信息, 如距离和时间段, 用数字字体.
/// [pill] 为 true 时是胶囊, 宽度随内容, 名字和 [detail] 排成一行; 否则是填满格子的圆角方块, [detail] 在名字下方.
class EatOption extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    this.detail,
    this.icon,
    this.pill = false,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? detail;
  final EatIcons? icon;
  final bool pill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final foreground = selected ? c.paper : c.ink;
    final muted = selected ? c.paper.withValues(alpha: 0.72) : c.inkMuted;
    final radius = pill ? EatRadius.pill : EatRadius.tile;
    final duration = context.motion(EatMotion.select);
    final name = Text(
      label,
      style: eat.text.subhead.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: foreground,
      ),
    );
    final detail = switch (this.detail) {
      final text? => Text(text, style: eat.text.count.copyWith(color: muted)),
      null => null,
    };
    return EatTappable(
      onTap: () {
        if (!selected) EatHaptics.selection();
        onTap();
      },
      button: false,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      focusShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(radius),
      ),
      builder: (context, _) => AnimatedContainer(
        duration: duration,
        curve: EatMotion.select.curve,
        constraints: BoxConstraints(
          minHeight: pill ? EatSize.touch : EatSize.button,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: pill ? EatSpace.s16 : EatSpace.s14,
          vertical: pill ? EatSpace.s4 : EatSpace.s10,
        ),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.mist,
          borderRadius: BorderRadius.all(radius),
        ),
        child: pill
            ? Row(
                mainAxisSize: MainAxisSize.min,
                spacing: EatSpace.s8,
                children: [name, ?detail],
              )
            : Row(
                spacing: EatSpace.s8,
                children: [
                  if (icon case final icon?)
                    EatIcon(icon, size: 20, color: foreground),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [name, ?detail],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 一组单选的读屏外壳, 把组内选项归为一个单选组.
class EatRadioGroup extends StatelessWidget {
  const new({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    role: SemanticsRole.radioGroup,
    label: label,
    child: child,
  );
}
