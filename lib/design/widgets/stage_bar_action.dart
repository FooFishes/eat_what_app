import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:flutter/widgets.dart';

/// 舞台顶栏右侧的一组 [StageBarAction].
///
/// 舞台上胶囊之间隔 `space-8`, 右边缘与左侧内容一样离屏幕边缘 `space-20` (顶栏自带 8, 再让出 12);
/// 吸顶后按进度收成紧挨着的纯图标按钮, 与其他舞台页的顶栏一致.
class StageBarActions extends StatelessWidget {
  const new({super.key, required this.children});

  final List<StageBarAction> children;

  @override
  Widget build(BuildContext context) {
    final open = 1 - StageScaffold.barPinOf(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 12 * open),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: EatSpace.s8 * open,
        children: children,
      ),
    );
  }
}

/// 舞台顶栏右侧的按钮 (首页的搜索和消息, 我的的编辑资料和设置).
///
/// 顶栏在舞台样式时是舞台次按钮色的胶囊, 图标后跟 [text]; 随吸顶进度 ([StageScaffold.barPinOf]) 增大,
/// 底色和文字淡出, 文字宽度收拢, 吸顶后与 `EatIconButton` 一样是 44×44 的纯图标. 点击区域始终不小于 44.
class StageBarAction extends StatelessWidget {
  const new({
    super.key,
    required this.icon,
    required this.text,
    this.label,
    required this.onTap,
    this.dot = false,
  });

  final EatIcons icon;
  final String text;

  /// 读屏朗读的说明, 可以比 [text] 多带状态 (如未读条数). 不传时读 [text].
  final String? label;
  final VoidCallback onTap;

  /// 是否在图标右上角显示未读圆点.
  final bool dot;

  static const _height = 30.0;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final pin = StageScaffold.barPinOf(context);
    final palette = StageTheme.maybeOf(context);
    final ghost = palette?.ghost ?? eat.colors.mist;
    final open = 1 - pin;
    final style = eat.text.meta.copyWith(
      fontWeight: FontWeight.w600,
      height: 1,
      leadingDistribution: TextLeadingDistribution.even,
    );
    // 圆点描边取图标背后的颜色: 舞台上是胶囊底色, 吸顶后是顶栏的白底.
    final dotBorder = Color.lerp(
      ghost,
      palette?.background ?? eat.colors.paper,
      pin,
    )!;
    final glyph = Stack(
      clipBehavior: Clip.none,
      children: [
        EatIcon(icon, size: 18 + 2 * pin),
        if (dot)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: DefaultTextStyle.of(context).style.color,
                shape: BoxShape.circle,
                border: Border.all(color: dotBorder, width: 2),
              ),
            ),
          ),
      ],
    );
    return EatTappable(
      onTap: onTap,
      label: label ?? text,
      focusShape: const StadiumBorder(),
      builder: (context, pressed) => SizedBox(
        height: EatSize.touch,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, pressed ? 1 : 0),
            child: Container(
              height: _height,
              constraints: const BoxConstraints(minWidth: EatSize.touch),
              // 吸顶后左右各留 12, 图标居中在 44 宽的按钮里.
              padding: EdgeInsets.only(
                left: 12 + 2 * open,
                right: 12 + 4 * open,
              ),
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: ghost.withValues(alpha: ghost.a * open),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  glyph,
                  if (open > 0)
                    ClipRect(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: open,
                        child: Opacity(
                          opacity: open,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: EatSpace.s4,
                            ),
                            child: ExcludeSemantics(
                              child: Transform.translate(
                                offset: Offset(0, _opticalShift(text, style)),
                                child: Text(
                                  text,
                                  maxLines: 1,
                                  textScaler: TextScaler.noScaling,
                                  style: style,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 汉字的视觉中心约在基线上方 0.38em (思源黑体的表意字框是 -0.12em 到 0.88em), 而文字框按字体的
  /// ascent 和 descent 居中, 两者不重合: Noto Sans SC 的 ascent 比 descent 大得多, 字会偏下约 0.05em.
  /// 按实际排版出的基线算出偏差, 把字的视觉中心挪到文字框中线上, 和图标在光学上对齐. 各平台字体的度量
  /// 不同, 所以不写死偏移.
  static double _opticalShift(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final shift = painter.height / 2 - (baseline - 0.38 * style.fontSize!);
    painter.dispose();
    return shift;
  }
}
