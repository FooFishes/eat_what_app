import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 从页面上的一小块 (如分类栏的一项) 长出来的小浮层, 大小随内容, 出现在那一块的正下方.
///
/// - [anchor] 不为 null 时打开, 变为 null 时收回那一块. 打开时位置, 大小, 圆角, 底色 (`paper`) 和投影
///   (`shadow-float`) 一起从那一块过渡到浮层, 内容随后淡入, 动效和 `showMorphCard` 一样用 [EatMotion.morph].
///   系统开启减少动态效果时直接出现和消失.
/// - 开着时换成另一个 [anchor], 浮层从当前位置挪到新那一块下面, 内容换成 [builder] 新给的.
/// - 不挡住页面, 浮层外面照常能点. [child] 和浮层算一个整体, 点 [child] (如分类栏本身) 不算点外面;
///   点其他地方或系统返回时调用 [onDismiss], 由调用方把 [anchor] 置空.
///   同一块在页面上还有副本 (如吸顶的分类栏) 时, 把副本包进 `groupId` 相同的 [TapRegion], 点副本也不算点外面.
/// - 浮层左右至少离屏幕边缘 `space-20`, 水平方向尽量对着那一块的中心.
class MorphPopover extends StatefulWidget {
  const new({
    super.key,
    required this.anchor,
    required this.builder,
    required this.onDismiss,
    required this.child,
    this.gap = EatSpace.s8,
    this.padding = const EdgeInsets.all(EatSpace.s14),
    this.label,
    this.groupId,
  });

  /// 浮层从哪一块长出来; null 表示关着.
  ///
  /// 通常只有一个 key. 同一块在页面上有几份 (如分类栏和它吸顶的副本, 同一时刻只有一份看得见) 时,
  /// 按优先顺序列出各份的 key, 浮层挂在第一份还在界面上的那一块上.
  final List<GlobalKey>? anchor;

  final WidgetBuilder builder;
  final VoidCallback onDismiss;
  final Widget child;

  /// 浮层顶边离那一块底边的距离.
  final double gap;

  /// 浮层内容四周的留白.
  final EdgeInsetsGeometry padding;

  /// 读屏对浮层的称呼.
  final String? label;

  /// 浮层和 [child] 所在的 [TapRegion] 分组, 不传时自己建一个.
  final Object? groupId;

  @override
  State<MorphPopover> createState() => _MorphPopoverState();
}

/// 浮层在某一时刻的样子: [rect] 是位置和大小, [style] 从 0 (还是那一块, 透明无投影) 到 1 (完整的浮层).
typedef _Pose = ({Rect rect, double style});

