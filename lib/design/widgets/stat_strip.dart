import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/morph_card.dart';
import 'package:flutter/widgets.dart';

/// [StatStrip] 里的一格: 上面一行小字说明是什么, 中间是数字或短词, 下面一行补充.
class StatCell {
  const StatCell({
    required this.label,
    required this.value,
    this.leading,
    this.note,
    this.onTap,
    this.semanticsLabel,
    this.toggled,
    this.key,
    this.valueWidget,
    this.footer,
  });

  /// 这一格是什么, 如 "评分".
  final String label;

  /// 主体, 如 "4.3". 数字用 Inter 显示, 其余文字用正文字体.
  final String value;

  /// 写在 [value] 前面的图标, 如赞的心形.
  final EatIcons? leading;

  /// 补充说明, 如 "12 人评过".
  final String? note;

  /// 点了做什么. 点了会打开别的东西的格子在 [label] 右边带一个小箭头; 开关类的格子 ([toggled] 不为 null) 不带.
  final VoidCallback? onTap;

  /// 读屏朗读的整格文字, 不传时读 [label], [value] 和 [note].
  final String? semanticsLabel;

  /// 开关类的格子 (如赞) 是否打开.
  final bool? toggled;

  /// 这一格的 key. 要从这一格展开卡片 ([showMorphCard]) 时传一个 [GlobalKey].
  final Key? key;

  /// 代替 [value] 那一行的组件, 如带动画的心形加赞数.
  final Widget? valueWidget;

  /// 代替 [note] 那一行的组件, 如一排小星.
  final Widget? footer;
}

/// 一行等宽的数字格, 放在抽屉顶部概括这道菜或这家店. 底色 `mist`, 格子之间一道细线.
class StatStrip extends StatelessWidget {
  const new(this.cells, {super.key});

  final List<StatCell> cells;

  /// [cell] 的样子, 不带点击和读屏. 从这一格展开卡片时, 卡片开头画的就是它.
  static Widget face(StatCell cell) => _Face(cell);

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.mist,
        borderRadius: const BorderRadius.all(EatRadius.tile),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, cell) in cells.indexed) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: EatSpace.s16),
                  child: SizedBox(
                    width: 1,
                    child: ColoredBox(color: c.hairline),
                  ),
                ),
              Expanded(child: _Cell(cell, key: cell.key)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const new(this.cell, {super.key});

  final StatCell cell;

  @override
  Widget build(BuildContext context) {
    final content = StatStrip.face(cell);
    final label =
        cell.semanticsLabel ??
        [
          cell.label,
          cell.value,
          ?cell.note,
        ].where((s) => s.isNotEmpty).join('，');
    if (cell.onTap case final onTap?) {
      return EatTappable(
        onTap: onTap,
        label: label,
        toggled: cell.toggled,
        focusShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(EatRadius.tile),
        ),
        builder: (context, _) => ExcludeSemantics(child: content),
      );
    }
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(child: content),
    );
  }
}

class _Face extends StatelessWidget {
  const new(this.cell);

  final StatCell cell;

  /// 全是数字, 小数点, 百分号和单位时用 Inter.
  static final _numeric = RegExp(r'^[0-9.,%\s—a-z]+$');

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final numeric = _numeric.hasMatch(cell.value);
    final valueStyle = numeric
        ? eat.text.stat.copyWith(fontSize: 24, height: 30 / 24, color: c.ink)
        : eat.text.subhead.copyWith(
            fontWeight: FontWeight.w700,
            height: 30 / eat.text.subhead.fontSize!,
            color: c.ink,
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s14,
        EatSpace.s14,
        EatSpace.s8,
        EatSpace.s14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Row(
            spacing: 2,
            children: [
              Flexible(
                child: Text(
                  cell.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.meta.copyWith(color: c.inkMuted),
                ),
              ),
              if (cell.onTap != null && cell.toggled == null)
                EatIcon(EatIcons.chevronRight, size: 14, color: c.inkMuted),
            ],
          ),
          SizedBox(
            height: 30,
            child:
                cell.valueWidget ??
                Row(
                  spacing: EatSpace.s4,
                  children: [
                    if (cell.leading case final icon?)
                      EatIcon(icon, size: 20, color: c.ink),
                    Flexible(
                      child: Text(
                        cell.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      ),
                    ),
                  ],
                ),
          ),
          SizedBox(
            height: 18,
            child:
                cell.footer ??
                Text(
                  cell.note ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.caption.copyWith(color: c.inkMuted),
                ),
          ),
        ],
      ),
    );
  }
}
