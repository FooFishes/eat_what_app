import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// "大家怎么说" 中的一个词.
class const TasteWord({
  required final String label,
  required final int count,

  /// 是否选中. 菜品详情中表示我打过, 餐厅详情中表示正按此词筛选.
  ///
  /// 选中靠字重和下划线区分, 不靠颜色.
  final bool selected = false,
});

/// "大家怎么说": 口味标签排成一行文字, 打的人越多, 字越大越重.
///
/// - [words] 须已按次数从高到低排序. 只显示前 6 个, 字号和颜色按排名分档.
/// - 每个词是一个按钮, 点击区域高度不小于 44px.
/// - [trailing] 通常为 "+ 加标签" 胶囊.
class TasteCloud extends StatelessWidget {
  const new({
    super.key,
    required this.words,
    required this.onTap,
    this.trailing,
    this.selectedLabel = '已选',
  });

  final List<TasteWord> words;
  final ValueChanged<int> onTap;
  final Widget? trailing;

  /// 选中的词在读屏中追加的说明. 菜品详情为 "我打过", 餐厅详情为 "正在筛选".
  final String selectedLabel;

  static const _tiers = [
    (size: 28.0, weight: FontWeight.w900, strong: true),
    (size: 22.0, weight: FontWeight.w700, strong: true),
    (size: 18.0, weight: FontWeight.w600, strong: false),
    (size: 15.0, weight: FontWeight.w500, strong: false),
  ];

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final shown = words.take(6).toList();
    return Wrap(
      spacing: EatSpace.s16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, word) in shown.indexed)
          _word(
            eat,
            word,
            _tiers[i < 1
                ? 0
                : i < 2
                ? 1
                : i < 4
                ? 2
                : 3],
            () => onTap(i),
          ),
        ?trailing,
      ],
    );
  }

  Widget _word(
    EatTheme eat,
    TasteWord word,
    ({double size, FontWeight weight, bool strong}) tier,
    VoidCallback onTap,
  ) {
    final colors = eat.colors;
    final color = tier.strong ? colors.ink : colors.inkMuted;
    return EatTappable(
      onTap: onTap,
      toggled: word.selected,
      label:
          '${word.label}，${word.count} 人${word.selected ? '，$selectedLabel' : ''}',
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      builder: (context, pressed) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: EatSize.touch),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              word.label,
              style: eat.text.body.copyWith(
                fontSize: tier.size,
                height: 1.25,
                fontWeight: word.selected ? FontWeight.w900 : tier.weight,
                color: color,
                decoration: word.selected ? TextDecoration.underline : null,
                decorationThickness: 2,
              ),
            ),
            const SizedBox(width: EatSpace.s4),
            Text(
              '${word.count}',
              style: eat.text.count.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
