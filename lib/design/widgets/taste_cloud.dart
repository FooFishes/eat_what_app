import 'package:eat/design/theme/eat_text_styles.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 表示 "大家怎么说" 词云中的单个口味词.
class const TasteWord({
  required final String label,
  required final int count,

  /// 是否处于选中态; 菜品详情页中表示当前用户打过该标签, 餐厅详情页中表示正在按此词筛选.
  ///
  /// 选中态仅通过字重和下划线区分, 不改变文字颜色.
  final bool selected = false,
});

/// "大家怎么说" 口味词云组件, 将标签排成文字流并根据人数梯度调整字号和字重.
///
/// - [words] 须已按次数降序排列, 组件仅截取前 6 个并按排名分档赋予字号和颜色.
/// - 每个词均为可点击按钮, 点击区域高度不小于 44px.
/// - [trailing] 通常用于放置 "+ 加标签" 胶囊按钮.
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

  /// 选中词在读屏中追加的状态说明, 菜品详情页传 "我打过", 餐厅详情页传 "正在筛选".
  final String selectedLabel;

  static const _tiers = [
    (size: 26.0, weight: FontWeight.w700, strong: true),
    (size: 20.0, weight: FontWeight.w700, strong: true),
    (size: 16.0, weight: FontWeight.w600, strong: false),
    (size: 15.0, weight: FontWeight.w400, strong: false),
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
                fontWeight: word.selected
                    ? EatTextStyles.heavyWeight
                    : tier.weight,
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
