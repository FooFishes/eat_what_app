import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 一个分类。
class const EatTabItem(
  final String label, {

  /// 跟在文字后面的计数，如「上传 42」。
  final int? count,

  /// 还没有接口的分类照样列出，后面跟「待接入」。
  final bool pending = false,
});

/// 用字重区分选中的文字分类：选中 17px 900，其他 15px 400 `ink-muted`，没有下划线和底色。
///
/// 文字行高 32，点击区域上下扩到 44，所以整条的布局高度约 44（按基线对齐会多出不到 1px）。
/// 放不下时横向滚动，不换行。
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

  /// 横向滚动时内容两侧的留白，一般是页面边距 `space-20`。
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    // tabBar 的语义节点必须直接包住各个 tab，所以放在滚动视图里面，而不是外面。
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
