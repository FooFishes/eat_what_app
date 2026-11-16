import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 可点击组件共用的交互外壳, 统一提供按下状态, 键盘激活, 焦点双环, 鼠标手型和读屏语义.
///
/// - 不绘制底色和水波纹, 外观完全由 [builder] 决定 (其中的 `pressed` 参数可用于实现下沉效果).
/// - 默认在按下时将内容不透明度降至 [pressedOpacity] 作为反馈;
///   若 [builder] 自行绘制按下效果 (如按钮), 可通过 [dimOnPress] 关闭.
/// - 当 [onTap] 为 null 时禁用点击, 且读屏将其报告为 "不可用".
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
    this.tapHint,
    this.dimOnPress = true,
  });

  final VoidCallback? onTap;

  final Widget Function(BuildContext context, bool pressed) builder;

  /// 焦点双环的轮廓形状, 应与组件自身轮廓保持一致.
  final ShapeBorder focusShape;

  /// 读屏朗读的标签文本, 未传入时朗读子组件中的文字.
  final String? label;

  final bool button;
  final bool? selected;
  final bool? checked;
  final bool? toggled;
  final bool inMutuallyExclusiveGroup;
  final SemanticsRole? role;

  /// 读屏朗读的点击动作提示 (如 "标为已读"), 未传入时使用平台默认的 "激活".
  final String? tapHint;

  /// 按下时是否降低内容不透明度; 当 [builder] 已根据 `pressed` 绘制按下效果时应传 false, 避免两种反馈叠加.
  final bool dimOnPress;

  /// 按下时内容的不透明度.
  static const pressedOpacity = 0.55;

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
        onTapHint: enabled ? widget.tapHint : null,
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
              child: widget.dimOnPress
                  ? AnimatedOpacity(
                      opacity: _pressed && enabled
                          ? EatTappable.pressedOpacity
                          : 1,
                      duration: context.motion(EatMotion.press),
                      child: widget.builder(context, _pressed && enabled),
                    )
                  : widget.builder(context, _pressed && enabled),
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
