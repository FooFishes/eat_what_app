import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/send_code_action.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 发到本账号绑定手机的验证码输入框. 右侧是 "获取验证码" 或重发倒计时.
///
/// 发送前需完成人机验证. 发送失败时用轻提示说明原因.
/// [phone] 是绑定的手机号, 打码后显示在输入框下方. [purpose] 决定发哪种验证码.
class AccountCodeField extends ConsumerStatefulWidget {
  const new({
    super.key,
    required this.controller,
    required this.phone,
    this.purpose = AccountCodePurpose.password,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? phone;
  final AccountCodePurpose purpose;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  ConsumerState<AccountCodeField> createState() => _AccountCodeFieldState();
}

class _AccountCodeFieldState extends ConsumerState<AccountCodeField> {
  final _focus = FocusNode();
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _focus.dispose();
    super.dispose();
  }

  Future<CaptchaOutcome> _presentCaptcha(Future<CaptchaParams?> params) async {
    if (!mounted) return const CaptchaCancelled();
    return ref.read(humanVerifierProvider).verify(context, params);
  }

  Future<void> _send() async {
    await ref
        .read(accountCodeProvider(widget.purpose).notifier)
        .send(_presentCaptcha);
    if (!mounted) return;
    final state = ref.read(accountCodeProvider(widget.purpose));
    if (state.failure case final failure?) {
      if (failure.kind == FailureKind.cancelled) return;
      showToast(
        context,
        failure.kind == FailureKind.tooFrequent
            ? '发送太频繁，${failure.retryHint}'
            : failure.code == BizCodes.mobileNotBound
            ? '账号还没有绑定手机号'
            : failure.message,
      );
      return;
    }
    if (state.resendAt != null) {
      _focus.requestFocus();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        final resendAt = ref.read(accountCodeProvider(widget.purpose)).resendAt;
        if (resendAt == null || !clock.now().isBefore(resendAt)) {
          timer.cancel();
        }
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final code = ref.watch(accountCodeProvider(widget.purpose));
    final resendAt = code.resendAt;
    final secondsLeft = resendAt == null
        ? 0
        : (resendAt.difference(clock.now()).inMilliseconds / 1000).ceil();
    final phone = widget.phone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        EatFormField(
          label: '验证码',
          controller: widget.controller,
          focusNode: _focus,
          hintText: '6 位数字',
          numeric: true,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          errorText: widget.errorText,
          onSubmitted: widget.onSubmitted,
          trailing: SendCodeAction(
            secondsLeft: secondsLeft,
            sending: code.sending,
            onPressed: _send,
          ),
        ),
        if (phone != null)
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '验证码发到 '),
                TextSpan(
                  text: AccountRules.maskMobile(phone),
                  style: eat.text.count,
                ),
                const TextSpan(text: '，5 分钟内有效'),
              ],
            ),
            style: eat.text.caption.copyWith(color: c.inkMuted),
          ),
      ],
    );
  }
}
