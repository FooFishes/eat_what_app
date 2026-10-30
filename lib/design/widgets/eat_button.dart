import 'dart:math' as math;

import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_shadows.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show CircularProgressIndicator;

enum _Kind { solid, outline, mist, dashed, stageSolid, stageGhost }

/// 带一点厚度的胶囊按钮。文字写清楚按下会发生什么（「就它了」「导航去店里」），不写「确定」。
///
/// 白底上：主操作 [EatButton.solid]，一屏最多一个；并排的次操作用 [EatButton.outline] 或
/// [EatButton.mist]；「新建」「自己写」这类补充入口用 [EatButton.dashed]。舞台上用
/// [EatButton.stageSolid] 和 [EatButton.stageGhost]，颜色跟着所在的舞台走。
///
/// [onPressed] 为 null 时不可用：变成扁平的灰底，附近要用 `warn` 文字说明怎样才能用。
/// 条件还没满足、但点了要告诉用户差什么时（没勾协议就点登录）设 [muted]：样子和不可用一样，
/// 点了照样调 [onPressed]，由页面给出提示；条件满足后去掉 [muted]，灰底平滑过渡成正常的样子。
/// 提交等着网络时设 [loading]：样子不变灰，文字换成转圈，不能再点；读屏报「按钮名，进行中」。
/// 宽度默认贴着内容；放进 `Expanded` 或给定宽度时撑满，成对出现时左次右主、等宽、隔 `space-10`。
class EatButton extends StatelessWidget {
  const new solid(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.height = EatSize.button,
    this.loading = false,
    this.muted = false,
  }) : _kind = _Kind.solid;

  const new outline(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.height = EatSize.button,
    this.loading = false,
    this.muted = false,
  }) : _kind = _Kind.outline;

  const new mist(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.height = EatSize.button,
    this.loading = false,
    this.muted = false,
  }) : _kind = _Kind.mist;

  const new dashed(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.height = EatSize.button,
    this.loading = false,
    this.muted = false,
  }) : _kind = _Kind.dashed;

  /// 舞台上的主操作：浅色舞台是 `ink` 底、舞台色字；深色舞台是白色渐变底、舞台色字。
  const new stageSolid(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.height = EatSize.button,
    this.loading = false,
    this.muted = false,
  }) : _kind = _Kind.stageSolid;

  /// 舞台上的次操作：半透明的磨砂底，文字是舞台文字色。
  const new stageGhost(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.height = EatSize.button,
    this.loading = false,
    this.muted = false,
  }) : _kind = _Kind.stageGhost;

  final String label;
  final VoidCallback? onPressed;

  /// 放在文字左边。
  final EatIcons? icon;

  /// 主按钮 52；列表行里的小按钮（回关、关注）36，点击区域会自动扩到 44。
  final double height;

  /// 正在处理这次点击，比如等登录接口返回。
  final bool loading;

  /// 看起来不可用，点了仍然响应。
  final bool muted;

  final _Kind _kind;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final stage = switch (_kind) {
      _Kind.stageSolid || _Kind.stageGhost => StageTheme.of(context),
      _ => null,
    };
    final compact = height < EatSize.touch;
    final fontSize = height >= 50
        ? 16.0
        : compact
        ? 14.0
        : 15.0;
    return EatTappable(
      onTap: loading ? null : onPressed,
      label: loading ? '$label，进行中' : null,
      builder: (context, pressed) {
        final look = _look(eat, stage, pressed: pressed);
        final sinks =
            onPressed != null && !loading && !muted && _kind != _Kind.dashed;
        final duration = context.motion(EatMotion.press);
        // 按下用 90ms；松开、在可用和不可用之间切换时用选中态的 180ms，颜色不是一下跳过去。
        final styleDuration = pressed
            ? duration
            : context.motion(EatMotion.select);
        final content = TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: look.foreground),
          duration: styleDuration,
          curve: EatMotion.select.curve,
          builder: (context, foreground, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon case final icon?) ...[
                EatIcon(icon, size: compact ? 16 : 18, color: foreground),
                const SizedBox(width: EatSpace.s8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.buttonLabel.copyWith(
                    fontSize: fontSize,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        );
        // 转圈叠在原来的文字上，文字只是隐去，按钮宽度不跟着变。
        final body = loading
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: 0, child: content),
                  SizedBox.square(
                    dimension: compact ? 16 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: look.foreground,
                      value: MediaQuery.disableAnimationsOf(context)
                          ? 0.75
                          : null,
                    ),
                  ),
                ],
              )
            : content;
        // 贴着内容的按钮两侧留 22px（小按钮 14px）；被撑满时（Expanded、给定宽度）文字居中，
        // 两侧只留 6px，否则三个并排的按钮会把「新建一家店」省略成「新建…」。
        final button = AnimatedContainer(
          duration: duration,
          curve: EatMotion.press.curve,
          transform: Matrix4.translationValues(
            0,
            sinks && pressed ? EatMotion.pressOffset : 0,
            0,
          ),
          child: Surface(
            style: look.style,
            duration: styleDuration,
            curve: EatMotion.press.curve,
            child: SizedBox(
              height: height,
              child: _SidePadding(
                loose: compact ? 14 : 22,
                tight: 6,
                child: Center(widthFactor: 1, child: body),
              ),
            ),
          ),
        );
        if (!compact) return button;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: (EatSize.touch - height) / 2),
          child: button,
        );
      },
    );
  }

  ({SurfaceStyle style, Color foreground}) _look(
    EatTheme eat,
    StagePalette? stage, {
    required bool pressed,
  }) {
    final c = eat.colors;
    final s = eat.shadows;
    if (onPressed == null || muted) {
      return _kind == _Kind.dashed
          ? (style: SurfaceStyle.dashed(c.lineStrong), foreground: c.disabledFg)
          : (style: SurfaceStyle.flat(c.disabledBg), foreground: c.disabledFg);
    }
    switch (_kind) {
      case _Kind.solid:
        return (
          style: _raised(c.inkTop, c.ink, pressed ? s.buttonPressed : s.button),
          foreground: c.paper,
        );
      case _Kind.outline:
        return (
          style: _raised(
            c.paper,
            c.paper,
            pressed ? _outlinePressed : s.buttonOutline,
          ),
          foreground: c.ink,
        );
      case _Kind.mist:
        return (
          style: _raised(
            c.mistTop,
            c.mist,
            pressed ? s.buttonLightPressed : s.buttonLight,
          ),
          foreground: c.ink,
        );
      case _Kind.dashed:
        return (style: SurfaceStyle.dashed(c.lineStrong), foreground: c.ink);
      case _Kind.stageSolid:
        final shadow = stage!.isDark
            ? (pressed ? _onStagePressed : s.buttonOnStage)
            : (pressed ? s.buttonPressed : s.button);
        return (
          style: _raised(stage.solidTop, stage.solidBottom, shadow),
          foreground: stage.solidForeground,
        );
      case _Kind.stageGhost:
        return (
          style: _raised(
            stage!.ghost,
            stage.ghost,
            pressed ? _ghostPressed : s.buttonGhost,
          ),
          foreground: stage.foreground,
        );
    }
  }
}

