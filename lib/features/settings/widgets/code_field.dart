import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/send_code_action.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 6 位数字验证码输入框, 右侧为 "获取验证码" 按钮, 发送成功后切换为 60 秒重发倒计时.
///
/// [onSend] 返回 true 表示已发送并启动倒计时, 返回 false 表示未发送 (用户取消人机验证或发送失败).
/// 发送失败的提示由调用方负责展示, [note] 展示在输入框下方 (如接收验证码的手机号).
class CodeField extends StatefulWidget {
  const new({
    super.key,
    required this.label,
    required this.controller,
    required this.onSend,
    this.note,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final Future<bool> Function() onSend;
  final String? note;
  final String? errorText;

  /// 为 false 时禁用 "获取验证码" 按钮, 例如新手机号尚未填写完整.
  final bool enabled;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  static const _interval = Duration(seconds: 60);

  final _focus = FocusNode();
  Timer? _ticker;
  DateTime? _resendAt;
  var _sending = false;

  @override
  void dispose() {
    _ticker?.cancel();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final sent = await widget.onSend();
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (sent) _resendAt = clock.now().add(_interval);
    });
    if (!sent) return;
    _focus.requestFocus();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!clock.now().isBefore(_resendAt!)) timer.cancel();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final resendAt = _resendAt;
    final secondsLeft = resendAt == null
        ? 0
        : (resendAt.difference(clock.now()).inMilliseconds / 1000).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        EatFormField(
          label: widget.label,
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
          trailing: SendCodeAction(
            secondsLeft: secondsLeft,
            sending: _sending,
            onPressed: widget.enabled ? _send : null,
          ),
        ),
        if (widget.note case final note?)
          Text(note, style: eat.text.caption.copyWith(color: c.inkMuted)),
      ],
    );
  }
}
