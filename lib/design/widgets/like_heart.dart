import 'dart:math' as math;

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/widgets.dart';

/// 赞的心形. 赞上时弹一下, 同时向外散开一圈小点; 取消时轻轻缩一下换回空心.
///
/// 只负责图形, 点击和读屏由外层处理. 系统开启减少动态效果时直接换图标.
class LikeHeart extends StatefulWidget {
  const new({super.key, required this.liked, this.size = 20, this.color});

  final bool liked;
  final double size;

  /// 空心时的颜色, 默认跟着文字色. 实心一律用 `stage-tomato`.
  final Color? color;

  @override
  State<LikeHeart> createState() => _LikeHeartState();
}

class _LikeHeartState extends State<LikeHeart>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: EatMotion.pop.duration,
    value: 1,
  );

  /// 这次动画是赞上 (带散点) 还是取消.
  var _burst = false;

  /// 赞上: 先压到 0.8, 再放大到 1.3, 落回 1.
  static final _likeScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.8,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 15,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.8,
        end: 1.3,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.3,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 50,
    ),
  ]);

  /// 取消: 缩到 0.85 再回来.
  static final _unlikeScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 40),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.85,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 60,
    ),
  ]);

  @override
  void didUpdateWidget(LikeHeart old) {
    super.didUpdateWidget(old);
    if (old.liked == widget.liked) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _burst = widget.liked;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final red = StageColor.tomato.color;
    final color =
        widget.color ??
        DefaultTextStyle.of(context).style.color ??
        context.eat.colors.ink;
    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final scale = (_burst ? _likeScale : _unlikeScale).transform(t);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_burst && t < 1)
                Positioned(
                  left: -size,
                  top: -size,
                  width: size * 3,
                  height: size * 3,
                  child: CustomPaint(
                    painter: _BurstPainter(progress: t, color: red),
                  ),
                ),
              Transform.scale(
                scale: scale,
                child: EatIcon(
                  widget.liked ? EatIcons.heartOn : EatIcons.heart,
                  size: size,
                  color: widget.liked ? red : color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 赞上时心形周围的一圈: 先是一道散开变细的圆环, 接着六个小点向外飞出淡掉.
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const _dots = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.width / 3;

    // 圆环: 0.1–0.5 之间从心形大小散到 1.3 倍, 越来越细.
    final ring = ((progress - 0.1) / 0.4).clamp(0.0, 1.0);
    if (ring > 0 && ring < 1) {
      canvas.drawCircle(
        center,
        unit * (0.5 + 0.8 * Curves.easeOut.transform(ring)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * 0.2 * (1 - ring)
          ..color = color.withValues(alpha: 0.6 * (1 - ring)),
      );
    }

    // 小点: 0.3–0.9 之间从 0.7 倍飞到 1.4 倍, 逐渐变小淡掉.
    final fly = ((progress - 0.3) / 0.6).clamp(0.0, 1.0);
    if (fly > 0 && fly < 1) {
      final eased = Curves.easeOut.transform(fly);
      final paint = Paint()..color = color.withValues(alpha: 1 - fly);
      for (var i = 0; i < _dots; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / _dots;
        final distance = unit * (0.7 + 0.7 * eased);
        canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * distance,
          unit * 0.09 * (1 - fly * 0.6),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.progress != progress || old.color != color;
}
