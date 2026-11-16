import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 表示文字分类栏 [EatTabs] 中的单个标签项.
class const EatTabItem(
  final String label, {

  /// 文字后的计数, 如 "上传 42".
  final int? count,

  /// 标识该分类尚未对接接口; 开启后仍正常列出, 并在文字后附加 "待接入".
  final bool pending = false,

  /// 文字前的图标, 如发现页分类栏中专题的图标.
  final EatIcons? icon,
});

/// 文字分类栏组件, 选中项通过字重而非下划线或底色区分.
///
/// - 点击区域上下扩展至 44px, 整条布局高度约为 44px (按基线对齐时会多出不足 1px).
/// - 内容超出宽度时横向滚动, 不自动换行.
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

  /// 横向滚动时内容两侧的留白, 通常设置为页面边距 `space-20`.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    // tabBar 语义节点必须直接包裹各个 tab, 因此放置在滚动视图内部而非外部.
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

class _Tab extends StatefulWidget {
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
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  @override
  void didUpdateWidget(_Tab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _reveal();
  }

  /// 将当前选中的分类滚动至分类栏中央, 使原本仅露出一部分的标签完整显示.
  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 仅滚动分类栏自身, 避免使用 `Scrollable.ensureVisible` 触发外层页面发生纵向跳动.
      final box = context.findRenderObject();
      if (box == null) return;
      Scrollable.maybeOf(context)?.position.ensureVisible(
        box,
        alignment: 0.5,
        duration: context.motion(EatMotion.select),
        curve: EatMotion.select.curve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final _Tab(:tab, :selected, :eat) = widget;
    final color = selected ? eat.colors.ink : eat.colors.inkMuted;
    final labelStyle = eat.text.subhead.copyWith(
      color: color,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
    );
    return EatTappable(
      onTap: () {
        if (!selected) EatHaptics.selection();
        widget.onTap();
      },
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
            if (tab.icon case final icon?) ...[
              EatIcon(icon, size: 16, color: color),
              const SizedBox(width: EatSpace.s4),
            ],
            Text(tab.label, style: labelStyle),
            if (tab.count case final count?) ...[
              const SizedBox(width: EatSpace.s4),
              Text(
                '$count',
                style: eat.text.count.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : null,
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
