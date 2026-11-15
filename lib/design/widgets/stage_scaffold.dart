import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_refresh.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 有舞台的页面骨架: 上方为舞台, 下方为白色抽屉. 抽屉向上压住舞台, 随页面滚动.
///
/// 页面只提供舞台色, 舞台内容和抽屉中的 sliver. 舞台高度, 抽屉起点和宽屏布局由本组件决定:
/// - 手机: 舞台高度按屏幕高度计算. [stageContent] 获得整个舞台的高度,
///   但底部 [EatSize.sheetOverlap] 会被抽屉遮挡, 菜名, 价格和按钮须排在这段之上.
/// - 宽屏: 舞台铺满屏幕且不滚动, [stageContent] 排在左侧面板的右边.
///   抽屉变为左侧的悬浮面板, 内容在面板内单独滚动, [topBar] 移到面板顶部并使用 `ink`.
///
/// 手机上 [topBar] 固定在屏幕顶部, 不随页面滚动. 页面滚动到任意位置时, 返回和右上角的操作都可点击:
/// - 页面未滚动时顶栏没有底色, 图标使用舞台文字色.
/// - 抽屉滚动到顶栏下方时, 顶栏变为 `paper` 底和 `ink` 图标, 并显示其中的 [StageBarTitle].
/// - [pinnedBottom] 是抽屉第一行内容 (如分类栏) 的副本. 该行滚动到顶栏下方时, 副本显示在顶栏下方的同一位置.
///
/// 抽屉中的 sliver 自行留出左右 `space-20`. 底部自动留出悬浮导航或系统安全区的高度.
class StageScaffold extends StatefulWidget {
  const new({
    super.key,
    required StageColor this.stage,
    required Widget this.stageContent,
    this.sheetSlivers = const [],
    this.topBar,
    this.pinnedBottom,
    this.onRefresh,
  }) : map = null;

  /// 以地图为舞台的页面, 如附近页. 地图铺在底层, 压在地图上的抽屉加阴影.
  const new map({
    super.key,
    required Widget this.map,
    this.sheetSlivers = const [],
    this.topBar,
    this.onRefresh,
  }) : stage = null,
       stageContent = null,
       pinnedBottom = null;

  final StageColor? stage;
  final Widget? stageContent;
  final Widget? map;
  final List<Widget> sheetSlivers;

  /// 舞台顶部的一行, 如返回, 收藏和分享, 或发现页的地点, 搜索和通知.
  final Widget? topBar;

  /// 抽屉第一行内容的副本, 在该行滚动到顶栏下方后显示.
  ///
  /// 传入时 [sheetSlivers] 的第一项必须是同一行内容. 副本出现的位置按第一项的位置计算.
  final Widget? pinnedBottom;

  /// 下拉刷新. 不传时页面不能下拉刷新.
  final Future<void> Function()? onRefresh;

  /// 手机布局下固定顶栏底边的纵坐标, 舞台内容不要排到这条线以上.
  static double barBottomOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + 4 + _StageScaffoldState._barHeight;

  @override
  State<StageScaffold> createState() => _StageScaffoldState();
}

