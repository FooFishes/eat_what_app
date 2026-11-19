import 'dart:math' as math;

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_colors.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:flutter/widgets.dart';

enum _Look { pill, route, coins }

/// 横向分段条: 把一组有先后的选项排成一行, 点选或左右拖动选中其中一段.
///
/// 三种造型共用同一套操作:
/// - 点某一段直接选中.
/// - 按住左右拖, 选中的标记跟着手指走, 每经过一段轻震一下; 松手吸附到最近的一段再回调.
/// - 读屏把它当作可调节的滑块, 上下轻扫换一段.
/// - 系统开启减少动态效果时标记直接跳到位.
///
/// 造型:
/// - 默认: 胶囊轨道上压一块 `ink` 实心滑块, 滑块上是选中项的文字.
/// - [EatSegmentSlider.route]: 一条从 "我" 出发的路线, 每段是路上一站, 选中的那站是一个大圆点, 走过的路用记号笔涂实.
///   传了 [icons] 时圆点上方站着当前那段的图标 (如步行, 骑车, 开车), 换段时淡入淡出. 给距离用.
/// - [EatSegmentSlider.coins]: 每段一摞硬币, 越往右越多, 选中的那摞亮起来并微微跳起; [allIndex] 那段是三小摞, 选中时全部亮起, 表示 "都可以". 给价位用.
///
/// 后两种的强调色是白底页面的记号笔色 (芒果黄), 和分类栏的记号笔一致; 文字在下方, 选中项靠字重区分.
class EatSegmentSlider extends StatefulWidget {
  const new({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    required this.semanticsLabel,
  }) : _look = _Look.pill,
       allIndex = null,
       icons = null;

  const new route({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    required this.semanticsLabel,
    this.icons,
  }) : _look = _Look.route,
       allIndex = null;

  const new coins({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    required this.semanticsLabel,
    this.allIndex,
  }) : _look = _Look.coins,
       icons = null;

  /// 每一段的文字, 从左到右.
  final List<String> labels;

  /// 选中的序号.
  final int selected;

  /// 选中另一段时回调新的序号.
  final ValueChanged<int> onChanged;

  /// 读屏读出的名字, 如 "人均价位".
  final String semanticsLabel;

  /// 硬币造型里表示 "不限" 的那一段的序号.
  final int? allIndex;

  /// 路线造型里每一段的图标, 和 [labels] 一一对应, 站在指示器上方.
  final List<EatIcons>? icons;

  final _Look _look;

  /// 胶囊造型的高度, 同时是点击区域的高度.
  static const height = EatSize.touch;

  /// 路线和硬币造型的高度: 上面画图, 下面一行字.
  static const tallHeight = 76.0;

  /// 滑块和轨道边缘之间的空隙.
  static const _inset = 3.0;

  @override
  State<EatSegmentSlider> createState() => _EatSegmentSliderState();
}

