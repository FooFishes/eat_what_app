import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 能点的组件共用的外壳：点击和按下状态、键盘操作、焦点双环、鼠标手型和读屏语义。
///
/// 不画任何底色和水波纹，样子全由 [builder] 决定；`pressed` 用来做按钮的下沉。
/// [onTap] 为 null 时不可点，读屏报「不可用」。
class EatTappable extends StatefulWidget {
  const new({
    super.key,
    required this.onTap,
    required this.builder,
    this.focusShape = const StadiumBorder(),
    this.label,
    this.button = true,
    this.selected,
    this.checked,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    this.role,
  });

  final VoidCallback? onTap;

  final Widget Function(BuildContext context, bool pressed) builder;

  /// 焦点双环沿着画的轮廓，和组件本身的形状一致。
  final ShapeBorder focusShape;

  /// 读屏读的文字。不传时读子组件里的文字。
  final String? label;

  final bool button;
  final bool? selected;
  final bool? checked;
  final bool? toggled;
  final bool inMutuallyExclusiveGroup;
  final SemanticsRole? role;

  @override
  State<EatTappable> createState() => _EatTappableState();
}

class _EatTappableState extends State<EatTappable> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  void _activate() => widget.onTap?.call();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final colors = context.eat.colors;
    return MergeSemantics(
      child: Semantics(
        button: widget.button,
        enabled: enabled,
        label: widget.label,
        selected: widget.selected,
        checked: widget.checked,
        toggled: widget.toggled,
        inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
        role: widget.role,
        onTap: enabled ? _activate : null,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowFocusHighlight: (focused) => setState(() => _focused = focused),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => _activate(),
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: widget.onTap,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            child: CustomPaint(
              foregroundPainter: _focused
                  ? _FocusRingPainter(
                      widget.focusShape,
                      inner: colors.paper,
                      outer: colors.ink,
                    )
                  : null,
              child: widget.builder(context, _pressed && enabled),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter(this.shape, {required this.inner, required this.outer});

  final ShapeBorder shape;
  final Color inner;
  final Color outer;

  @override
  void paint(Canvas canvas, Size size) => paintFocusRing(
    canvas,
    Offset.zero & size,
    shape,
    inner: inner,
    outer: outer,
  );

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.inner != inner ||
      oldDelegate.outer != outer;
}
