import 'dart:math' as math;

import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_refresh.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/remove_padding.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 带有顶部彩色舞台与下方白色抽屉的页面骨架, 抽屉向上压住舞台并随页面一起滚动.
///
/// 调用方仅需传入舞台色, 舞台内容和抽屉 sliver, 舞台高度, 抽屉起点及宽屏适配均由本组件接管:
/// - 手机布局: 舞台高度按屏幕高度计算, [stageContent] 占据完整舞台高度,
///   但底部 [EatSize.sheetOverlap] 区域会被抽屉遮挡, 因此菜名, 价格和按钮需排在该区域之上.
/// - 宽屏布局: 舞台铺满全屏且不滚动, [stageContent] 排布在左侧悬浮面板右侧,
///   抽屉转变为独立滚动的左侧面板且 [topBar] 移至面板顶部并采用 `ink` 配色.
///
/// 手机布局下 [topBar] 固定在屏幕顶部以确保页面滚动到任意位置时返回与右上角操作始终可点:
/// - 页面未滚动时顶栏透明无底色, 图标使用舞台文字色.
/// - 当抽屉滚入顶栏下方时, 顶栏过渡为 `paper` 底色与 `ink` 图标并淡入其中的 [StageBarTitle].
/// - [pinnedBottom] 为抽屉第一行内容 (如分类栏) 的副本, 该行滚至顶栏下方时副本会吸顶固定在顶栏正下方.
///
/// 手机布局下舞台默认随页面一起滚走; [fixedStage] 为 true 时舞台固定在底层, 上滑时抽屉从下方盖住舞台,
/// 滑到头时没有拉伸效果: 顶部滑到头就停 (下拉交给刷新), 底部继续上拉时整块抽屉跟着上移, 松手回弹.
///
/// 抽屉中的 sliver 需自行预留左右 `space-20` 边距, 底部则自动留出悬浮导航或系统安全区高度.
class StageScaffold extends StatefulWidget {
  const new({
    super.key,
    required StageColor this.stage,
    required Widget this.stageContent,
    this.sheetSlivers = const [],
    this.topBar,
    this.pinnedBottom,
    this.onRefresh,
    this.fixedStage = false,
  }) : map = null;

  /// 构建以地图为舞台的页面骨架 (如附近页), 地图铺于底层而抽屉叠加阴影压在地图之上.
  const new map({
    super.key,
    required Widget this.map,
    this.sheetSlivers = const [],
    this.topBar,
    this.onRefresh,
  }) : stage = null,
       stageContent = null,
       pinnedBottom = null,
       fixedStage = false;

  final StageColor? stage;
  final Widget? stageContent;
  final Widget? map;
  final List<Widget> sheetSlivers;

  /// 舞台顶部操作栏, 如返回, 收藏与分享按钮, 或发现页的地点, 搜索与通知入口.
  final Widget? topBar;

  /// 抽屉第一行内容的吸顶副本, 在该行滚至顶栏下方后固定展示.
  ///
  /// 传入时须与 [sheetSlivers] 的第一项保持完全一致, 其显现时机也依据该首项位置计算.
  final Widget? pinnedBottom;

  /// 下拉刷新回调, 未传入时禁用下拉刷新.
  final Future<void> Function()? onRefresh;

  /// 手机布局下舞台是否固定在底层不随滚动移动, 上滑时由抽屉盖住. 宽屏布局的舞台始终固定, 不受影响.
  final bool fixedStage;

  /// 手机布局下固定顶栏底边的纵坐标, 舞台内容应排布在该线以下.
  static double barBottomOf(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).top +
      4 +
      _StageScaffoldState._barHeight;

  @override
  State<StageScaffold> createState() => _StageScaffoldState();
}