class _MorphPopoverState extends State<MorphPopover>
    with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  final _ownGroup = Object();
  Object get _group => widget.groupId ?? _ownGroup;
  final _box = GlobalKey();
  late final _controller = AnimationController(vsync: this)
    ..addStatusListener(_onStatus);

  /// 正在显示或正在收回的浮层挂在哪一块上.
  List<GlobalKey>? _shown;

  /// 这一段动画的起点; null 表示从 [_shown] 那一块出发.
  _Pose? _from;

  /// 这一段动画的终点是完整的浮层 (true) 还是收回那一块 (false).
  var _toCard = true;

  @override
  void initState() {
    super.initState();
    if (widget.anchor case final anchor?) {
      _shown = anchor;
      _controller.value = 1;
      _portal.show();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.motion(EatMotion.morph);
  }

  @override
  void didUpdateWidget(MorphPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final anchor = widget.anchor;
    if (listEquals(anchor, oldWidget.anchor)) return;
    if (anchor == null && _shown == null) return;
    final box = _box.currentContext?.findRenderObject() as _RenderPopover?;
    _from = _shown == null ? null : box?.pose;
    if (anchor != null) {
      _shown = anchor;
      _toCard = true;
    } else {
      _toCard = false;
    }
    if (_portal.isShowing) {
      _controller.forward(from: 0);
      return;
    }
    // 浮层只在开着和收回途中挂到 Overlay 上. didUpdateWidget 在 build 期间, 不能调用 show, 等这一帧画完再挂.
    _controller.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_toCard || _portal.isShowing) return;
      _portal.show();
      _controller.forward(from: 0);
    });
  }

  void _onStatus(AnimationStatus status) {
    if (!status.isCompleted || _toCard) return;
    // 减少动态效果时动画在 didUpdateWidget 里就走完了, 同样要等这一帧画完再摘下.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _toCard) return;
      _portal.hide();
      setState(() {
        _shown = null;
        _from = null;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.anchor != null;
    return PopScope(
      canPop: !open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.anchor != null) widget.onDismiss();
      },
      child: TapRegion(
        groupId: _group,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: _overlay,
          child: widget.child,
        ),
      ),
    );
  }

  Widget _overlay(BuildContext context) {
    final anchor = _shown;
    if (anchor == null) return const SizedBox.shrink();
    final eat = context.eat;
    final content = TapRegion(
      groupId: _group,
      onTapOutside: (_) {
        if (widget.anchor != null) widget.onDismiss();
      },
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: widget.label,
        child: Padding(padding: widget.padding, child: widget.builder(context)),
      ),
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = EatMotion.morph.curve.transform(_controller.value);
        final style = lerpDouble(_from?.style ?? 0, _toCard ? 1 : 0, t)!;
        return _PopoverLayout(
          key: _box,
          anchor: anchor,
          from: _from,
          toCard: _toCard,
          t: t,
          style: style,
          // 收回时和刚开始长出来时都不能点.
          interactive: _toCard && style >= 0.6,
          gap: widget.gap,
          color: eat.colors.paper,
          shadows: eat.shadows.float.outer,
          child: child,
        );
      },
      child: content,
    );
  }
}

class _PopoverLayout extends SingleChildRenderObjectWidget {
  const new({
    super.key,
    required this.anchor,
    required this.from,
    required this.toCard,
    required this.t,
    required this.style,
    required this.interactive,
    required this.gap,
    required this.color,
    required this.shadows,
    super.child,
  });

  final List<GlobalKey> anchor;
  final _Pose? from;
  final bool toCard;
  final double t;
  final double style;
  final bool interactive;
  final double gap;
  final Color color;
  final List<BoxShadow> shadows;

  @override
  _RenderPopover createRenderObject(BuildContext context) => _RenderPopover()
    ..anchor = anchor
    ..from = from
    ..toCard = toCard
    ..t = t
    ..style = style
    ..interactive = interactive
    ..gap = gap
    ..color = color
    ..shadows = shadows;

  @override
  void updateRenderObject(BuildContext context, _RenderPopover renderObject) {
    renderObject
      ..anchor = anchor
      ..from = from
      ..toCard = toCard
      ..t = t
      ..style = style
      ..interactive = interactive
      ..gap = gap
      ..color = color
      ..shadows = shadows
      ..markNeedsPaint();
  }
}

