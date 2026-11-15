import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show CircularProgressIndicator;

/// 验证码输入框右侧的发送操作, 放在 `EatFormField.trailing`.
///
/// - 可发送时是文字按钮 "获取验证码": `ink` 色 600 字重, 不带底色和胶囊. 点击区域高 44px.
/// - [onPressed] 为 null 时文字为 `disabled-fg`, 不可点.
/// - [sending] 时文字换成进度圈, 宽度不变.
/// - [secondsLeft] 大于 0 时换成 "N 秒后重发" 倒计时.
class SendCodeAction extends StatelessWidget {
  const new({
    super.key,
    required this.secondsLeft,
    required this.onPressed,
    this.sending = false,
  });

  static const label = '获取验证码';

  final int secondsLeft;
  final VoidCallback? onPressed;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    if (secondsLeft > 0) {
      return Semantics(
        liveRegion: true,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$secondsLeft',
                style: eat.text.count.copyWith(color: c.inkMuted),
              ),
              const TextSpan(text: ' 秒后重发'),
            ],
          ),
          style: eat.text.body.copyWith(color: c.inkMuted),
        ),
      );
    }
    final color = onPressed == null ? c.disabledFg : c.ink;
    final text = Text(
      label,
      style: eat.text.body.copyWith(fontWeight: FontWeight.w600, color: color),
    );
    return EatTappable(
      onTap: sending ? null : onPressed,
      label: sending ? '$label，进行中' : null,
      focusShape: const StadiumBorder(),
      builder: (context, _) => SizedBox(
        height: EatSize.touch,
        child: Padding(
          padding: const EdgeInsets.only(left: EatSpace.s8),
          child: Center(
            widthFactor: 1,
            child: sending
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(opacity: 0, child: text),
                      SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.ink,
                          value: MediaQuery.disableAnimationsOf(context)
                              ? 0.75
                              : null,
                        ),
                      ),
                    ],
                  )
                : text,
          ),
        ),
      ),
    );
  }
}
