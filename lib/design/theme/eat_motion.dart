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

  /// 舞台页顶栏在舞台样式和吸顶后的白底样式之间切换: 底色, 文字和图标颜色, 首页按钮的收拢一起过渡.
  ///
  /// 按时间过渡而不是跟着滚动距离走, 往上甩时抽屉很快穿过分界处, 跟着滚动会像突变.
  static const EatTransition barPin = (
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOutCubic,
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

  /// 用于从一格展开成卡片 (如数字条的评分格展开成评分卡): 位置, 大小和底色一起过渡, 内容先出后进.
  static const EatTransition morph = (
    duration: Duration(milliseconds: 420),
    curve: Curves.easeInOutCubicEmphasized,
  );

  /// 用于点赞和打分时图形弹一下: 先略微压扁, 再放大越过原大小, 最后落回.
  static const EatTransition pop = (
    duration: Duration(milliseconds: 520),
    curve: Curves.linear,
  );

  /// 换深浅色: 旧界面的截图在新界面上淡出.
  static const EatTransition themeSwitch = (
    duration: Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  /// 弹簧: 快速的位移, 带一点回弹 (Material 3 的 expressive fast spatial). 用于轻提示进场和抖一下.
  static final springBouncy = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 800,
    ratio: 0.6,
  );

  /// 弹簧: 快速的位移, 几乎不回弹 (Material 3 的 standard fast spatial). 用于轻提示退场和拖动后回位.
  static final springSnappy = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 1400,
    ratio: 0.9,
  );

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
