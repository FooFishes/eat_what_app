import 'dart:math' as math;

import 'package:eat/design/theme/eat_colors.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 一排五颗星, 用来打分或展示分数. 实心的星用芒果黄记号笔色, 空的只描一圈边.
///
/// 能打分时 ([onChanged] 不为 null):
/// - 点第 n 颗选 n 分; 按住左右滑, 星星跟着手指亮起, 每经过一颗轻震一下, 松手时选中.
/// - 选中时亮起的星依次弹一下.
/// - 传了 [labels] 时下面一行写当前分数的说法 (如 "好吃"), 滑动时跟着变.
/// - 读屏里每颗星是一个按钮, 读 "4 分", 选中的那颗报告已选中.
///
/// 只展示时是一排小星, 不接点击.
class StarRating extends StatefulWidget {
  const new({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 40,
    this.labels,
  });

  /// 选中或要展示的分数, 1 到 5; null 表示没有.
  final int? value;

  /// 选了第几颗. 不传时只展示.
  final ValueChanged<int>? onChanged;

  /// 每颗星的边长. 能打分时每颗星的点击区域不小于 [EatSize.touch].
  final double size;

  /// 1 到 5 分各自的说法.
  final List<String>? labels;

  static const count = 5;

  /// 星星实心的颜色: 和分类栏, 分段条同一种芒果黄记号笔.
  static Color fillOf(EatColors colors) =>
      StageColor.mango.colorIn(dark: colors.isDark);

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating>
    with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: EatMotion.pop.duration,
    value: 1,
  );

  /// 手指滑过时临时亮到的分数.
  int? _hover;

  @override
  void didUpdateWidget(StarRating old) {
    super.didUpdateWidget(old);
    final value = widget.value;
    if (value != null &&
        value != old.value &&
        !MediaQuery.disableAnimationsOf(context)) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  double get _slot => math.max(widget.size + 8, EatSize.touch);

  int _at(double dx) => (dx / _slot).floor().clamp(0, StarRating.count - 1) + 1;

  void _hoverTo(double dx) {
    final next = _at(dx);
    if (next != _hover) {
      EatHaptics.selection();
      setState(() => _hover = next);
    }
  }

  void _commit() {
    final picked = _hover;
    setState(() => _hover = null);
    if (picked != null) widget.onChanged?.call(picked);
  }

  /// 第 [index] 颗星 (从 0 数) 此刻的缩放: 亮起的星从左到右依次弹一下.
  double _scaleOf(int index, int lit) {
    if (index >= lit) return 1;
    const stagger = 0.08;
    final local = ((_pop.value - index * stagger) / (1 - stagger * 4)).clamp(
      0.0,
      1.0,
    );
    if (local == 0 || local == 1) return 1;
    // 先放大到 1.25, 再回落.
    return 1 + 0.25 * math.sin(local * math.pi) * (1 - local * 0.3);
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final fill = StarRating.fillOf(c);
    final shown = _hover ?? widget.value ?? 0;
    final onChanged = widget.onChanged;
    final star = AnimatedBuilder(
      animation: _pop,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < StarRating.count; i++)
            _star(context, i, shown, fill, onChanged),
        ],
      ),
    );
    if (onChanged == null) {
      return ExcludeSemantics(child: star);
    }
    final labels = widget.labels;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: EatSpace.s4,
      children: [
        GestureDetector(
          onHorizontalDragStart: (d) => _hoverTo(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => _hoverTo(d.localPosition.dx),
          onHorizontalDragEnd: (_) => _commit(),
          onHorizontalDragCancel: () => setState(() => _hover = null),
          child: star,
        ),
        if (labels != null)
          ExcludeSemantics(
            child: SizedBox(
              height: 24,
              child: AnimatedSwitcher(
                duration: context.motion(EatMotion.select),
                child: Text(
                  shown == 0 ? '' : labels[shown - 1],
                  key: ValueKey(shown),
                  style: eat.text.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _star(
    BuildContext context,
    int index,
    int lit,
    Color fill,
    ValueChanged<int>? onChanged,
  ) {
    final c = context.eat.colors;
    final size = widget.size;
    final painted = Transform.scale(
      scale: _scaleOf(index, lit),
      child: CustomPaint(
        size: Size.square(size),
        painter: _StarPainter(
          filled: index < lit,
          fill: fill,
          outline: c.inkMuted,
        ),
      ),
    );
    if (onChanged == null) {
      return Padding(
        padding: EdgeInsets.only(right: index < StarRating.count - 1 ? 2 : 0),
        child: painted,
      );
    }
    final score = index + 1;
    return EatTappable(
      onTap: () => onChanged(score),
      label: '$score 分',
      selected: widget.value == score,
      focusShape: const CircleBorder(),
      dimOnPress: false,
      builder: (context, _) => SizedBox.square(
        dimension: _slot,
        child: Center(child: painted),
      ),
    );
  }
}

/// 一颗圆角五角星. 实心时填满 [fill]; 空心时只描一圈 [outline].
class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.filled,
    required this.fill,
    required this.outline,
  });

  final bool filled;
  final Color fill;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r * 1.06);
    final outer = r * 0.86;
    final inner = outer * 0.48;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    path.close();
    // 用同色的圆头描边把五个尖角磨圆.
    final round = r * 0.16;
    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = fill
          ..style = PaintingStyle.stroke
          ..strokeWidth = round
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, r * 0.1)
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.filled != filled || old.fill != fill || old.outline != outline;
}
