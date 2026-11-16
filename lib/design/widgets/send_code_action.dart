import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show CircularProgressIndicator;

/// 放置于 `EatFormField.trailing` 的验证码发送操作按钮.
///
/// - 可发送状态下展示 600 字重 `ink` 色的 "获取验证码" 纯文字按钮 (无底色与胶囊, 点击区域高 44px).
/// - 当 [onPressed] 为 null 时文字变为 `disabled-fg` 且不可点击.
/// - 当 [sending] 为 true 时替换为等宽度的加载进度圈; 当 [secondsLeft] 大于 0 时展示 "N 秒后重发" 倒计时.
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
