import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/painting.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:flutter/widgets.dart';

enum _Kind { choice, tag, add, district }

/// 36px 高的胶囊小标签。点击区域上下各扩 4px 到 44px，所以布局高度是 44：
/// 放进 `Wrap` 时 `spacing` 用 `space-8`、`runSpacing` 用 0，排出来和设计稿一样。
///
/// 不用舞台色上色，一个标签里不同时放图标、文字和计数。
class EatChip extends StatelessWidget {
  /// 单选分类（菜品分类、商圈）：选中 `ink` 底 `paper` 字，一组只能有一个选中。
  const new choice(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
  }) : _kind = _Kind.choice;

  /// 多选标签（口味标签）：选中 `tag-selected` 底加 `ink` 描边。
  const new tag(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
  }) : _kind = _Kind.tag;

  /// 补充入口：虚线描边，写「＋ 自己写」「＋ 加标签」。
  const new add(this.label, {super.key, required this.onTap})
    : selected = false,
      _kind = _Kind.add;

  /// 地图上的商圈：浮在地图上，未选中带 `shadow-float`。
  const new district(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
  }) : _kind = _Kind.district;

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final _Kind _kind;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final (style, foreground) = switch ((_kind, selected)) {
      (_Kind.choice, false) => (SurfaceStyle.flat(c.mist), c.ink),
      (_Kind.choice || _Kind.district, true) => (
        SurfaceStyle.flat(c.ink),
        c.paper,
      ),
      (_Kind.tag, false) => (
        SurfaceStyle.flat(c.paper, inset: [_border(c.handle)]),
        c.ink,
      ),
      (_Kind.tag, true) => (
        SurfaceStyle.flat(c.tagSelected, inset: [_border(c.ink)]),
        c.ink,
      ),
      (_Kind.district, false) => (
        SurfaceStyle(
          top: c.paper,
          bottom: c.paper,
          outer: eat.shadows.float.outer,
        ),
        c.ink,
      ),
      (_Kind.add, _) => (SurfaceStyle.dashed(c.lineStrong), c.ink),
    };
    final duration = context.motion(EatMotion.select);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: EatTappable(
        onTap: onTap,
        button: _kind == _Kind.add,
        checked: _kind == _Kind.choice ? selected : null,
        inMutuallyExclusiveGroup: _kind == _Kind.choice,
        toggled: _kind == _Kind.tag ? selected : null,
        selected: _kind == _Kind.district ? selected : null,
        builder: (context, _) => SizedBox(
          height: EatSize.touch,
          child: Center(
            widthFactor: 1,
            child: Surface(
              style: style,
              duration: duration,
              curve: EatMotion.select.curve,
              child: SizedBox(
                height: EatSize.chip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      label,
                      style: eat.text.body.copyWith(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: foreground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxShadow _border(Color color) => BoxShadow(spreadRadius: 1.5, color: color);

/// 「待接入」小标：跟在还没有接口的功能名后面，接口上线后去掉。
///
/// 只是标记，不可点；文字颜色跟着所在的文字，放在舞台上也看得清。
class PendingTag extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: CustomPaint(
        painter: _DashedPillPainter(eat.colors.lineStrong),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Text(
            '待接入',
            style: eat.text.caption.copyWith(
              fontSize: 11,
              height: 18 / 11,
              fontWeight: FontWeight.w500,
              color: DefaultTextStyle.of(context).style.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPillPainter extends CustomPainter {
  _DashedPillPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintDashedOutline(
    canvas,
    Offset.zero & size,
    const StadiumBorder(),
    color,
    1,
  );

  @override
  bool shouldRepaint(_DashedPillPainter oldDelegate) =>
      oldDelegate.color != color;
}
