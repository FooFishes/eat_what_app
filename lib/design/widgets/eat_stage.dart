import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 有主角菜的页面顶部那块彩色区域。
///
/// 只负责「舞台」这一层：铺舞台色，向下提供 [StageTheme]（舞台上的按钮、文字从这里取色），
/// 默认文字色设成舞台文字色，状态栏图标按深浅切换；换舞台色时底色、文字、按钮 500ms 一起过渡。
/// 菜名、价格、盘子和按钮怎么摆由各个页面决定。舞台上只用 9 个 `stage-*`，不直接用照片的平均色。
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
