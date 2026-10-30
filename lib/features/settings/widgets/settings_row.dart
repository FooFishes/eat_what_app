import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 设置里的一行：左边 22px 图标、名字，右边当前的值；能点进去时最右边是箭头。
///
/// 还没有接口的功能照样列出来，名字旁边放「待接入」（[pending]），点了不做任何事。
class SettingsRow extends StatelessWidget {
  const new({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.numericValue = false,
    this.pending = false,
    this.onTap,
  });

  final EatIcons icon;
  final String label;
  final String? value;

  /// 值是版本号、打码的手机号这类数字时用数字字体。
  final bool numericValue;
  final bool pending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final valueStyle = numericValue
        ? eat.text.count.copyWith(fontSize: 15, color: c.inkMuted)
        : eat.text.body.copyWith(fontSize: 14, color: c.inkMuted);
    final row = SizedBox(
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: EatSpace.s14,
          children: [
            EatIcon(icon, size: 22, color: c.ink),
            Expanded(
              child: Row(
                spacing: EatSpace.s8,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: eat.text.body.copyWith(fontSize: 16, color: c.ink),
                    ),
                  ),
                  if (pending) const PendingTag(),
                ],
              ),
            ),

            /// 值不参与分配剩余宽度，否则会和名字各占一半，短的值贴不到右边；只限制它最多占半行。
            if (value case final value?)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: valueStyle,
                ),
              ),
            if (onTap != null)
              EatIcon(EatIcons.chevronRight, size: 20, color: c.inkMuted),
          ],
        ),
      ),
    );
    if (onTap == null) return MergeSemantics(child: row);
    return EatTappable(
      onTap: onTap,
      button: false,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => row,
    );
  }
}
