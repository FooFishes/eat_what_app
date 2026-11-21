import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:flutter/widgets.dart';

/// 一组带小标题的单选标签 ([EatChip.choice]), 放在筛选浮层这类小地方. 宽度随内容, 放不下时折行.
class EatChoiceGroup<T> extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.label,
    required this.onPick,
  });

  final String title;
  final List<T> options;
  final T selected;
  final String Function(T option) label;

  /// 点了某一项, 包括已选的那一项.
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: eat.text.meta.copyWith(
            fontWeight: FontWeight.w600,
            color: eat.colors.inkMuted,
          ),
        ),
        Wrap(
          spacing: EatSpace.s8,
          children: [
            for (final option in options)
              EatChip.choice(
                label(option),
                selected: option == selected,
                onTap: () => onPick(option),
              ),
          ],
        ),
      ],
    );
  }
}
