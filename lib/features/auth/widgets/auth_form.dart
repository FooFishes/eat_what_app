import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';

/// 登录表单下面的一句出错说明：`warn` 加警示图标，说清楚哪里不对、下一步怎么做。
class FormMessage extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: EatIcon(EatIcons.warning, size: 18, color: eat.colors.warn),
          ),
          Expanded(
            child: Text(
              text,
              style: eat.text.meta.copyWith(color: eat.colors.warn),
            ),
          ),
        ],
      ),
    );
  }
}

/// 表单下方居中的文字链接（「用密码登录」「用验证码登录」），点击区域 44px 高。
class FormLink extends StatelessWidget {
  const new(this.label, {super.key, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Center(
      child: EatTappable(
        onTap: onTap,
        label: label,
        focusShape: const StadiumBorder(),
        builder: (context, _) => SizedBox(
          height: EatSize.touch,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: eat.text.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: eat.colors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
