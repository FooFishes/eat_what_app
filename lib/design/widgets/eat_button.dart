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

/// 有厚度的胶囊按钮.
///
/// 文字写明按下后的结果, 如 "就它了" "导航去店里", 不写 "确定".
///
/// 变体:
/// - 白底主操作用 [EatButton.solid], 每屏最多一个.
/// - 白底上并排的次操作用 [EatButton.outline] 或 [EatButton.mist].
/// - "新建" "自己写" 这类补充入口用 [EatButton.dashed].
/// - 舞台上用 [EatButton.stageSolid] 和 [EatButton.stageGhost], 颜色取自所在舞台.
///
/// 状态:
/// - [onPressed] 为 null 时不可用, 显示为扁平灰底. 附近须用 `warn` 文字说明可用条件.
/// - [muted] 的外观与不可用相同, 但仍调用 [onPressed], 由页面提示缺少的条件.
///   去掉 [muted] 后, 外观平滑过渡回正常状态.
/// - [loading] 时文字替换为进度圈, 不响应点击, 外观不变灰. 读屏在按钮名后加 "进行中".
///
/// 宽度默认贴合内容, 放入 `Expanded` 或给定宽度时撑满.
/// 成对出现时左次右主, 等宽, 间距 `space-10`.
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

  /// 舞台上的主操作. 浅色舞台为 `ink` 底, 深色舞台为白色渐变底, 文字均为舞台色.
  const new stageSolid(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.height = EatSize.button,
    this.loading = false,
    this.muted = false,
  }) : _kind = _Kind.stageSolid;

  /// 舞台上的次操作. 半透明磨砂底, 文字为舞台文字色.
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

  /// 文字左侧的图标.
  final EatIcons? icon;

  /// 按钮高度. 列表行中的小按钮 (回关, 关注) 用 36, 点击区域仍会扩展到 44.
  final double height;

  /// 正在处理本次点击, 如等待登录接口返回.
  final bool loading;

  /// 外观为不可用, 但仍响应点击.
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
    return EatTappable(
      onTap: loading ? null : onPressed,
      label: loading ? '$label，进行中' : null,
      builder: (context, pressed) {
        final look = _look(eat, stage, pressed: pressed);
        final sinks =
            onPressed != null && !loading && !muted && _kind != _Kind.dashed;
        final duration = context.motion(EatMotion.press);
        // 按下使用按压时长. 松开以及切换可用状态时使用较长的选中态时长, 颜色渐变而非突变.
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
                  style: (height >= 50 ? eat.text.subhead : eat.text.body)
                      .copyWith(fontWeight: FontWeight.w600, color: foreground),
                ),
              ),
            ],
          ),
        );
        // 进度圈叠加在透明的文字上, 按钮宽度保持不变.
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
        // 贴合内容时两侧留白较宽. 被撑满时文字居中, 两侧留白收窄.
        // 否则三个按钮并排时, "新建一家店" 会被截断为省略号.
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

/// 按宽度约束选择左右留白: 宽度固定 (撑满) 时用 [tight], 贴合内容时用 [loose].
///
/// 不用 `LayoutBuilder` 判断宽度, 因为 `LayoutBuilder` 不支持固有尺寸查询.
/// 抽屉, 面板等按内容定高的容器会先查询内部按钮的固有尺寸.
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

// 以下三种按下阴影不在阴影令牌中, 只供本组件使用.

/// 描边按钮按下: 保留描边, 去掉底边和投影.
const _outlinePressed = EatShadow(
  inset: [BoxShadow(spreadRadius: 1.5, color: Color(0xFF231C18))],
);

/// 深色舞台上白色实心按钮的按下阴影.
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

/// 舞台次按钮按下: 顶边高光变暗, 去掉投影.
const _ghostPressed = EatShadow(
  inset: [
    BoxShadow(offset: Offset(0, 1), color: Color.fromRGBO(255, 255, 255, 0.3)),
  ],
);