/// 铺满浮层所在的 Overlay, 但只在浮层那一块里接收点击, 其余地方的点击落到下面的页面.
///
/// 那一块的位置要等页面布局完才量得准, 所以浮层的位置在绘制时才算, 并记下来给点击和读屏用.
class _RenderPopover extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  late List<GlobalKey> anchor;
  _Pose? from;
  late bool toCard;
  late double t;
  late double gap;

  /// 从 0 (还是那一块) 到 1 (完整的浮层); 决定底色, 投影, 圆角和内容的不透明度.
  double get style => _style;
  double _style = 0;
  set style(double value) {
    if (value == _style) return;
    final fading = _fading;
    _style = value;
    if (_fading != fading) markNeedsCompositingBitsUpdate();
  }

  /// 内容的不透明度: 长到四分之一时开始淡入, 长到四分之三时完全显出; 收回时倒着播.
  double get _contentOpacity => ((_style - 0.25) / 0.5).clamp(0.0, 1.0);

  /// 内容正在淡入淡出, 要用一层 [OpacityLayer]. 完全显出或看不见时不加图层.
  bool get _fading => _contentOpacity > 0 && _contentOpacity < 1;

  /// 能不能点; 不能点时读屏也看不到里面的内容.
  bool get interactive => _interactive;
  bool _interactive = false;
  set interactive(bool value) {
    if (value == _interactive) return;
    _interactive = value;
    markNeedsSemanticsUpdate();
  }

  late Color color;
  late List<BoxShadow> shadows;

  /// 最近一次绘制时的样子, 换位置或收回时从这里接着走.
  _Pose? pose;

  /// 最近一次量到的那一块; 那一块已经不在屏幕上时 (如页面换了内容) 沿用.
  Rect? _anchorRect;

  final _clip = LayerHandle<ClipRRectLayer>();
  final _opacity = LayerHandle<OpacityLayer>();

  /// 浮层左右离屏幕边缘的最小距离.
  static const _margin = EatSpace.s20;

  @override
  bool get alwaysNeedsCompositing => child != null && _fading;

  @override
  void performLayout() {
    size = constraints.biggest;
    child?.layout(
      BoxConstraints(
        maxWidth: math.max(0, size.width - _margin * 2),
        maxHeight: size.height / 2,
      ),
      parentUsesSize: true,
    );
  }

  Rect? _measureAnchor() {
    for (final key in anchor) {
      final box = key.currentContext?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        final topLeft = globalToLocal(box.localToGlobal(Offset.zero));
        return _anchorRect = topLeft & box.size;
      }
    }
    return _anchorRect;
  }

  _Pose? _resolve() {
    final child = this.child;
    final anchor = _measureAnchor();
    if (child == null || anchor == null) return null;
    final content = child.size;
    final left = (anchor.center.dx - content.width / 2)
        .clamp(_margin, math.max(_margin, size.width - _margin - content.width))
        .toDouble();
    final card = Rect.fromLTWH(
      left,
      anchor.bottom + gap,
      content.width,
      content.height,
    );
    final start = from?.rect ?? anchor;
    final end = toCard ? card : anchor;
    return (rect: Rect.lerp(start, end, t)!, style: _style);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    final pose = this.pose = _resolve();
    if (child == null || pose == null || pose.style <= 0) {
      _clip.layer = null;
      _opacity.layer = null;
      return;
    }
    final (:rect, :style) = pose;
    final radius = Radius.circular(
      lerpDouble(rect.shortestSide / 2, EatRadius.tile.x, style)!,
    );
    final shape = RRect.fromRectAndRadius(rect, radius);
    final canvas = context.canvas;
    for (final shadow in shadows) {
      final faded = shadow.copyWith(
        color: shadow.color.withValues(alpha: shadow.color.a * style),
      );
      canvas.drawRRect(
        shape.shift(offset + shadow.offset).inflate(shadow.spreadRadius),
        faded.toPaint(),
      );
    }
    canvas.drawRRect(
      shape.shift(offset),
      Paint()..color = color.withValues(alpha: color.a * style),
    );
    final opacity = _contentOpacity;
    if (opacity == 0) {
      _clip.layer = null;
      _opacity.layer = null;
      return;
    }
    void paintContent(PaintingContext context, Offset offset) {
      if (!_fading) {
        _opacity.layer = null;
        context.paintChild(child, offset + rect.topLeft);
        return;
      }
      _opacity.layer = context.pushOpacity(
        offset,
        (opacity * 255).round(),
        (context, offset) => context.paintChild(child, offset + rect.topLeft),
        oldLayer: _opacity.layer,
      );
    }

    // 不需要合成时 pushClipRRect 只在画布上裁剪, 不加图层.
    _clip.layer = context.pushClipRRect(
      needsCompositing,
      offset,
      rect,
      shape,
      paintContent,
      oldLayer: _clip.layer,
    );
  }

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    final pose = this.pose;
    if (child == null || pose == null || !_interactive) return false;
    if (!pose.rect.contains(position)) return false;
    return result.addWithPaintOffset(
      offset: pose.rect.topLeft,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final origin = pose?.rect.topLeft ?? Offset.zero;
    transform.translateByDouble(origin.dx, origin.dy, 0, 1);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_interactive) super.visitChildrenForSemantics(visitor);
  }

  @override
  void dispose() {
    _clip.layer = null;
    _opacity.layer = null;
    super.dispose();
  }
}