class _StageScaffoldState extends State<StageScaffold>
    with ScrollToTopOnReselect {
  /// 顶栏单行高度.
  static const _barHeight = 52.0;

  /// 抽屉顶部把手区域总高度: 上留白 10, 把手 4, 下留白 14.
  static const _handleExtent = 28.0;

  /// 舞台色顶栏背景生效的滚动阈值: 滚动超过该距离后顶栏铺设舞台底色, 避免上移的盘子和文字与顶栏图标重叠.
  static const _liftSpan = 16.0;

  /// 抽屉顶边距顶栏底边 [_pinLead] 时顶栏开始过渡到白底样式, 继续滚动 [_pinSpan] 后过渡完成.
  static const _pinLead = 8.0;
  static const _pinSpan = 24.0;

  /// 顶栏的实时交互状态.
  ///
  /// - `lift`: 0 为透明无底色, 1 为完全铺满舞台色.
  /// - `pin`: 0 为舞台样式, 1 为白底样式.
  /// - `row`: 抽屉第一行是否已滚动到顶栏下方.
  final _bar = ValueNotifier<({double lift, double pin, bool row})>((
    lift: 0,
    pin: 0,
    row: false,
  ));

  /// 手机布局下舞台的高度和顶栏底边纵坐标, 每次 build 时更新供滚动监听计算 [_bar].
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
      // 舞台固定时没有内容从顶栏下方穿过, 不需要垫舞台色.
      lift: widget.fixedStage ? 0.0 : (offset / _liftSpan).clamp(0.0, 1.0),
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
    final safe = MediaQuery.viewPaddingOf(context);
    final navInset = NavBarInset.of(context);
    final bottomSpace = navInset > 0 ? navInset : safe.bottom + EatSpace.s24;
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
    // 当内容不足一屏时默认不可滚动, 需强制允许滚动以使下拉手势能够触发刷新.
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
                  child: RemovePadding(
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
      final barTop = safe.top + 4;
      _stageHeight = height;
      _barBottom = barTop + _barHeight;
      body = Stack(
        children: [
          // 仅在 iOS 等平台触发顶部弹性回弹时露出, 避免舞台上方出现白色空隙.
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
              physics: widget.fixedStage
                  ? _SheetBounceScrollPhysics(
                      parent: physics,
                      snapOffset:
                          height -
                          EatSize.sheetOverlap +
                          _handleExtent -
                          _barBottom,
                    )
                  : physics,
              // 舞台固定时, 滑到头的拉伸效果会把底层舞台一起拉变形, 所以关掉, 到底的反馈改由回弹给出.
              scrollBehavior: widget.fixedStage
                  ? ScrollConfiguration.of(context).copyWith(overscroll: false)
                  : null,
              paintOrder: SliverPaintOrder.lastIsTop,
              slivers: [
                _OverlappedSliver(
                  overlap: EatSize.sheetOverlap,
                  pinned: widget.fixedStage,
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
                // 内容不满一屏时将白底延伸至页面底部, 避免抽屉在页面中间提前断开.
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

  /// 构建固定在屏幕顶部的顶栏, 其颜色随 [_bar] 状态在舞台样式和白底样式之间插值过渡.
  ///
  /// [topBar] 内的图标和文字自动从 [StageTheme] 与默认文字色取色, 两者随进度同步插值, 页面无需单独处理配色.
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
        // 以地图为舞台时不存在舞台色, 顶栏始终保持白底样式.
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
              // 顶栏具有底色时拦截点击事件, 防止点击穿透至被遮挡的舞台内容.
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

/// 顶栏向白底样式过渡的进度值, 由 [StageScaffold] 注入给顶栏中的 [StageBarTitle].
class _StageBarPin extends InheritedWidget {
  const new({required this.pin, required super.child});

  final double pin;

  @override
  bool updateShouldNotify(_StageBarPin oldWidget) => pin != oldWidget.pin;
}

/// 舞台页顶栏中的标题组件 (如菜名, 店名和昵称), 位于返回按钮与右侧按钮之间, 通常包裹在 `Expanded` 中.
///
/// - 顶栏处于舞台样式时不显示, 以免与舞台上已有的相同文字重复.
/// - 顶栏过渡为白底样式时随进度淡入, 在舞台滚出屏幕后标明当前所在页面.
/// - 宽屏布局下舞台固定不滚动, 该标题始终保持隐藏.
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

/// 布局高度比实际内容少 [overlap] 的 sliver 容器.
///
/// 后续 sliver 会从其底部向上 [overlap] 处开始排列,
/// 配合 `SliverPaintOrder.lastIsTop` 使溢出部分被后续抽屉覆盖, 形成抽屉压住舞台的层叠效果.
///
/// [pinned] 为 true 时内容始终画在视口顶部, 不随滚动移动, 抽屉照常上移并逐渐盖住它.
/// 舞台仍在滚动视图内, 所以拖动舞台照样滚动页面, 下拉刷新和顶栏变色也照常按滚动位置计算.
class _OverlappedSliver extends SingleChildRenderObjectWidget {
  const new({
    required this.overlap,
    this.pinned = false,
    required Widget super.child,
  });

  final double overlap;
  final bool pinned;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverlappedSliver(overlap, pinned);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOverlappedSliver renderObject,
  ) => renderObject
    ..overlap = overlap
    ..pinned = pinned;
}

class _RenderOverlappedSliver extends RenderSliverSingleBoxAdapter {
  _RenderOverlappedSliver(this._overlap, this._pinned);

  double _overlap;
  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  bool _pinned;
  set pinned(bool value) {
    if (value == _pinned) return;
    _pinned = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final extent = child.size.height;
    final scrollExtent = (extent - _overlap).clamp(0.0, extent);
    // 刻意将绘制范围报告为与布局范围相同, 多出的 [_overlap] 绘制在范围之外.
    // 若如实报告更大的绘制范围, 视口会按重叠高度裁掉后续 sliver 的语义区域, 导致抽屉第一行按钮在读屏中不完整.
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
      // 固定时布局范围缩到 0 才说明舞台已被抽屉完全盖住, 在那之前都要绘制.
      visible: _pinned ? constraints.scrollOffset < scrollExtent : null,
      hasVisualOverflow: true,
    );
    if (_pinned) {
      (child.parentData! as SliverPhysicalParentData).paintOffset = Offset.zero;
    } else {
      setChildParentData(child, constraints, geometry!);
    }
  }

  /// 固定时舞台不随滚动移动, 命中测试和绘制一样以视口顶部为原点.
  @override
  double childMainAxisPosition(RenderBox child) =>
      _pinned ? 0 : super.childMainAxisPosition(child);
}

/// 舞台固定时的滚动物理: 顶部和 Android 默认一样滑到头就停, 越界的下拉交给刷新; 底部可以越界, 整块抽屉跟着手指上移, 松手回弹.
///
/// 只在底部回弹, 是因为顶部越界会把固定的舞台一起拉下来, 也会和下拉刷新抢手势.
///
/// 往上甩时若惯性会越过 [snapOffset] (抽屉第一行吸顶的位置), 改为减速停在那里, 不带着推荐流继续冲下去; 到不了的甩动照常.
class _SheetBounceScrollPhysics extends BouncingScrollPhysics {
  const new({super.parent, this.snapOffset});

  /// 抽屉第一行刚好滚到顶栏下方时的滚动位置.
  final double? snapOffset;

  /// 手指拖动时底部最多越界的距离. 回弹只是到底的提示, 不需要像 iOS 那样能拉很远.
  static const _maxDragOverscroll = 128.0;

  @override
  _SheetBounceScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SheetBounceScrollPhysics(
        parent: buildParent(ancestor),
        snapOffset: snapOffset,
      );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final simulation = super.createBallisticSimulation(position, velocity);
    final snap = snapOffset;
    if (simulation == null ||
        snap == null ||
        velocity <= 0 ||
        position.pixels >= snap - toleranceFor(position).distance ||
        snap >= position.maxScrollExtent ||
        simulation.x(_settleTime) <= snap) {
      return simulation;
    }
    return _SnapSimulation(
      start: position.pixels,
      end: snap,
      velocity: velocity,
      tolerance: toleranceFor(position),
    );
  }

  /// 判断惯性最终停在哪里时取的时刻, 足够让模拟停下.
  static const _settleTime = 60.0;

  /// 越界后的拖动阻力, 约为 [BouncingScrollPhysics] 默认值的六成, 越往外越难拖.
  @override
  double frictionFactor(double overscrollFraction) =>
      0.3 * math.pow(1 - overscrollFraction, 2);

  /// 拖动越界不超过 [_maxDragOverscroll].
  ///
  /// 上限只加在手指拖动上: 若在 [applyBoundaryConditions] 里挡住, 惯性滚动撞到上限时会直接停下, 停在越界处不再回弹.
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final applied = super.applyPhysicsToUserOffset(position, offset);
    if (applied >= 0 || position.pixels < position.maxScrollExtent) {
      return applied;
    }
    final room =
        _maxDragOverscroll - (position.pixels - position.maxScrollExtent);
    return math.max(applied, -math.max(room, 0.0));
  }

  /// 比默认略硬的回弹弹簧 (默认刚度 100): 快速甩到底时冲出去少一些, 回弹仍然柔和.
  @override
  SpringDescription get spring =>
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 200, ratio: 1.1);

  /// 顶部按 [ClampingScrollPhysics] 的规则挡住越界, 底部照 [BouncingScrollPhysics] 放行.
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels) {
      return value - position.minScrollExtent;
    }
    return 0;
  }
}

/// 从当前位置匀减速到 [end] 停住, 不越过终点.
///
/// 按离手速度算减速时长, 使起步速度和离手时一致; 距离太近, 速度太快时至少用 [_minDuration], 起步速度相应放慢, 避免急刹.
class _SnapSimulation extends Simulation {
  _SnapSimulation({
    required double start,
    required double end,
    required double velocity,
    super.tolerance,
  }) : _start = start,
       _distance = end - start,
       _duration = math.max(2 * (end - start) / velocity, _minDuration);

  static const _minDuration = 0.2;

  final double _start;
  final double _distance;
  final double _duration;

  double _progress(double time) => (time / _duration).clamp(0.0, 1.0);

  @override
  double x(double time) {
    final rest = 1 - _progress(time);
    return _start + _distance * (1 - rest * rest);
  }

  @override
  double dx(double time) => 2 * _distance * (1 - _progress(time)) / _duration;

  @override
  bool isDone(double time) => time >= _duration;
}

/// 抽屉的白色背景 sliver; 绘制方式与 `DecoratedSliver` 相同, 但同时拦截自身区域的命中测试.
///
/// 借此阻止点击抽屉压住舞台的区域时事件穿透至下方舞台组件, 点击抽屉内空白处也不会穿透.
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
