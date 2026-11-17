import 'package:flutter/widgets.dart';

/// 动效的时长和曲线.
typedef EatTransition = ({Duration duration, Curve curve});

/// 设计规范中的动效时长和曲线.
///
/// 系统开启减少动态效果时, 组件直接跳到终点, 不使用这些值.
abstract final class EatMotion {
  /// 转盘吸附. 曲线末段略微越过终点再回落, 形成回弹.
  static const EatTransition snap = (
    duration: Duration(milliseconds: 680),
    curve: Cubic(0.2, 0.9, 0.25, 1.1),
  );

  /// 舞台换色. 背景和文字同步过渡.
  static const EatTransition stageColor = (
    duration: Duration(milliseconds: 500),
    curve: Curves.ease,
  );

  /// 用于标签, 单选与开关的选中态切换, 取规范 160–200ms 范围的中间值.
  static const EatTransition select = (
    duration: Duration(milliseconds: 180),
    curve: Curves.ease,
  );

  /// 用于按钮按下动效: 整体下移 [pressOffset] 并换用按下的阴影, 松开后复原.
  static const EatTransition press = (
    duration: Duration(milliseconds: 90),
    curve: Curves.easeOut,
  );

  static const pressOffset = 1.0;

  /// 用于照片方块按下: 缩到 [tilePressScale], 松开后复原. 照片没有厚度, 下沉 1px 看不出来, 改为轻微缩小.
  static const tilePressScale = 0.97;

  /// 用于列表条目第一次出现: 从下方 [revealOffset] 处淡入上移, 相邻条目依次错开 [revealStagger].
  static const EatTransition reveal = (
    duration: Duration(milliseconds: 420),
    curve: Curves.easeOutCubic,
  );

  static const revealOffset = 16.0;

  static const revealStagger = Duration(milliseconds: 70);

  /// 用于对话框进出动效: 淡入的同时从 [dialogScale] 放大到原大小.
  static const EatTransition dialog = (
    duration: Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
  );

  static const dialogScale = 0.96;

  /// 登录页转盘匀速旋转一周的时间. 这是应用中唯一自动播放的动画.
  static const loginSpinPeriod = Duration(seconds: 90);
}

extension EatMotionContext on BuildContext {
  /// [transition] 在当前环境下的时长. 系统开启减少动态效果时为零, 组件直接跳到终点.
  Duration motion(EatTransition transition) =>
      MediaQuery.maybeDisableAnimationsOf(this) ?? false
      ? Duration.zero
      : transition.duration;
}
