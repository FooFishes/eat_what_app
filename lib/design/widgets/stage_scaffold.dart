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

/// 有舞台的页面骨架：上面是舞台，下面是白色抽屉，抽屉往上压住舞台 32px，跟着页面一起滚。
///
/// 页面只给舞台色、舞台内容和抽屉里的 sliver，舞台多高、抽屉从哪开始、宽屏怎么排都由这里决定：
/// - 手机：舞台高度按屏幕高度算（844 高时 520，夹在 420–560），[stageContent] 拿到整个舞台的高度，
///   但底部 32px 会被抽屉盖住，菜名、价格、按钮要贴着底部留出这段再排。
/// - 宽屏（600 及以上）：舞台铺满整个屏幕、不滚动，[stageContent] 排在左侧面板右边；抽屉变成
///   左侧 400 宽的悬浮面板，内容在面板里单独滚，[topBar] 挪到面板顶部、用 `ink`。
///
/// 抽屉里的 sliver 自己留左右 `space-20`；底部会自动留出悬浮导航（或系统安全区）的高度。
class StageScaffold extends StatefulWidget {
  const new({
    super.key,
    required StageColor this.stage,
    required Widget this.stageContent,
    this.sheetSlivers = const [],
    this.topBar,
  }) : map = null;

  /// 附近页这类用地图当舞台的页面：地图铺在下面，抽屉压在地图上要加阴影。
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

  /// 舞台顶部的一行：返回、收藏、分享，或发现页的地点、搜索、通知。
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
          // 只在页面顶部回弹（iOS）时露出来，让舞台上方不出现白边。
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
              // 内容不满一屏时把白底铺到底，抽屉不会在页面中间断开。
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

/// 布局高度比绘制高度少 [overlap] 的 sliver：后面的 sliver 从它底部往上 [overlap] 处开始排，
/// 配合 `SliverPaintOrder.lastIsTop` 画在它上面，形成抽屉压住舞台的样子。
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
    final paintExtent = calculatePaintOffset(constraints, from: 0, to: extent);
    final layoutExtent = calculatePaintOffset(
      constraints,
      from: 0,
      to: scrollExtent,
    );
    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintExtent: paintExtent,
      layoutExtent: layoutExtent.clamp(0.0, paintExtent),
      maxPaintExtent: extent,
      hitTestExtent: paintExtent,
      hasVisualOverflow:
          extent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0,
    );
    setChildParentData(child, constraints, geometry!);
  }
}

/// 抽屉的白底。和 `DecoratedSliver` 一样画，但白底本身也接住点击：
/// 抽屉压住舞台的那 32px 里点不到下面舞台上的东西，抽屉里的空白处也不会点穿。
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
