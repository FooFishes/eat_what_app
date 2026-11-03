import 'package:flutter/painting.dart';

/// 阴影令牌, 外阴影和内阴影分别存放.
///
/// 两个列表都按绘制顺序排列, 后绘制的在上层. 该顺序与 CSS 的书写顺序相反.
class const EatShadow({
  /// 外阴影, 直接传给 `BoxDecoration.boxShadow`.
  final List<BoxShadow> outer = const [],

  /// 对应 CSS 的 `inset` 阴影. Flutter 不支持内阴影, 由组件自行绘制.
  ///
  /// - `offset.dy` 为正: 顶部高光.
  /// - `offset.dy` 为负: 底部暗边.
  /// - `spreadRadius`: 沿边缘的描边宽度.
  final List<BoxShadow> inset = const [],
});

/// 设计规范中的阴影. 只用于下列位置, 卡片不加投影.
class const EatShadows({
  /// 舞台上的盘子: 白色盘沿和投影.
  required final EatShadow plate,

  /// 悬浮元素: 导航胶囊, 地图上的搜索框和商圈标签.
  required final EatShadow float,

  /// `ink` 实心按钮, 搭配 `ink-top` 到 `ink` 的渐变.
  required final EatShadow button,
  required final EatShadow buttonPressed,

  /// 雾面按钮, 搭配 `mist-top` 到 `mist` 的渐变.
  required final EatShadow buttonLight,
  required final EatShadow buttonLightPressed,

  /// 描边按钮: `ink` 描边和浅色底边.
  required final EatShadow buttonOutline,

  /// 深色舞台上的白色实心按钮, 搭配 `paper` 到 `paper-bottom` 的渐变.
  required final EatShadow buttonOnStage,

  /// 舞台上的半透明次按钮.
  required final EatShadow buttonGhost,

  /// 地图上的店铺标记.
  required final EatShadow pin,

  /// 压在地图上的抽屉. 压在舞台色上的抽屉不加阴影.
  required final EatShadow sheet,
}) {
  static const standard = EatShadows(
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
          color: Color.fromRGBO(35, 28, 24, 0.16),
        ),
        BoxShadow(
          offset: Offset(0, 1),
          blurRadius: 2,
          color: Color.fromRGBO(35, 28, 24, 0.2),
        ),
      ],
      inset: [
        BoxShadow(offset: Offset(0, -2), color: Color.fromRGBO(0, 0, 0, 0.28)),
        BoxShadow(
          offset: Offset(0, 1),
          color: Color.fromRGBO(255, 255, 255, 0.16),
        ),
      ],
    ),
    buttonPressed: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 1),
          blurRadius: 1,
          color: Color.fromRGBO(35, 28, 24, 0.2),
        ),
      ],
      inset: [
        BoxShadow(offset: Offset(0, -1), color: Color.fromRGBO(0, 0, 0, 0.24)),
        BoxShadow(
          offset: Offset(0, 1),
          color: Color.fromRGBO(255, 255, 255, 0.1),
        ),
      ],
    ),
    buttonLight: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 3),
          blurRadius: 8,
          color: Color.fromRGBO(35, 28, 24, 0.06),
        ),
        BoxShadow(
          offset: Offset(0, 1),
          blurRadius: 2,
          color: Color.fromRGBO(35, 28, 24, 0.12),
        ),
      ],
      inset: [
        BoxShadow(
          offset: Offset(0, -2),
          color: Color.fromRGBO(35, 28, 24, 0.1),
        ),
        BoxShadow(
          offset: Offset(0, 1),
          color: Color.fromRGBO(255, 255, 255, 0.9),
        ),
      ],
    ),
    buttonLightPressed: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 1),
          blurRadius: 1,
          color: Color.fromRGBO(35, 28, 24, 0.1),
        ),
      ],
      inset: [
        BoxShadow(
          offset: Offset(0, -1),
          color: Color.fromRGBO(35, 28, 24, 0.1),
        ),
        BoxShadow(
          offset: Offset(0, 1),
          color: Color.fromRGBO(255, 255, 255, 0.7),
        ),
      ],
    ),
    buttonOutline: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 1),
          blurRadius: 2,
          color: Color.fromRGBO(35, 28, 24, 0.12),
        ),
      ],
      inset: [
        BoxShadow(
          offset: Offset(0, -3),
          color: Color.fromRGBO(35, 28, 24, 0.08),
        ),
        BoxShadow(spreadRadius: 1.5, color: Color(0xFF231C18)),
      ],
    ),
    buttonOnStage: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 8),
          blurRadius: 18,
          color: Color.fromRGBO(0, 0, 0, 0.16),
        ),
        BoxShadow(
          offset: Offset(0, 2),
          blurRadius: 4,
          color: Color.fromRGBO(0, 0, 0, 0.18),
        ),
      ],
      inset: [
        BoxShadow(offset: Offset(0, -2), color: Color.fromRGBO(0, 0, 0, 0.16)),
      ],
    ),
    buttonGhost: EatShadow(
      outer: [
        BoxShadow(
          offset: Offset(0, 1),
          blurRadius: 2,
          color: Color.fromRGBO(0, 0, 0, 0.1),
        ),
      ],
      inset: [
        BoxShadow(offset: Offset(0, -2), color: Color.fromRGBO(0, 0, 0, 0.1)),
        BoxShadow(
          offset: Offset(0, 1),
          color: Color.fromRGBO(255, 255, 255, 0.4),
        ),
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
