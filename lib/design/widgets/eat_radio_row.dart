import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 整行可点的单选项. 选中行铺 `mist` 底, 右侧圆圈变为 `ink` 实心加对勾.
///
/// - 带缩略图的行用于选店, 行高较高.
/// - 不带缩略图的行用于面板选项, 选中时文字加粗.
///
/// 行自带左右内边距. 放入页面时整组需向外偏移相同距离, 文字才能与页面边距对齐.
class EatRadioRow extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.thumbnail,
    required this.selected,
    required this.onSelected,
  });

  final String title;

  /// 第二行文字, 如距离和商圈.
  final Widget? subtitle;

  /// 缩略图, 通常为 52px 的 `ListThumb`.
  final Widget? thumbnail;

  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final hasThumb = thumbnail != null;
    final radius = hasThumb ? EatRadius.tile : const Radius.circular(18);
    final titleStyle = hasThumb
        ? eat.text.rowTitle
        : eat.text.body.copyWith(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          );
    final duration = context.motion(EatMotion.select);
    return EatTappable(
      onTap: onSelected,
      button: false,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      focusShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(radius),
      ),
      builder: (context, _) => AnimatedContainer(
        duration: duration,
        curve: EatMotion.select.curve,
        height: hasThumb ? 68 : 52,
        padding: EdgeInsets.only(left: hasThumb ? 10 : 12, right: 12),
        decoration: BoxDecoration(
          color: selected ? c.mist : c.mist.withValues(alpha: 0),
          borderRadius: BorderRadius.all(radius),
        ),
        child: Row(
          spacing: EatSpace.s14,
          children: [
            ?thumbnail,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle.copyWith(color: c.ink),
                  ),
                  if (subtitle case final subtitle?)
                    DefaultTextStyle.merge(
                      style: eat.text.meta.copyWith(color: c.inkMuted),
                      maxLines: 1,
                      child: subtitle,
                    ),
                ],
              ),
            ),
            _RadioMark(selected: selected, duration: duration),
          ],
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const new({required this.selected, required this.duration});

  final bool selected;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return AnimatedContainer(
      duration: duration,
      curve: EatMotion.select.curve,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.ink : c.ink.withValues(alpha: 0),
        border: Border.all(width: 2, color: selected ? c.ink : c.lineStrong),
      ),
      child: AnimatedOpacity(
        duration: duration,
        opacity: selected ? 1 : 0,
        child: Center(child: EatIcon(EatIcons.check, size: 14, color: c.paper)),
      ),
    );
  }
}
