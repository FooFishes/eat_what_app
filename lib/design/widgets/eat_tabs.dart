import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
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

/// 文字分类栏组件, 选中项字重加粗, 字的下半截压一道记号笔.
///
/// - 记号笔取舞台色的淡色, 没有舞台的白底页面用芒果黄; 选中时从左往右画出来, 取消时从右往左收回.
/// - 放得下时各项等分整行宽度, 文字在各自那一格里居中, 底下一条 `hairline` 托住整排;
///   放不下时 (分类多, 或带 "待接入" 小标) 按固定间距从左往右排, 横向滚动, 不换行, 细线固定在下面.
/// - 点击区域上下扩展至 44px, 整条布局高度约为 44px (按基线对齐时会多出不足 1px).
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

  /// 分类栏两侧的留白, 通常设置为页面边距 `space-20`.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final marker = _markerColor(StageTheme.maybeOf(context));
    final inset = padding.resolve(Directionality.of(context)).horizontal;
    Widget tabAt(int i, {required bool fill}) => _Tab(
      tab: tabs[i],
      selected: i == selected,
      onTap: () => onSelected(i),
      eat: eat,
      marker: marker,
      fill: fill,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - inset;
        final column = width / tabs.length;
        final fits = tabs.every(
          (tab) => _naturalWidth(context, tab) + _gap <= column,
        );
        // tabBar 语义节点必须直接包裹各个 tab, 因此放置在滚动视图内部而非外部.
        if (!fits) {
          final edges = padding.resolve(Directionality.of(context));
          // 横向滚动时细线不跟着滚, 固定在页面边距之内, 和等分时一样托住整排.
          return Stack(
            children: [
              Positioned(
                left: edges.left,
                right: edges.right,
                bottom: 0,
                child: ColoredBox(
                  color: eat.colors.hairline,
                  child: const SizedBox(height: 1),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: padding,
                child: Semantics(
                  role: SemanticsRole.tabBar,
                  container: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        tabAt(i, fill: false),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return Padding(
          padding: padding,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: eat.colors.hairline)),
            ),
            child: Semantics(
              role: SemanticsRole.tabBar,
              container: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(child: tabAt(i, fill: true)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 一项分类不加左右点击区域时的宽度, 按选中时的字重量; 带 "待接入" 小标的按放不下算.
  static double _naturalWidth(BuildContext context, EatTabItem tab) {
    if (tab.pending) return double.infinity;
    final eat = context.eat;
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    var width = measure(tab.label, _labelStyle(eat, selected: true));
    if (tab.icon != null) width += _selectedSize + EatSpace.s4;
    if (tab.count case final count?) {
      width +=
          EatSpace.s4 +
          measure(
            '$count',
            eat.text.count.copyWith(fontWeight: FontWeight.w700),
          );
    }
    return width;
  }

  /// 记号笔的颜色: 舞台色叠一层透明度. 深色舞台本身就重, 淡一些; 浅色舞台要浓一些才看得出来.
  static Color _markerColor(StagePalette? palette) {
    final background = palette?.background ?? StageColor.mango.color;
    final dark = palette?.isDark ?? StageColor.mango.isDark;
    return background.withValues(alpha: dark ? 0.4 : 0.85);
  }
}

class _Tab extends StatefulWidget {
  const new({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.eat,
    required this.marker,
    required this.fill,
  });

  final EatTabItem tab;
  final bool selected;
  final VoidCallback onTap;
  final EatTheme eat;
  final Color marker;

  /// 是否占满分给它的一格, 文字在格里居中; 整格都能点.
  final bool fill;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  @override
  void didUpdateWidget(_Tab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 等分整行时没有横向滚动视图, 往上找到的是页面的纵向滚动, 不能滚.
    if (widget.selected && !oldWidget.selected && !widget.fill) _reveal();
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
    final labelStyle = _labelStyle(
      eat,
      selected: selected,
    ).copyWith(color: color);
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
        padding: const EdgeInsets.symmetric(
          vertical: (EatSize.touch - _lineHeight) / 2,
          horizontal: _gap / 2,
        ),
        child: _centered(
          widget.fill,
          _Marker(
            on: selected,
            color: widget.marker,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (tab.icon case final icon?) ...[
                  _TabIcon(icon, color: color, style: labelStyle),
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
        ),
      ),
    );
  }

  /// 占满一格时让内容在格里水平居中; [Align] 保留子组件的基线, 整排仍按基线对齐.
  static Widget _centered(bool fill, Widget child) => fill
      ? Align(alignment: Alignment.topCenter, heightFactor: 1, child: child)
      : child;
}

/// 两项文字之间的最小间距, 一半做成每项左右的点击区域.
const _gap = 22.0;

/// 选中项 18 号 (介于 `subhead` 和 `heading` 之间), 未选中的用 15 号 (`body` 的字号); 行高都是 26, 切换时整排不跳.
/// 图标和字一样大.
const _selectedSize = 18.0;
const _unselectedSize = 15.0;
const _lineHeight = 26.0;

TextStyle _labelStyle(EatTheme eat, {required bool selected}) {
  final size = selected ? _selectedSize : _unselectedSize;
  return eat.text.subhead.copyWith(
    fontSize: size,
    height: _lineHeight / size,
    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
  );
}

/// 文字前的图标, 中心对在汉字的视觉中心上.
///
/// 分类栏按基线排, 图标本身没有基线, 所以放进一段和文字同样式的 [Text.rich] 里, 底边落在基线上,
/// 再往下挪到图标中心和汉字中心 (基线上方约 0.38em, 见 `StageBarAction`) 重合.
class _TabIcon extends StatelessWidget {
  const new(this.icon, {required this.color, required this.style});

  final EatIcons icon;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Text.rich(
    WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Transform.translate(
        offset: Offset(0, style.fontSize! / 2 - 0.38 * style.fontSize!),
        child: EatIcon(icon, size: style.fontSize!, color: color),
      ),
    ),
    style: style,
    textScaler: TextScaler.noScaling,
  );
}

/// 压在文字下半截的一道记号笔: 略向右斜, 两头圆角不一样, 像手画的.
///
/// [on] 变为 true 时从左往右画出来, 变为 false 时从右往左收回, 时长和曲线用 [EatMotion.select].
class _Marker extends StatelessWidget {
  const new({required this.on, required this.color, required this.child});

  final bool on;
  final Color color;
  final Widget child;

  /// 记号笔的高度, 和离文字框底边的距离; 盖住字的下半截, 上半截露在外面.
  static const _height = 13.0;
  static const _bottom = 2.0;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: -3,
        right: -3,
        bottom: _bottom,
        height: _height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: on ? 1 : 0),
          duration: context.motion(EatMotion.select),
          curve: EatMotion.select.curve,
          builder: (context, t, _) => t == 0
              ? const SizedBox()
              // 先按进度裁出一截再斜切, 两头的斜边才不会被裁直.
              : Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Transform(
                    alignment: AlignmentDirectional.centerStart,
                    transform: Matrix4.skewX(-0.2)..rotateZ(-0.025),
                    child: ClipRect(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: t,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(9),
                            ),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
      child,
    ],
  );
}
