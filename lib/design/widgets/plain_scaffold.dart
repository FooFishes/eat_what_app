import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 白底页面骨架, 用于消息, 选店, 搜索, 评论和设置.
///
/// - 返回按钮和 `page-title` 标题在同一行, 标题过长时换行, 左右边距 `space-20`.
/// - 宽屏时整页收窄为居中的一栏.
/// - 分组靠小标题和留白分隔, 不加卡片. [slivers] 已包含左右边距.
/// - 键盘弹出时页面避让到键盘上方, 获得焦点的输入框会滚动到可见位置.
/// - 拖动页面或点击空白处时收起键盘.
class PlainScaffold extends StatefulWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.slivers = const [],
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.physics,
  });

  final String title;

  /// 标题下方一两行的说明, 使用 `ink-muted`.
  final String? subtitle;

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
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: CustomScrollView(
                  controller: scrollController,
                  physics: widget.physics,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        widget.showBack
                            ? padding - EatBackButton.inset
                            : padding,
                        media.padding.top + 4,
                        widget.actions.isEmpty ? padding : padding - 4,
                        widget.subtitle == null ? 24 : 8,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            if (widget.showBack) ...[
                              EatBackButton(onPressed: widget.onBack),
                              const SizedBox(width: EatSpace.s4),
                            ],
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  widget.title,
                                  textScaler: TextScaler.noScaling,
                                  style: eat.text.heading.copyWith(
                                    color: eat.colors.ink,
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
                      ),
                    ),
                    if (widget.subtitle case final subtitle?)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            subtitle,
                            style: eat.text.body.copyWith(
                              color: eat.colors.inkMuted,
                            ),
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
          ),
        ),
      ),
    );
  }
}
