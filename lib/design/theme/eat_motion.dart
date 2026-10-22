import 'package:flutter/animation.dart';

/// 一段动效的时长和曲线。
typedef EatTransition = ({Duration duration, Curve curve});

/// 设计规范「动效」里的时长和曲线。系统开启减少动态效果时，组件直接跳到终点，不用这些值。
abstract final class EatMotion {
  /// 转盘吸附：略带回弹，像真的转盘停下来。
  static const EatTransition snap = (
    duration: Duration(milliseconds: 680),
    curve: Cubic(0.2, 0.9, 0.25, 1.1),
  );

  /// 舞台换色：背景和文字一起过渡。
  static const EatTransition stageColor = (
    duration: Duration(milliseconds: 500),
    curve: Curves.ease,
  );

  /// 选中态：标签、单选、开关。规范给的是 160–200ms，取中间值。
  static const EatTransition select = (
    duration: Duration(milliseconds: 180),
    curve: Curves.ease,
  );

  /// 按钮按下：整体下移 [pressOffset]、换成按下的阴影；松开弹回。
  static const EatTransition press = (
    duration: Duration(milliseconds: 90),
    curve: Curves.easeOut,
  );

  static const pressOffset = 1.0;

  /// 登录页转盘匀速转一圈的时间，这是全应用唯一自动播放的动画。
  static const loginSpinPeriod = Duration(seconds: 90);
}
