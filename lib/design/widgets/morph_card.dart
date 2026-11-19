import 'dart:math' as math;

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:flutter/widgets.dart';

/// 从页面上的一格 ([origin]) 展开成一张浮在 `scrim` 上的卡片, 关闭时再收回那一格.
///
/// 展开时位置, 大小, 圆角和底色 (从 [from] 到 `paper`) 一起过渡; 格子原来的样子 ([face]) 先淡出,
/// 卡片内容 ([builder]) 随后淡入, 看起来是那一格自己长大成卡片. 点卡片外面或系统返回关闭.
///
/// 卡片宽度和页面内容一样 (左右 `space-20`, 宽屏最宽 480), 高 [height], 尽量贴着那一格出现,
/// 放不下时往屏幕中间挪. [fullscreen] 时铺满整个屏幕, 圆角收成直角, [height] 不用.
/// [fromRadius] 是那一格自己的圆角. 系统开启减少动态效果时直接出现和消失.
Future<T?> showMorphCard<T>(
  BuildContext context, {
  required GlobalKey origin,
  required Color from,
  required WidgetBuilder face,
  required WidgetBuilder builder,
  double height = 0,
  Radius fromRadius = EatRadius.tile,
  bool fullscreen = false,
  String? barrierLabel,
}) {
  final box = origin.currentContext?.findRenderObject() as RenderBox?;
  final rect = box == null || !box.hasSize
      ? null
      : box.localToGlobal(Offset.zero) & box.size;
  return Navigator.of(context).push(
    _MorphRoute<T>(
      origin: rect,
      from: from,
      height: height,
      fromRadius: fromRadius,
      fullscreen: fullscreen,
      face: face,
      builder: builder,
      duration: context.motion(EatMotion.morph),
      barrierColor: context.eat.colors.scrim,
      barrierLabel: barrierLabel,
    ),
  );
}

class _MorphRoute<T> extends PopupRoute<T> {
  _MorphRoute({
    required this.origin,
    required this.from,
    required this.height,
    required this.fromRadius,
    required this.fullscreen,
    required this.face,
    required this.builder,
    required this.duration,
    required this.barrierColor,
    this.barrierLabel,
  });

  /// 那一格在屏幕上的位置. 量不到时卡片从自己的位置淡入.
  final Rect? origin;
  final Color from;
  final double height;
  final Radius fromRadius;
  final bool fullscreen;
  final WidgetBuilder face;
  final WidgetBuilder builder;
  final Duration duration;

  @override
  final Color barrierColor;

  @override
  final String? barrierLabel;

  @override
  bool get barrierDismissible => !fullscreen;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _MorphBody(route: this, animation: animation);
}

class _MorphBody extends StatefulWidget {
  const new({required this.route, required this.animation});

  final _MorphRoute<dynamic> route;
  final Animation<double> animation;

  @override
  State<_MorphBody> createState() => _MorphBodyState();
}

class _MorphBodyState extends State<_MorphBody> {
  late final _curved = CurvedAnimation(
    parent: widget.animation,
    curve: EatMotion.morph.curve,
    reverseCurve: EatMotion.morph.curve.flipped,
  );

  /// 卡片离屏幕上下边缘至少留的距离.
  static const _edge = EatSpace.s24;

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final curved = _curved;
    final c = context.eat.colors;
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final width = math.min(screen.width - EatSpace.s20 * 2, 480.0);
    final left = (screen.width - width) / 2;
    final origin = route.origin;
    final maxTop =
        screen.height - keyboard - padding.bottom - _edge - route.height;
    final top =
        (origin == null
                ? (screen.height - route.height) / 2
                : origin.top - EatSpace.s16)
            .clamp(padding.top + _edge, math.max(padding.top + _edge, maxTop))
            .toDouble();
    final target = route.fullscreen
        ? Offset.zero & screen
        : Rect.fromLTWH(left, top, width, route.height);
    final toRadius = route.fullscreen ? Radius.zero : EatRadius.tile;
    final content = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: route.barrierLabel,
      child: SizedBox.fromSize(
        size: target.size,
        child: route.builder(context),
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        final start = origin ?? target.deflate(EatSpace.s16);
        final rect = Rect.lerp(start, target, t)!;
        // 格子的样子在前 30% 淡出, 卡片内容在 25%–75% 之间淡入; 收回时倒着播.
        final faceOpacity = origin == null
            ? 0.0
            : (1 - t / 0.3).clamp(0.0, 1.0);
        final contentOpacity = ((t - 0.25) / 0.5).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fromRect(
              rect: rect,
              child: ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.lerp(route.fromRadius, toRadius, t)!,
                ),
                child: ColoredBox(
                  color: Color.lerp(route.from, c.paper, t)!,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      if (origin != null && faceOpacity > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          width: origin.width,
                          height: origin.height,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: faceOpacity,
                              child: route.face(context),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        top: 0,
                        width: target.width,
                        height: target.height,
                        child: Opacity(
                          opacity: contentOpacity,
                          child: IgnorePointer(
                            ignoring: t < 0.6,
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
