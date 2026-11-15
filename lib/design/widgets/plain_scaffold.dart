import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_refresh.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 白底页面骨架, 用于消息, 选店, 搜索, 评论和设置.
///
/// - 返回按钮和 `page-title` 标题在同一行, 标题过长时换行, 左右边距 `space-20`.
/// - 标题行固定在顶部, 不随内容滚动. 内容滚动到标题行下方时, 标题行底边显示 `hairline`.
/// - 宽屏时整页收窄为居中的一栏.
/// - 分组靠小标题和留白分隔, 不加卡片. [slivers] 已包含左右边距.
/// - 标题下面不放副标题. 说明写在内容里它所说明的输入框或列表旁边,
///   标题旁只放 [titleNote] 这类简短的状态.
/// - 键盘弹出时页面避让到键盘上方, 获得焦点的输入框会滚动到可见位置.
/// - 拖动页面或点击空白处时收起键盘.
class PlainScaffold extends StatefulWidget {
  const new({
    super.key,
    required this.title,
    this.titleNote,
    this.slivers = const [],
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.physics,
    this.onRefresh,
    this.header,
  });

  final String title;

  /// 紧跟在标题后面的简短状态, 如 "3 条未读" "仅自己可见", 使用 `meta` 和 `ink-muted`.
  /// 和标题同属一段文字, 放不下时接着标题换行.
  final String? titleNote;

  final List<Widget> slivers;

  /// 顶栏右侧的图标按钮.
  final List<Widget> actions;

  final bool showBack;

  /// 返回按钮的回调. 不传时返回上一页, 没有上一页时执行后备行为.
  final VoidCallback? onBack;

  /// 页面的滚动行为.
  ///
  /// 页面中有地图等需要拖动的组件时, 手指按在其上期间传入 `NeverScrollableScrollPhysics`.
  /// 否则纵向拖动会被页面滚动接管.
  final ScrollPhysics? physics;

  /// 下拉刷新. 不传时页面不能下拉刷新.
  final Future<void> Function()? onRefresh;

  /// 代替标题显示在返回按钮右侧的组件, 如搜索页的搜索框. 传入时 [title] 只用于读屏.
  final Widget? header;

  @override
  State<PlainScaffold> createState() => _PlainScaffoldState();
}

class _PlainScaffoldState extends State<PlainScaffold>
    with ScrollToTopOnReselect {
  /// 内容是否已滚动到标题行下方.
  final _scrolled = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    _scrolled.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.hasClients) {
      _scrolled.value = scrollController.offset > 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final media = MediaQuery.of(context);
    final padding = EatLayout.of(context).plainHorizontalPadding;
    final navInset = NavBarInset.of(context);
    final header = widget.header;
    final titleRow = Padding(
      padding: EdgeInsets.fromLTRB(
        widget.showBack ? padding - EatBackButton.inset : padding,
        media.padding.top + 4,
        widget.actions.isEmpty ? padding : padding - 4,
        4,
      ),
      child: Row(
        children: [
          if (widget.showBack) ...[
            EatBackButton(onPressed: widget.onBack),
            const SizedBox(width: EatSpace.s4),
          ],
          Expanded(
            child: header != null
                ? Semantics(header: true, label: widget.title, child: header)
                : Semantics(
                    header: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: widget.title),
                            if (widget.titleNote case final note?) ...[
                              const WidgetSpan(
                                child: SizedBox(width: EatSpace.s8),
                              ),
                              TextSpan(
                                text: note,
                                style: eat.text.meta.copyWith(
                                  color: eat.colors.inkMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        textScaler: TextScaler.noScaling,
                        style: eat.text.heading.copyWith(color: eat.colors.ink),
                      ),
                    ),
                  ),
          ),
          if (widget.actions.isNotEmpty)
            SizedBox(
              height: EatBackButton.extent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.actions,
              ),
            ),
        ],
      ),
    );
    Widget scroll = CustomScrollView(
      controller: scrollController,
      physics: switch ((widget.physics, widget.onRefresh)) {
        (final physics?, _) => physics,
        // 内容不足一屏时默认不能滚动, 下拉手势不会触发刷新.
        (null, _?) => const AlwaysScrollableScrollPhysics(),
        (null, null) => null,
      },
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: SliverMainAxisGroup(slivers: widget.slivers),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: navInset > 0
                ? navInset
                : media.padding.bottom + EatSpace.s24,
          ),
        ),
      ],
    );
    if (widget.onRefresh case final onRefresh?) {
      scroll = EatRefresh(onRefresh: onRefresh, child: scroll);
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: eat.colors.paper,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: eat.colors.ink),
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _scrolled,
                      builder: (context, scrolled, child) => DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: scrolled
                                  ? eat.colors.hairline
                                  : eat.colors.paper,
                            ),
                          ),
                        ),
                        child: child,
                      ),
                      child: titleRow,
                    ),
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: scroll,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
