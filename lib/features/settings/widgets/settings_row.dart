import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/features/settings/widgets/settings_group.dart';
import 'package:flutter/widgets.dart';

/// 设置页的列表行组件, 放在 [SettingsGroup] 的卡片里. 左侧是图标与名称, 右侧展示当前值, 可点击时最右侧附带右箭头.
///
/// 尚未接入接口的功能同样列出, 当 [pending] 为 true 时在名称旁显示 "待接入" 标签.
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

  /// 当值为版本号或脱敏手机号等数字内容时, 设为 true 以使用数字字体.
  final bool numericValue;
  final bool pending;
  final VoidCallback? onTap;

  static const _icon = 22.0;
  static const _gap = EatSpace.s14;

  /// 名称离行左边的距离, [SettingsGroup] 的分隔线从这里开始.
  static const textInset = _icon + _gap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final valueStyle = numericValue
        ? eat.text.count.copyWith(fontSize: 15, color: c.inkMuted)
        : eat.text.body.copyWith(color: c.inkMuted);
    final row = SizedBox(
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: _gap,
          children: [
            EatIcon(icon, size: _icon, color: c.ink),
            Expanded(
              child: Row(
                spacing: EatSpace.s8,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: eat.text.subhead.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.ink,
                      ),
                    ),
                  ),
                  if (pending) const PendingTag(),
                ],
              ),
            ),

            // 值不参与分配剩余宽度, 只限制最大宽度为半行.
            // 参与分配时值和名称各占一半, 较短的值无法靠右对齐.
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
