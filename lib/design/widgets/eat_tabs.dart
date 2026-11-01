import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 文字分类栏 [EatTabs] 中的一项.
class const EatTabItem(
  final String label, {

  /// 文字后的计数, 如 "上传 42".
  final int? count,

  /// 功能尚未对接接口. 分类正常列出, 文字后接 "待接入".
  final bool pending = false,
});

/// 文字分类栏. 选中项靠字重区分, 没有下划线和底色.
///
/// - 点击区域上下扩展到 44px, 整条的布局高度因此约为 44px. 按基线对齐时会多出不到 1px.
/// - 放不下时横向滚动, 不换行.
class EatTabs extends StatelessWidget {
  const new({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  final List<EatTabItem> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  /// 横向滚动时内容两侧的留白, 通常为页面边距 `space-20`.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    // tabBar 语义节点必须直接包含各个 tab, 因此放在滚动视图内部, 而不是外部.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Semantics(
        role: SemanticsRole.tabBar,
        container: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            for (final (i, tab) in tabs.indexed) ...[
              if (i > 0) const SizedBox(width: 22),
              _Tab(
                tab: tab,
                selected: i == selected,
                onTap: () => onSelected(i),
                eat: eat,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const new({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.eat,
  });

  final EatTabItem tab;
  final bool selected;
  final VoidCallback onTap;
  final EatTheme eat;

  @override
  Widget build(BuildContext context) {
    final color = selected ? eat.colors.ink : eat.colors.inkMuted;
    final labelStyle = (selected ? eat.text.tabActive : eat.text.tab).copyWith(
      color: color,
    );
    return EatTappable(
      onTap: onTap,
      button: false,
      role: SemanticsRole.tab,
      selected: selected,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: (EatSize.touch - 24) / 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(tab.label, style: labelStyle),
            if (tab.count case final count?) ...[
              const SizedBox(width: EatSpace.s4),
              Text(
                '$count',
                style: eat.text.count.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
            if (tab.pending) ...[
              const SizedBox(width: EatSpace.s4),
              const PendingTag(),
            ],
          ],
        ),
      ),
    );
  }
}
