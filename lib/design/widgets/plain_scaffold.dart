import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 白底页面骨架（消息、选店、搜索、评论、设置）：左上角 44×44 的返回，下面 `page-title` 大标题，
/// 左右边距 `space-20`。宽屏时整页挤到居中一栏，最宽 480。
///
/// 分组靠 13px 的小标题和留白，不加卡片；[slivers] 已经套好了左右边距。
class PlainScaffold extends StatefulWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.slivers = const [],
    this.actions = const [],
    this.showBack = true,
    this.onBack,
  });

  final String title;

  /// 标题下面一两行的说明，`ink-muted`。
  final String? subtitle;

  final List<Widget> slivers;

  /// 顶栏右边的图标按钮。
  final List<Widget> actions;

  final bool showBack;

  /// 不传时返回上一页，没有上一页时回到兜底页面。
  final VoidCallback? onBack;

  @override
  State<PlainScaffold> createState() => _PlainScaffoldState();
}

class _PlainScaffoldState extends State<PlainScaffold>
    with ScrollToTopOnReselect {
  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final media = MediaQuery.of(context);
    final padding = EatLayout.of(context).plainHorizontalPadding;
    final navInset = NavBarInset.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: eat.colors.paper,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: eat.colors.ink),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding - 12,
                  media.padding.top + 2,
                  padding - 4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: EatSize.touch,
                    child: Row(
                      children: [
                        if (widget.showBack)
                          EatBackButton(onPressed: widget.onBack),
                        const Spacer(),
                        ...widget.actions,
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, 8, padding, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: EatSpace.s4,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          widget.title,
                          textScaler: TextScaler.noScaling,
                          style: eat.text.pageTitle.copyWith(
                            color: eat.colors.ink,
                          ),
                        ),
                      ),
                      if (widget.subtitle case final subtitle?)
                        Text(
                          subtitle,
                          style: eat.text.body.copyWith(
                            fontSize: 14,
                            height: 22 / 14,
                            color: eat.colors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
          ),
        ),
      ),
    );
  }
}
