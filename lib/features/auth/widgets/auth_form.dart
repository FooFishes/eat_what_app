import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 登录表单下方的错误说明, `warn` 色文字配警示图标.
///
/// 文字须说明错误原因和下一步操作.
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

/// 表单下方居中的文字链接, 如 "用密码登录" 和 "用验证码登录". 点击区域高 44px.
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

/// 手机号输入格式化器, 仅保留数字且最多 11 位.
///
/// 从通讯录或短信复制的号码常含 +86 前缀, 空格及横线, 因此需先剥离区号再截断至 11 位, 避免 "+86 138 1234 5678" 被截断为 "86138123456".
class MobileInputFormatter extends TextInputFormatter {
  const new();

  static const _length = 11;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > _length) {
      for (final prefix in const ['0086', '86']) {
        if (digits.startsWith(prefix) &&
            digits.length - prefix.length <= _length) {
          digits = digits.substring(prefix.length);
          break;
        }
      }
    }
    if (digits.length > _length) digits = digits.substring(0, _length);
    if (digits == newValue.text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
