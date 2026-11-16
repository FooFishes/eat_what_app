import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 有主角菜的页面顶部舞台容器, 负责渲染彩色背景并管理舞台内的配色上下文.
///
/// 本组件仅处理舞台基础层:
/// - 铺设舞台色, 并在切换时同步过渡底色, 文字与按钮颜色.
/// - 向下提供 [StageTheme], 供舞台上的按钮和文字取色.
/// - 将默认文字色设为舞台文字色, 并随舞台深浅自动切换状态栏图标色调.
///
/// 菜名, 价格, 盘子和按钮的具体布局由各页面自行决定; 舞台仅使用 9 种预设 `stage-*` 色值, 不直接使用照片平均色.
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
