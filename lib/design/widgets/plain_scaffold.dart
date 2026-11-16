import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_refresh.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 白底页面骨架, 用于消息, 选店, 搜索, 评论和设置等列表页.
///
/// - 返回按钮与 `page-title` 标题同行排布, 标题过长时自动换行, 左右边距为 `space-20`.
/// - 标题行固定在顶部不随内容滚动, 内容滚动到标题行下方时在其底边显示 `hairline` 分割线.
/// - 宽屏下整页收窄为居中一栏, 分组通过小标题与留白分隔而不使用卡片 ([slivers] 区域已包含左右边距).
/// - 标题下方不设副标题, 详细说明应放在对应输入框或列表旁, 标题旁仅展示 [titleNote] 等简短状态.
/// - 键盘弹出时自动避让并将焦点输入框滚动到可见区域, 拖动页面或点击空白处时收起键盘.
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

  /// 紧跟在标题后的简短状态文本 (如 "3 条未读" "仅自己可见"), 采用 `meta` 字号和 `ink-muted` 颜色, 空间不足时随标题自然换行.
  final String? titleNote;

  final List<Widget> slivers;

  /// 顶栏右侧的操作图标按钮列表.
  final List<Widget> actions;

  final bool showBack;

  /// 点击返回按钮的回调, 未传入时返回上一页或执行后备跳转.
  final VoidCallback? onBack;

  /// 页面滚动物理行为.
  ///
  /// 若页面包含地图等需手势拖动的组件, 在手指按压交互期间应传入 `NeverScrollableScrollPhysics`,
  /// 防止纵向拖动被页面滚动拦截.
  final ScrollPhysics? physics;

  /// 下拉刷新回调, 未传入时禁用下拉刷新.
  final Future<void> Function()? onRefresh;

  /// 替换标题展示在返回按钮右侧的自定义组件 (如搜索页搜索框), 传入时 [title] 仅提供给读屏.
  final Widget? header;

  @override
  State<PlainScaffold> createState() => _PlainScaffoldState();
}

class _PlainScaffoldState extends State<PlainScaffold>
    with ScrollToTopOnReselect {
  /// 记录内容是否已滚动到标题行下方.
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
        // 当内容不足一屏时默认不可滚动, 需强制允许滚动以使下拉手势能够触发刷新.
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
