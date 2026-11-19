import 'package:eat/design/theme/eat_colors.dart';
import 'package:flutter/painting.dart';

/// 阴影令牌, 外阴影和内阴影分别存放.
///
/// 两个列表都按绘制顺序排列, 后绘制的在上层. 该顺序与 CSS 的书写顺序相反.
class const EatShadow({
  /// 外阴影, 直接传给 `BoxDecoration.boxShadow`.
  final List<BoxShadow> outer = const [],

  /// 对应 CSS 的 `inset` 阴影. Flutter 不支持内阴影, 因此由组件自行绘制.
  ///
  /// - `offset.dy` 为正: 顶部高光.
  /// - `offset.dy` 为负: 底部暗边.
  /// - `spreadRadius`: 沿边缘的描边宽度.
  final List<BoxShadow> inset = const [],
});

/// 设计规范中的阴影集合, 仅用于下列位置, 卡片不加投影.
class const EatShadows({
  /// 舞台上盘子的白色盘沿和投影.
  required final EatShadow plate,

  /// 用于导航胶囊, 地图上的搜索框和商圈标签等悬浮元素.
  required final EatShadow float,

  /// 按钮的厚度画在胶囊内部: 底边一道内阴影, 外加一层收在按钮下方的柔和投影.
  /// 按下时内阴影消失, 投影收拢.
  ///
  /// 用于 `ink` 实心按钮及浅色舞台上的实心按钮.
  required final EatShadow button,
  required final EatShadow buttonPressed,

  /// 用于雾面按钮, 包含 `handle` 细描边和浅色底边, 按下时只保留描边.
  ///
  /// 细描边用于区分雾面按钮与不可用按钮的扁平灰底.
  required final EatShadow buttonLight,
  required final EatShadow buttonLightPressed,

  /// 用于描边按钮, 包含 `ink` 描边和柔和投影, 没有底边.
  required final EatShadow buttonOutline,

  /// 用于深色舞台上的白色实心按钮.
  required final EatShadow buttonOnStage,

  /// 用于舞台上的半透明次按钮.
  required final EatShadow buttonGhost,

  /// 用于地图上的店铺标记.
  required final EatShadow pin,

  /// 用于压在地图上的抽屉及登录页的抽屉; 其他压在舞台色上的抽屉不加阴影.
  required final EatShadow sheet,
}) {
  static final light = EatShadows._of(EatColors.light);

  /// 深色模式下雾面按钮和描边按钮的描边换成深色的 `handle` 和 `ink`, 投影不变.
  static final dark = EatShadows._of(EatColors.dark);

  factory EatShadows._of(EatColors c) => EatShadows(
    plate: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 22),
          blurRadius: 40,
          color: Color.fromRGBO(0, 0, 0, 0.3),
        ),
        BoxShadow(spreadRadius: 8, color: Color(0xFFFFFFFF)),
      ],
    ),
    float: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 8),
          blurRadius: 24,
          color: Color.fromRGBO(35, 28, 24, 0.14),
        ),
        BoxShadow(spreadRadius: 1, color: Color.fromRGBO(35, 28, 24, 0.06)),
      ],
    ),
    button: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 6),
          blurRadius: 14,
          spreadRadius: -6,
          color: Color.fromRGBO(35, 28, 24, 0.4),
        ),
      ],
      inset: [
        BoxShadow(offset: Offset(0, -3), color: Color.fromRGBO(0, 0, 0, 0.35)),
      ],
    ),
    buttonPressed: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -2,
          color: Color.fromRGBO(35, 28, 24, 0.4),
        ),
      ],
    ),
    buttonLight: EatShadow(
      inset: [
        BoxShadow(
          offset: Offset(0, -3),
          color: Color.fromRGBO(35, 28, 24, 0.06),
        ),
        BoxShadow(spreadRadius: 1, color: c.handle),
      ],
    ),
    buttonLightPressed: EatShadow(
      inset: [BoxShadow(spreadRadius: 1, color: c.handle)],
    ),
    buttonOutline: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 4),
          blurRadius: 10,
          spreadRadius: -6,
          color: Color.fromRGBO(35, 28, 24, 0.25),
        ),
      ],
      inset: [BoxShadow(spreadRadius: 1.5, color: c.ink)],
    ),
    buttonOnStage: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 8),
          blurRadius: 18,
          spreadRadius: -8,
          color: Color.fromRGBO(0, 0, 0, 0.4),
        ),
      ],
      inset: [
        BoxShadow(offset: Offset(0, -3), color: Color.fromRGBO(0, 0, 0, 0.12)),
      ],
    ),
    buttonGhost: EatShadow(
      inset: [
        BoxShadow(offset: Offset(0, -3), color: Color.fromRGBO(0, 0, 0, 0.06)),
      ],
    ),
    pin: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 4),
          blurRadius: 10,
          color: Color.fromRGBO(35, 28, 24, 0.18),
        ),
      ],
    ),
    sheet: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, -6),
          blurRadius: 20,
          color: Color.fromRGBO(35, 28, 24, 0.08),
        ),
      ],
    ),
  );
}