class _StageScaffoldState extends State<StageScaffold>
    with ScrollToTopOnReselect {
  /// 顶栏一行的高度.
  static const _barHeight = 52.0;

  /// 抽屉顶部把手占的高度: 上留白 10, 把手 4, 下留白 14.
  static const _handleExtent = 28.0;

  /// 页面滚动超过该距离后, 顶栏以舞台色为底. 否则滚动到顶栏位置的盘子和文字会与顶栏图标重叠.
  static const _liftSpan = 16.0;

  /// 抽屉顶边距顶栏底边 [_pinLead] 时, 顶栏开始过渡到白底样式. 再滚动 [_pinSpan] 后过渡完成.
  static const _pinLead = 8.0;
  static const _pinSpan = 24.0;

  /// 顶栏的状态.
  ///
  /// - `lift`: 0 为没有底色, 1 为铺满舞台色.
  /// - `pin`: 0 为舞台样式, 1 为白底样式.
  /// - `row`: 抽屉第一行是否已滚动到顶栏下方.
  final _bar = ValueNotifier<({double lift, double pin, bool row})>((
    lift: 0,
    pin: 0,
    row: false,
  ));

  /// 手机布局下舞台的高度和顶栏底边的纵坐标. 每次 build 时更新, 滚动时据此计算 [_bar].
  double? _stageHeight;
  double _barBottom = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    _bar.dispose();
    super.dispose();
  }

  void _onScroll() {
    final stageHeight = _stageHeight;
    if (stageHeight == null || !scrollController.hasClients) return;
    final offset = scrollController.offset;
    final sheetTop = stageHeight - EatSize.sheetOverlap - offset;
    _bar.value = (
      lift: (offset / _liftSpan).clamp(0.0, 1.0),
      pin: ((_barBottom + _pinLead - sheetTop) / _pinSpan).clamp(0.0, 1.0),
      row: sheetTop + _handleExtent <= _barBottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    if (stage == null) return _build(context, null);
    return AnimatedStageTheme(stage: stage, builder: _build);
  }

  Widget _build(BuildContext context, StagePalette? palette) {
    final eat = context.eat;
    final layout = EatLayout.of(context);
    final media = MediaQuery.of(context);
    final navInset = NavBarInset.of(context);
    final bottomSpace = navInset > 0
        ? navInset
        : media.padding.bottom + EatSpace.s24;
    final backdrop =
        widget.map ??
        ColoredBox(color: palette!.background, child: const SizedBox.expand());
    final onMap = widget.map != null;

    Widget onStage(Widget child) => palette == null
        ? child
        : DefaultTextStyle.merge(
            style: TextStyle(color: palette.foreground),
            child: child,
          );

    Widget refreshable(Widget scroll, {double edgeOffset = 0}) =>
        switch (widget.onRefresh) {
          final onRefresh? => EatRefresh(
            onRefresh: onRefresh,
            edgeOffset: edgeOffset,
            child: scroll,
          ),
          null => scroll,
        };
    // 内容不足一屏时默认不能滚动, 下拉手势不会触发刷新.
    final physics = widget.onRefresh == null
        ? null
        : const AlwaysScrollableScrollPhysics();

    final Widget body;
    if (layout.isWide) {
      _stageHeight = null;
      const inset = EatLayout.widePanelInset;
      body = Stack(
        children: [
          Positioned.fill(child: backdrop),
          if (widget.stageContent case final content?)
            Positioned(
              left: inset + EatLayout.widePanelWidth,
              top: 0,
              right: 0,
              bottom: 0,
              child: onStage(content),
            ),
          Positioned(
            left: inset,
            top: inset,
            bottom: inset,
            width: EatLayout.widePanelWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: eat.colors.paper,
                borderRadius: const BorderRadius.all(EatRadius.sheet),
                boxShadow: onMap ? eat.shadows.float.outer : null,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(EatRadius.sheet),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: eat.colors.ink),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    child: refreshable(
                      CustomScrollView(
                        controller: scrollController,
                        physics: physics,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 12),
                            sliver: SliverToBoxAdapter(child: widget.topBar),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: EatSpace.s14),
                          ),
                          ...widget.sheetSlivers,
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: navInset > 0 ? navInset : EatSpace.s24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final height = layout.stageHeight;
      final barTop = media.padding.top + 4;
      _stageHeight = height;
      _barBottom = barTop + _barHeight;
      body = Stack(
        children: [
          // 只在页面顶部回弹 (iOS) 时露出, 避免舞台上方出现白边.
          if (palette != null)
            ListenableBuilder(
              listenable: scrollController,
              builder: (context, _) {
                final offset = scrollController.hasClients
                    ? scrollController.offset
                    : 0.0;
                return SizedBox(
                  height: (height - offset).clamp(0.0, double.infinity),
                  width: double.infinity,
                  child: ColoredBox(color: palette.background),
                );
              },
            ),
          refreshable(
            edgeOffset: _barBottom,
            CustomScrollView(
              controller: scrollController,
              physics: physics,
              paintOrder: SliverPaintOrder.lastIsTop,
              slivers: [
                _OverlappedSliver(
                  overlap: EatSize.sheetOverlap,
                  child: SizedBox(
                    height: height,
                    child: Stack(
                      children: [
                        Positioned.fill(child: backdrop),
                        if (widget.stageContent case final content?)
                          Positioned.fill(child: onStage(content)),
                      ],
                    ),
                  ),
                ),
                _SheetSliver(
                  decoration: BoxDecoration(
                    color: eat.colors.paper,
                    borderRadius: const BorderRadius.vertical(
                      top: EatRadius.sheet,
                    ),
                    boxShadow: onMap ? eat.shadows.sheet.outer : null,
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      const SliverPadding(
                        padding: EdgeInsets.only(top: 10, bottom: EatSpace.s14),
                        sliver: SliverToBoxAdapter(child: SheetHandle()),
                      ),
                      ...widget.sheetSlivers,
                      SliverToBoxAdapter(child: SizedBox(height: bottomSpace)),
                    ],
                  ),
                ),
                // 内容不满一屏时白底延伸到底部, 避免抽屉在页面中间断开.
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ColoredBox(color: eat.colors.paper),
                ),
              ],
            ),
          ),
          if (widget.topBar case final topBar?)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _pinnedBar(context, palette, topBar, barTop),
            ),
        ],
      );
    }

    final dark = palette?.isDark ?? false;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark && !layout.isWide
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: ColoredBox(color: eat.colors.paper, child: body),
    );
  }

  /// 固定在屏幕顶部的顶栏. 颜色随 [_bar] 在舞台样式和白底样式之间过渡.
  ///
  /// [topBar] 中的图标和文字从 [StageTheme] 和默认文字色取色. 两者随过渡进度插值, 页面无需处理颜色.
  Widget _pinnedBar(
    BuildContext context,
    StagePalette? palette,
    Widget topBar,
    double barTop,
  ) {
    final eat = context.eat;
    final c = eat.colors;
    final plain = StagePalette(
      background: c.paper,
      foreground: c.ink,
      secondaryForeground: c.inkMuted,
      ghost: c.mist,
      table: c.mist,
      tableRing: c.hairline,
      solid: c.ink,
      solidForeground: c.paper,
      isDark: false,
    );
    return ValueListenableBuilder(
      valueListenable: _bar,
      builder: (context, bar, _) {
        // 以地图为舞台时没有舞台色, 顶栏始终使用白底样式.
        final pin = palette == null ? 1.0 : bar.pin;
        final colors = palette == null
            ? plain
            : StagePalette.lerp(palette, plain, pin);
        final fill = palette == null
            ? c.paper
            : Color.lerp(
                palette.background.withValues(alpha: bar.lift),
                c.paper,
                pin,
              )!;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: colors.isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Stack(
            children: [
              // 顶栏有底色时拦截点击. 否则点击会传到被顶栏遮挡的舞台内容.
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: fill.a == 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: fill,
                      border: Border(
                        bottom: BorderSide(
                          color: c.hairline.withValues(alpha: pin),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: barTop),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: _barHeight,
                      child: StageTheme(
                        palette: colors,
                        child: _StageBarPin(
                          pin: pin,
                          child: DefaultTextStyle.merge(
                            style: TextStyle(color: colors.foreground),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: topBar,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.pinnedBottom case final row? when bar.row)
                      DefaultTextStyle.merge(
                        style: TextStyle(color: c.ink),
                        child: row,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 顶栏换成白底样式的进度, 由 [StageScaffold] 提供给顶栏里的 [StageBarTitle].
class _StageBarPin extends InheritedWidget {
  const new({required this.pin, required super.child});

  final double pin;

  @override
  bool updateShouldNotify(_StageBarPin oldWidget) => pin != oldWidget.pin;
}

/// 舞台页顶栏中的标题, 如菜名, 店名和昵称. 位于返回按钮和右侧按钮之间, 通常放在 `Expanded` 中.
///
/// - 顶栏为舞台样式时不显示, 因为舞台上已有同样的文字.
/// - 顶栏过渡到白底样式时淡入. 此时舞台已滚出屏幕, 标题说明当前所在的页面.
/// - 宽屏时舞台不滚动, 始终不显示.
class StageBarTitle extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final pin =
        context.dependOnInheritedWidgetOfExactType<_StageBarPin>()?.pin ?? 0;
    if (pin == 0) return const SizedBox();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: pin,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            style: context.eat.text.subhead,
          ),
        ),
      ),
    );
  }
}

/// 布局高度比内容少 [overlap] 的 sliver.
///
/// 后续 sliver 从其底部向上 [overlap] 处开始排列. 多出的部分绘制在自身范围之外,
/// 配合 `SliverPaintOrder.lastIsTop` 被后续的抽屉覆盖, 形成抽屉压住舞台的效果.
class _OverlappedSliver extends SingleChildRenderObjectWidget {
  const new({required this.overlap, required Widget super.child});

  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverlappedSliver(overlap);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOverlappedSliver renderObject,
  ) => renderObject.overlap = overlap;
}

class _RenderOverlappedSliver extends RenderSliverSingleBoxAdapter {
  _RenderOverlappedSliver(this._overlap);

  double _overlap;
  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final extent = child.size.height;
    final scrollExtent = (extent - _overlap).clamp(0.0, extent);
    // 绘制范围报告为与布局范围相同, 多出的 [_overlap] 绘制在范围之外.
    // 若报告更大的绘制范围, 视口会按重叠高度裁掉后续 sliver 的语义, 抽屉第一行按钮在读屏中不完整.
    final layoutExtent = calculatePaintOffset(
      constraints,
      from: 0,
      to: scrollExtent,
    );
    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintExtent: layoutExtent,
      layoutExtent: layoutExtent,
      maxPaintExtent: extent,
      hasVisualOverflow: true,
    );
    setChildParentData(child, constraints, geometry!);
  }
}

/// 抽屉的白底. 绘制方式与 `DecoratedSliver` 相同, 但白底本身也拦截点击.
///
/// 因此点击抽屉压住舞台的区域不会传到下方舞台的组件, 点击抽屉内的空白处也不会穿透.
class _SheetSliver extends DecoratedSliver {
  const new({required super.decoration, super.sliver});

  @override
  RenderDecoratedSliver createRenderObject(BuildContext context) =>
      _RenderSheetSliver(
        decoration: decoration,
        configuration: createLocalImageConfiguration(context),
      );
}

class _RenderSheetSliver extends RenderDecoratedSliver {
  _RenderSheetSliver({required super.decoration, super.configuration});

  @override
  bool hitTestSelf({
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) => true;
}
