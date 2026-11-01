import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 有主角菜的页面顶部的彩色区域.
///
/// 本组件只负责舞台这一层:
/// - 铺设舞台色.
/// - 向下提供 [StageTheme], 舞台上的按钮和文字从中取色.
/// - 默认文字色设为舞台文字色, 状态栏图标随舞台深浅切换.
/// - 切换舞台色时, 底色, 文字和按钮同步过渡.
///
/// 菜名, 价格, 盘子和按钮的布局由各页面决定.
/// 舞台只使用 9 个 `stage-*`, 不直接使用照片的平均色.
class EatStage extends StatelessWidget {
  const new({super.key, required this.stage, required this.child});

  final StageColor stage;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedStageTheme(
    stage: stage,
    builder: (context, palette) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: palette.background,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: palette.foreground),
          child: child,
        ),
      ),
    ),
  );
}
