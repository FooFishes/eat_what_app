import 'dart:math' as math;

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:flutter/widgets.dart';

/// 转盘上的一道菜：封面和圆形取景。
class const TurntableItem({
  required final ImageProvider? image,
  final double centerX = 0.5,
  final double centerY = 0.5,
  final double diameter = 1,
});

/// 发现页舞台里的转盘：几道菜摆在一张大圆桌的边上，拖动或点「换一个」转到下一道。
///
/// 手机上圆心在当前这道菜正下方 430px（按舞台高度缩放），相邻两道隔 55°，屏幕上只看到当前这道和
/// 左下角露出的上一道；宽屏时圆心在屏幕右侧外面，菜沿右边缘上下转，下一道从右上角露出来。
/// 拖动跟手，每 7.5px 转 1°，拖过约 4° 松手就换一道，一次只转一格；吸附 680ms 带回弹。
/// 离开正位的菜缩到 0.85 倍，照片保持正向。
///
/// [items] 是一条往后增长的队列，[index] 是当前那道；转到 [index] 以外由 [onIndexChanged] 告诉页面，
/// 页面改了 [index] 再传回来。[spinning] 为 false 时（能推荐的菜少于 5 道）不画转盘，只放当前这道。
/// 只认横向拖动（宽屏是纵向），另一个方向交给页面滚动；拖动的替代操作是页面上的「换一个」。
class Turntable extends StatefulWidget {
  const new({
    super.key,
    required this.items,
    required this.index,
    required this.onIndexChanged,
    required this.plateSize,
    required this.plateCenter,
    this.wide = false,
    this.spinning = true,
  });

  final List<TurntableItem> items;
  final int index;
  final ValueChanged<int> onIndexChanged;

  /// 当前这道菜盘子的直径（含盘沿内的照片）。
  final double plateSize;

  /// 当前这道菜盘子的圆心，在这个组件里的坐标。
  final Offset plateCenter;

  final bool wide;
  final bool spinning;

  /// 相邻两道之间的角度。
  static const step = 55.0;

  @override
  State<Turntable> createState() => _TurntableState();
}

class _TurntableState extends State<Turntable>
    with SingleTickerProviderStateMixin {
  /// 当前转到的位置，带小数：动画在两道之间插值。
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.index.toDouble(),
  );

  /// 手指拖出来的角度，松手后归零。
  double _drag = 0;

  double get _radius =>
      EatSize.turntableRadius * widget.plateSize / EatSize.plate;

  /// 每拖 1px 转多少度：弧长 πR/180 对应 1°。
  double get _degreesPerPixel => 180 / (math.pi * _radius);

  @override
  void didUpdateWidget(Turntable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _animateTo(widget.index);
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    final target = index.toDouble();
    final duration = context.motion(EatMotion.snap);
    if (duration == Duration.zero) {
      _position.value = target;
    } else {
      _position.animateTo(
        target,
        duration: duration,
        curve: EatMotion.snap.curve,
      );
    }
  }

  void _onUpdate(double delta) {
    setState(() {
      _drag = (_drag + delta * _degreesPerPixel).clamp(
        -Turntable.step * 1.1,
        Turntable.step * 1.1,
      );
    });
  }

  void _onEnd() {
    final drag = _drag;
    var next = widget.index;
    if (drag < -4 && widget.index + 1 < widget.items.length) next++;
    if (drag > 4 && widget.index > 0) next--;
    // 把松手时的角度折进位置里，再从那里吸附过去，不会先跳回原位。
    _position.value -= drag / Turntable.step;
    setState(() => _drag = 0);
    if (next == widget.index) {
      _animateTo(next);
    } else {
      widget.onIndexChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = StageTheme.of(context);
    final plate = widget.plateSize;
    final radius = _radius;
    // 手机上菜指向正上方，宽屏时指向左边。
    final base = widget.wide ? -math.pi / 2 : 0.0;
    final center = widget.wide
        ? widget.plateCenter + Offset(radius, 0)
        : widget.plateCenter + Offset(0, radius);
    final tableRadius = radius + plate * 170 / EatSize.plate;
    final ringRadius = radius + plate * 130 / EatSize.plate;

    Widget table = ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _position,
        builder: (context, _) => Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (widget.spinning) ...[
              _circle(center, tableRadius, color: palette.table),
              _circle(center, ringRadius, border: palette.tableRing),
            ],
            for (var i = 0; i < widget.items.length; i++)
              ?_plate(i, center: center, radius: radius, base: base),
          ],
        ),
      ),
    );
    if (widget.spinning) {
      table = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: widget.wide
            ? null
            : (details) => _onUpdate(details.delta.dx),
        onHorizontalDragEnd: widget.wide ? null : (_) => _onEnd(),
        onHorizontalDragCancel: widget.wide ? null : _onEnd,
        onVerticalDragUpdate: widget.wide
            ? (details) => _onUpdate(-details.delta.dy)
            : null,
        onVerticalDragEnd: widget.wide ? (_) => _onEnd() : null,
        onVerticalDragCancel: widget.wide ? _onEnd : null,
        child: table,
      );
    }
    return table;
  }

  Widget? _plate(
    int i, {
    required Offset center,
    required double radius,
    required double base,
  }) {
    final offset = i - _position.value;
    final visible = widget.spinning ? 1.6 : 0.6;
    if (offset.abs() >= visible + 0.4) return null;
    final degrees = offset * Turntable.step + _drag;
    final away = math.min(1.0, degrees.abs() / Turntable.step);
    final angle = base + degrees * math.pi / 180;
    final position =
        center + Offset(math.sin(angle) * radius, -math.cos(angle) * radius);
    final size = widget.plateSize * (1 - 0.15 * away);
    final opacity = (visible + 0.4 - offset.abs()).clamp(0.0, 1.0);
    final item = widget.items[i];
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: Opacity(
        opacity: widget.spinning ? opacity : (1 - offset.abs()).clamp(0.0, 1.0),
        child: DishPlate(
          image: item.image,
          size: size,
          centerX: item.centerX,
          centerY: item.centerY,
          diameter: item.diameter,
        ),
      ),
    );
  }

  static Widget _circle(
    Offset center,
    double radius, {
    Color? color,
    Color? border,
  }) => Positioned(
    left: center.dx - radius,
    top: center.dy - radius,
    child: Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border, width: 1.5),
      ),
    ),
  );
}

/// 舞台左栏下面的一排小圆点：这道菜在这一批里排第几，当前那个拉长成 16px。
class TurntableDots extends StatelessWidget {
  const new({super.key, required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color!;
    final duration = context.motion(EatMotion.select);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: duration,
              width: i == current ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: i == current ? 1 : 0.4),
                borderRadius: const BorderRadius.all(Radius.circular(3)),
              ),
            ),
        ],
      ),
    );
  }
}