/// 左右留白：宽度是给定的（撑满）时用 [tight]，贴着内容时用 [loose]。
///
/// 不用 `LayoutBuilder` 判断宽度，是为了让按钮能回答自己的固有尺寸：抽屉、面板这类按内容
/// 定高的容器会先量一遍里面的按钮，`LayoutBuilder` 量不了。
class _SidePadding extends SingleChildRenderObjectWidget {
  const new({required this.loose, required this.tight, super.child});

  final double loose;
  final double tight;

  @override
  _RenderSidePadding createRenderObject(BuildContext context) =>
      _RenderSidePadding(loose: loose, tight: tight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSidePadding renderObject,
  ) => renderObject
    ..loose = loose
    ..tight = tight;
}

class _RenderSidePadding extends RenderShiftedBox {
  _RenderSidePadding({required this._loose, required this._tight})
    : super(null);

  double _loose;
  set loose(double value) {
    if (value == _loose) return;
    _loose = value;
    markNeedsLayout();
  }

  double _tight;
  set tight(double value) {
    if (value == _tight) return;
    _tight = value;
    markNeedsLayout();
  }

  double _sideFor(BoxConstraints constraints) =>
      constraints.hasTightWidth ? _tight : _loose;

  @override
  double computeMinIntrinsicWidth(double height) =>
      (child?.getMinIntrinsicWidth(height) ?? 0) + _loose * 2;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (child?.getMaxIntrinsicWidth(height) ?? 0) + _loose * 2;

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(math.max(0, width - _loose * 2)) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(math.max(0, width - _loose * 2)) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final side = _sideFor(constraints);
    final inner = constraints.deflate(EdgeInsets.symmetric(horizontal: side));
    final childSize = child?.getDryLayout(inner) ?? Size.zero;
    return constraints.constrain(
      Size(childSize.width + side * 2, childSize.height),
    );
  }

  @override
  void performLayout() {
    final side = _sideFor(constraints);
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(side * 2, 0));
      return;
    }
    child.layout(
      constraints.deflate(EdgeInsets.symmetric(horizontal: side)),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(child.size.width + side * 2, child.size.height),
    );
    (child.parentData! as BoxParentData).offset = Offset(side, 0);
  }
}

SurfaceStyle _raised(Color top, Color bottom, EatShadow shadow) => SurfaceStyle(
  top: top,
  bottom: bottom,
  outer: shadow.outer,
  inset: shadow.inset,
);

// 下面三种按下的阴影只出现在 Button 组件的预览里，没有进 tokens.json。

/// 描边按钮按下：只剩描边，底边和投影收掉。
const _outlinePressed = EatShadow(
  inset: [BoxShadow(spreadRadius: 1.5, color: Color(0xFF231C18))],
);

/// 深色舞台上的白色实心按钮按下。
const _onStagePressed = EatShadow(
  outer: [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      color: Color.fromRGBO(0, 0, 0, 0.18),
    ),
  ],
  inset: [
    BoxShadow(offset: Offset(0, -1), color: Color.fromRGBO(0, 0, 0, 0.14)),
  ],
);

/// 舞台次按钮按下：顶边高光变暗，投影收掉。
const _ghostPressed = EatShadow(
  inset: [
    BoxShadow(offset: Offset(0, 1), color: Color.fromRGBO(255, 255, 255, 0.3)),
  ],
);