class _EatSegmentSliderState extends State<EatSegmentSlider>
    with SingleTickerProviderStateMixin {
  /// 标记所在的位置, 以段为单位: 0 是第一段的中心, `labels.length - 1` 是最后一段.
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.selected.toDouble(),
  );

  var _dragging = false;

  int get _last => widget.labels.length - 1;

  int get _nearest => _position.value.round().clamp(0, _last);

  @override
  void didUpdateWidget(EatSegmentSlider old) {
    super.didUpdateWidget(old);
    if (!_dragging && widget.selected != _nearest) _slideTo(widget.selected);
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _slideTo(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = index.toDouble();
      return;
    }
    // 路线和硬币用转盘同款的回弹, 指示器和硬币落位时略微越过再回来.
    final motion = widget._look == _Look.pill
        ? EatMotion.select
        : EatMotion.snap;
    _position.animateTo(
      index.toDouble(),
      duration: motion.duration,
      curve: motion.curve,
    );
  }

  /// 把手指的横坐标换算成标记的位置.
  double _at(double dx, double segment) =>
      (dx / segment - 0.5).clamp(0, _last.toDouble());

  void _pick(int index) {
    _slideTo(index);
    if (index != widget.selected) {
      EatHaptics.selection();
      widget.onChanged(index);
    }
  }

  void _dragTo(double dx, double segment) {
    final before = _nearest;
    _position.value = _at(dx, segment);
    if (_nearest != before) EatHaptics.selection();
  }

  void _step(int delta) {
    final next = (widget.selected + delta).clamp(0, _last);
    if (next != widget.selected) _pick(next);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final index = widget.selected;
    return Semantics(
      slider: true,
      label: widget.semanticsLabel,
      value: labels[index],
      increasedValue: index < _last ? labels[index + 1] : null,
      decreasedValue: index > 0 ? labels[index - 1] : null,
      onIncrease: index < _last ? () => _step(1) : null,
      onDecrease: index > 0 ? () => _step(-1) : null,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segment = constraints.maxWidth / labels.length;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _pick(_at(d.localPosition.dx, segment).round()),
              onHorizontalDragStart: (d) {
                _dragging = true;
                _position.stop();
                _dragTo(d.localPosition.dx, segment);
              },
              onHorizontalDragUpdate: (d) =>
                  _dragTo(d.localPosition.dx, segment),
              onHorizontalDragEnd: (_) {
                _dragging = false;
                _pick(_nearest);
              },
              onHorizontalDragCancel: () {
                _dragging = false;
                _slideTo(widget.selected);
              },
              child: AnimatedBuilder(
                animation: _position,
                builder: (context, _) => switch (widget._look) {
                  _Look.pill => _pill(context, segment),
                  _Look.route || _Look.coins => _drawn(context, segment),
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, double segment) {
    final eat = context.eat;
    final c = eat.colors;
    return SizedBox(
      height: EatSegmentSlider.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.paper,
          borderRadius: const BorderRadius.all(EatRadius.pill),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                for (final label in widget.labels)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        maxLines: 1,
                        style: eat.text.meta.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              left: _position.value * segment + EatSegmentSlider._inset,
              top: EatSegmentSlider._inset,
              bottom: EatSegmentSlider._inset,
              width: segment - EatSegmentSlider._inset * 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.ink,
                  borderRadius: const BorderRadius.all(EatRadius.pill),
                ),
                child: Center(
                  child: Text(
                    widget.labels[_nearest],
                    maxLines: 1,
                    style: eat.text.meta.copyWith(
                      color: c.paper,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 路线和硬币: 上面是画出来的图, 下面一行字, 选中的字加粗.
  Widget _drawn(BuildContext context, double segment) {
    final eat = context.eat;
    final c = eat.colors;
    final marker = StageColor.mango
        .colorIn(dark: c.isDark)
        .withValues(alpha: c.isDark ? 0.55 : 0.85);
    final painter = switch (widget._look) {
      _Look.route => _RoutePainter(
        position: _position.value,
        count: widget.labels.length,
        colors: c,
        marker: marker,
      ),
      _ => _CoinsPainter(
        position: _position.value,
        count: widget.labels.length,
        allIndex: widget.allIndex,
        colors: c,
        marker: marker,
      ),
    };
    return SizedBox(
      height: EatSegmentSlider.tallHeight,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: painter)),
                if (widget.icons case final icons?)
                  Positioned(
                    left:
                        (_position.value + 0.5) * segment -
                        _RoutePainter.iconSize / 2,
                    top: _RoutePainter.iconTop,
                    width: _RoutePainter.iconSize,
                    height: _RoutePainter.iconSize,
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : EatMotion.select.duration,
                      child: EatIcon(
                        icons[_nearest],
                        key: ValueKey(icons[_nearest]),
                        size: _RoutePainter.iconSize,
                        color: c.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 24,
            child: Row(
              children: [
                for (final (i, label) in widget.labels.indexed)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        maxLines: 1,
                        style: eat.text.meta.copyWith(
                          color: i == _nearest ? c.ink : c.inkMuted,
                          fontWeight: i == _nearest
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 距离的路线: 左端是 "我", 一条虚线往右走, 每段是一站; 选中的站上一个大圆点当指示器, 走过的路用记号笔涂实.
class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.position,
    required this.count,
    required this.colors,
    required this.marker,
  });

  final double position;
  final int count;
  final EatColors colors;
  final Color marker;

  /// 图画区的高度, 即造型总高减去下面一行字.
  static const _height = EatSegmentSlider.tallHeight - 24;

  /// 路离图画区底边的距离.
  static const _lineFromBottom = 10.0;

  /// 站在指示器上方的图标的大小和上沿位置; 图标底边离路 12px, 让出指示器.
  static const iconSize = 24.0;
  static const iconTop = _height - _lineFromBottom - 12 - iconSize;

  @override
  void paint(Canvas canvas, Size size) {
    final segment = size.width / count;
    final lineY = size.height - _lineFromBottom;
    final meX = 7.0;
    double stopX(double i) => (i + 0.5) * segment;
    final pinX = stopX(position);
    final endX = stopX(count - 1.0);

    // 前面还没走的路: 浅色虚线.
    final dash = Paint()
      ..color = colors.handle
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = pinX; x < endX; x += 8) {
      canvas.drawLine(
        Offset(x, lineY),
        Offset(math.min(x + 3, endX), lineY),
        dash,
      );
    }

    // 走过的路: 一道记号笔, 中间一条实线.
    canvas
      ..drawLine(
        Offset(meX, lineY),
        Offset(pinX, lineY),
        Paint()
          ..color = marker
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        Offset(meX, lineY),
        Offset(pinX, lineY),
        Paint()
          ..color = colors.ink
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

    // 各站.
    for (var i = 0; i < count; i++) {
      final x = stopX(i.toDouble());
      final passed = x <= pinX + 0.5;
      canvas.drawCircle(
        Offset(x, lineY),
        3.5,
        Paint()..color = passed ? colors.ink : colors.paper,
      );
      if (!passed) {
        canvas.drawCircle(
          Offset(x, lineY),
          3.5,
          Paint()
            ..color = colors.handle
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // "我": 实心圆点套一圈.
    canvas
      ..drawCircle(Offset(meX, lineY), 6, Paint()..color = colors.ink)
      ..drawCircle(Offset(meX, lineY), 2.5, Paint()..color = colors.paper);

    // 指示器: 选中的站上一个大圆点, 外圈一道底色把它和路分开.
    canvas
      ..drawCircle(Offset(pinX, lineY), 9, Paint()..color = colors.paper)
      ..drawCircle(Offset(pinX, lineY), 7, Paint()..color = colors.ink)
      ..drawCircle(Offset(pinX, lineY), 3, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.position != position ||
      old.count != count ||
      old.colors != colors ||
      old.marker != marker;
}

/// 价位的硬币: 每段一摞硬币, 越往右越多; 离标记越近的那摞越亮, 并微微跳起.
/// "不限" 那段是一枚, 两枚, 三枚三小摞, 选中时全部亮起.
class _CoinsPainter extends CustomPainter {
  _CoinsPainter({
    required this.position,
    required this.count,
    required this.allIndex,
    required this.colors,
    required this.marker,
  });

  final double position;
  final int count;
  final int? allIndex;
  final EatColors colors;
  final Color marker;

  /// 一枚硬币的厚度和相邻两枚的间距.
  static const _thick = 8.0;
  static const _pitch = 10.0;

  /// 亮起时往上跳多高.
  static const _hop = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final segment = size.width / count;
    final baseY = size.height - 6;
    final width = math.min(segment * 0.4, 28.0);

    /// 标记离 [i] 越近越亮, 1 是正好落在上面.
    double near(int i) => (1 - (position - i).abs()).clamp(0, 1);
    final all = allIndex == null ? 0.0 : near(allIndex!);

    /// 以 [x] 为中心, 从底往上叠 [coins] 枚宽 [w] 的硬币.
    void pile(double x, double w, int coins, double lit) {
      final face = Color.lerp(colors.mist, marker, lit)!;
      // 厚度边一律往暗里调; 深色模式下 ink 是浅色, 不能拿来压暗.
      final edge = Color.lerp(
        face,
        const Color(0xFF000000),
        colors.isDark ? 0.35 : 0.15,
      )!;
      final lift = _hop * lit;
      for (var j = 0; j < coins; j++) {
        final top = baseY - lift - _thick - j * _pitch;
        final rect = Rect.fromLTWH(x - w / 2, top, w, _thick);
        const radius = Radius.circular(_thick / 2);
        canvas
          ..drawRRect(
            RRect.fromRectAndRadius(rect.shift(const Offset(0, 2)), radius),
            Paint()..color = edge,
          )
          ..drawRRect(
            RRect.fromRectAndRadius(rect, radius),
            Paint()..color = face,
          );
      }
    }

    var rank = 0;
    for (var i = 0; i < count; i++) {
      final x = (i + 0.5) * segment;
      if (i == allIndex) {
        final w = width * 0.48;
        for (var k = 0; k < 3; k++) {
          pile(x + (k - 1) * w * 1.25, w, k + 1, all);
        }
        continue;
      }
      rank++;
      pile(x, width, rank, math.max(near(i), all));
    }
  }

  @override
  bool shouldRepaint(_CoinsPainter old) =>
      old.position != position ||
      old.count != count ||
      old.allIndex != allIndex ||
      old.colors != colors ||
      old.marker != marker;
}
