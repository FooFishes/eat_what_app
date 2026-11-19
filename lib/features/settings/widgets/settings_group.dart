import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:flutter/widgets.dart';

/// 设置页的一组选项: 上面是小标题和说明, 下面是一张圆角卡片, 卡片里的行之间隔一条 `hairline`.
///
/// 卡片底色是 `mist` 和 `paper` 各一半左右, 比 `mist` 浅; 整张 `mist` 铺满一页显得发灰.
///
/// 卡片给每行留出左右 16px, 行本身不再加左右边距.
class SettingsGroup extends StatelessWidget {
  const new({
    super.key,
    this.title,
    this.note,
    this.dividerIndent = SettingsRow.textInset,
    this.rowPadding = 0,
    required this.children,
  });

  final String? title;

  /// 小标题下面的一句说明, 用 `meta` 和 `ink-muted`.
  final Widget? note;

  /// 分隔线从左边多远开始. 默认对齐 [SettingsRow] 的文字; 组里有不带图标的开关时传 0, 从卡片边缘留 16px 开始.
  final double dividerIndent;

  /// 每行上下多留的空白. [SettingsRow] 自带行高, 不用留; 开关的说明可能折成两行, 传 `EatSpace.s8`.
  final double rowPadding;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    final line = 1 / MediaQuery.devicePixelRatioOf(context);
    final card = Color.alphaBlend(c.mist.withValues(alpha: 0.55), c.paper);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final title?)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: EatSpace.s8),
            child: ListGroupTitle(title),
          ),
        if (note case final note?)
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              right: 4,
              bottom: EatSpace.s8,
            ),
            child: DefaultTextStyle.merge(
              style: context.eat.text.meta.copyWith(color: c.inkMuted),
              child: note,
            ),
          ),
        ClipRRect(
          borderRadius: const BorderRadius.all(EatRadius.thumbLg),
          child: ColoredBox(
            color: card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsets.only(
                        left: EatSpace.s16 + dividerIndent,
                      ),
                      child: SizedBox(
                        height: line,
                        child: ColoredBox(color: c.hairline),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: EatSpace.s16,
                      vertical: rowPadding,
                    ),
                    child: child,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
