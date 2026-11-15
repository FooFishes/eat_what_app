import 'dart:math' as math;

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:flutter/widgets.dart';

/// 转盘上的一道菜: 封面和圆形取景.
class const TurntableItem({
  required final ImageProvider? image,
  final double centerX = 0.5,
  final double centerY = 0.5,
  final double diameter = 1,
});

/// 发现页舞台中的转盘. 几道菜排列在一张大圆桌的边缘, 拖动或点击 "换一个" 转到下一道.
///
/// 布局:
/// - 手机上圆心位于当前菜品正下方, 屏幕上只显示当前菜品. 上一道菜转向左下角的过程中淡出.
/// - 宽屏时圆心位于屏幕右侧之外, 菜品沿右边缘纵向转动, 下一道从右上角露出.
/// - 离开正位的菜品缩小显示, 照片始终保持正向.
///
/// 交互:
/// - 拖动时转盘跟随手指. 松手时拖过的角度超过阈值即换一道, 每次只转一格.
/// - 松手后以回弹曲线吸附到目标位置.
/// - 手机上只响应横向拖动, 宽屏只响应纵向拖动, 另一方向交给页面滚动.
/// - 拖动的替代操作是页面上的 "换一个" 按钮.
///
/// 状态:
/// - [items] 是向后增长的队列, [index] 是当前菜品.
/// - 转到其他位置时通过 [onIndexChanged] 通知页面, 页面更新 [index] 后传回.
/// - [spinning] 为 false 时不绘制转盘, 只显示当前菜品, 仍可拖动换菜.
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

  /// 当前菜品盘子的直径, 即盘沿内照片的直径.
  final double plateSize;

  /// 当前菜品盘子的圆心, 以本组件的坐标表示.
  final Offset plateCenter;

  final bool wide;
  final bool spinning;

  /// 相邻两道菜之间的角度.
  static const step = 55.0;

  @override
  State<Turntable> createState() => _TurntableState();
}

class _TurntableState extends State<Turntable>
    with SingleTickerProviderStateMixin {
  /// 当前转到的位置, 可带小数. 动画在两道菜之间插值.
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.index.toDouble(),
  );

  /// 手指拖动产生的角度, 松手后归零.
  double _drag = 0;

  double get _radius =>
      EatSize.turntableRadius * widget.plateSize / EatSize.plate;

  /// 每拖动 1px 转过的角度. 半径为 R 时, 1° 对应的弧长为 πR/180.
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
    // 把松手时的角度并入位置, 再从该位置吸附到目标, 避免先跳回原位.
    _position.value -= drag / Turntable.step;
    setState(() => _drag = 0);
    if (next == widget.index) {
      _animateTo(next);
    } else {
      EatHaptics.selection();
      widget.onIndexChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = StageTheme.of(context);
    final plate = widget.plateSize;
    final radius = _radius;
    // 手机上菜品朝向正上方, 宽屏时朝向左侧.
    final base = widget.wide ? -math.pi / 2 : 0.0;
    final center = widget.wide
        ? widget.plateCenter + Offset(radius, 0)
        : widget.plateCenter + Offset(0, radius);
    final tableRadius = radius + plate * 170 / EatSize.plate;
    final ringRadius = radius + plate * 130 / EatSize.plate;

    final table = ExcludeSemantics(
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
    return GestureDetector(
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
    // 手机上转过的菜停在舞台左下角, 与价格, 批次圆点和 "换一个" 按钮重叠.
    // 因此向左转动时不透明度随角度降低, 转过 0.8 格后为 0. 向右转回时恢复.
    // 宽屏上转过的菜位于右下角, 不与文字重叠, 不做此处理.
    final turned = degrees / Turntable.step;
    final opacity = !widget.wide && turned < 0
        ? (1 + turned * 1.25).clamp(0.0, 1.0)
        : (visible + 0.4 - offset.abs()).clamp(0.0, 1.0);
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

/// 舞台左栏下方的一排小圆点, 表示当前菜品在本批中的位置. 当前圆点拉长显示.
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
