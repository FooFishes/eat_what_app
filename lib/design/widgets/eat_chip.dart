import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/painting.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:flutter/widgets.dart';

enum _Kind { choice, tag, add, district }

/// 胶囊小标签.
///
/// 点击区域上下扩展到 [EatSize.touch], 布局高度因此等于点击区域的高度.
/// 宽度不小于 [EatSize.touch], 单字标签的点击区域也满足下限.
/// 放入 `Wrap` 时 `spacing` 用 `space-8`, `runSpacing` 用 0, 行距由扩展出的点击区域提供.
///
/// - 不使用舞台色着色.
/// - 一个标签内不同时放图标, 文字和计数.
class EatChip extends StatelessWidget {
  /// 单选分类, 如菜品分类和商圈. 选中时为 `ink` 底 `paper` 字, 一组只有一个选中项.
  const new choice(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
  }) : _kind = _Kind.choice;

  /// 多选标签, 如口味标签. 选中时为 `tag-selected` 底加 `ink` 描边.
  const new tag(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
  }) : _kind = _Kind.tag;

  /// 补充入口. 虚线描边, 文字如 "+ 自己写" "+ 加标签".
  const new add(this.label, {super.key, required this.onTap})
    : selected = false,
      _kind = _Kind.add;

  /// 地图上的商圈. 浮于地图之上, 未选中时带 `shadow-float`.
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: EatSize.touch),
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
      ),
    );
  }
}

BoxShadow _border(Color color) => BoxShadow(spreadRadius: 1.5, color: color);

/// "待接入" 标记. 放在未对接接口的功能名后, 接口上线后移除.
///
/// 仅作标记, 不可点击. 文字颜色继承所在文字, 因此在舞台上同样清晰.
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
