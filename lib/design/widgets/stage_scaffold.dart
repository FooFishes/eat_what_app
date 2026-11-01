import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
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
/// 抽屉中的 sliver 自行留出左右 `space-20`. 底部自动留出悬浮导航或系统安全区的高度.
class StageScaffold extends StatefulWidget {
  const new({
    super.key,
    required StageColor this.stage,
    required Widget this.stageContent,
    this.sheetSlivers = const [],
    this.topBar,
  }) : map = null;

  /// 以地图为舞台的页面, 如附近页. 地图铺在底层, 压在地图上的抽屉加阴影.
  const new map({
    super.key,
    required Widget this.map,
    this.sheetSlivers = const [],
    this.topBar,
  }) : stage = null,
       stageContent = null;

  final StageColor? stage;
  final Widget? stageContent;
  final Widget? map;
  final List<Widget> sheetSlivers;

  /// 舞台顶部的一行, 如返回, 收藏和分享, 或发现页的地点, 搜索和通知.
  final Widget? topBar;

  @override
  State<StageScaffold> createState() => _StageScaffoldState();
}

class _StageScaffoldState extends State<StageScaffold>
    with ScrollToTopOnReselect {
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

    final Widget body;
    if (layout.isWide) {
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
                    child: CustomScrollView(
                      controller: scrollController,
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
        ],
      );
    } else {
      final height = layout.stageHeight;
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
          CustomScrollView(
            controller: scrollController,
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
                      if (widget.topBar case final topBar?)
                        Positioned(
                          top: media.padding.top + 4,
                          left: 8,
                          right: 8,
                          child: onStage(topBar),
                        ),
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
