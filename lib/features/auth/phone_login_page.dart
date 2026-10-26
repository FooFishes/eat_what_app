import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/auth/auth_providers.dart';
import 'package:eat/features/auth/widgets/auth_form.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 手机号登录（`G-PhoneLogin`）：手机号加 6 位验证码，新号码验证后自动注册。
///
/// 发验证码前先过人机验证；60 秒后才能重发。登录成功后由守卫带回原来要去的页面，新号码进认证引导。
class PhoneLoginPage extends ConsumerStatefulWidget {
  const new({super.key, this.query = const {}});

  /// 登录页带来的 `from`、`expired`，原样往下传。
  final Map<String, String> query;

  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage> {
  final _mobile = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  Timer? _ticker;
  String? _mobileError;

  @override
  void initState() {
    super.initState();
    // Web 上直接打开或刷新这一页时还没勾协议，先回登录页勾选。
    if (!ref.read(loginAgreementProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(_withQuery(Paths.login));
      });
    }
    _mobile.addListener(_onChanged);
    _code.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _mobile.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// 人机验证弹在这一页上；页面已经关掉时当作用户取消。
  Future<CaptchaOutcome> _presentCaptcha(CaptchaParams params) async {
    if (!mounted) return const CaptchaCancelled();
    return ref.read(humanVerifierProvider).verify(context, params);
  }

  void _onChanged() => setState(() {});

  String _withQuery(String path) => Uri(
    path: path,
    queryParameters: widget.query.isEmpty ? null : widget.query,
  ).toString();

  Future<void> _sendCode() async {
    final mobile = _mobile.text;
    if (!AccountRules.isMobile(mobile)) {
      setState(() => _mobileError = '请输入正确的手机号');
      return;
    }
    setState(() => _mobileError = null);
    await ref
        .read(phoneLoginProvider.notifier)
        .sendCode(_presentCaptcha, mobile);
    if (!mounted) return;
    if (ref.read(phoneLoginProvider).resendAt != null) {
      _codeFocus.requestFocus();
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final resendAt = ref.read(phoneLoginProvider).resendAt;
      if (resendAt == null || !clock.now().isBefore(resendAt)) timer.cancel();
      setState(() {});
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref.read(phoneLoginProvider.notifier).submit(_mobile.text, _code.text);
  }

  void _showLimited() => showPanel<void>(
    context,
    builder: (panel) => EatPanel(
      icon: EatIcons.time,
      title: '验证码发送次数已达上限，请明天再试',
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '用密码登录',
              onPressed: () {
                Navigator.of(panel).pop();
                context.push(_withQuery(Paths.loginPassword));
              },
            ),
          ),
          Expanded(
            child: EatButton.solid(
              '知道了',
              onPressed: () => Navigator.of(panel).pop(),
            ),
          ),
        ],
      ),
      child: Text(
        '同一个号码 1 小时最多发 5 次，一天最多 10 次。设过密码的话，可以用密码登录。',
        style: panel.eat.text.body.copyWith(height: 22 / 15),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final login = ref.watch(phoneLoginProvider);
    ref.listen(phoneLoginProvider.select((s) => s.event), (_, event) {
      if (event is AuthCodeLimited) _showLimited();
    });
    final resendAt = login.resendAt;
    final secondsLeft = resendAt == null
        ? 0
        : (resendAt.difference(clock.now()).inMilliseconds / 1000).ceil();
    final failure = switch (login.event) {
      AuthFormFailed(:final failure)
          when failure.kind != FailureKind.cancelled =>
        failure,
      _ => null,
    };
    final wrongCode = failure?.code == BizCodes.wrongCode;
    final ready =
        AccountRules.isMobile(_mobile.text) &&
        AccountRules.isSmsCode(_code.text) &&
        !login.submitting;
    final numberStyle = eat.text.count.copyWith(color: c.inkMuted);

    return PlainScaffold(
      title: '手机号登录',
      subtitle: '没注册过的号码，验证后自动注册',
      slivers: [
        SliverToBoxAdapter(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: EatSpace.s14),
                EatFormField(
                  label: '手机号',
                  controller: _mobile,
                  hintText: '11 位手机号',
                  numeric: true,
                  prefix: '+86',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  errorText: _mobileError,
                ),
                const SizedBox(height: 26),
                EatFormField(
                  label: '验证码',
                  controller: _code,
                  focusNode: _codeFocus,
                  hintText: '6 位数字',
                  numeric: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) {
                    if (ready) _submit();
                  },
                  errorText: wrongCode ? failure!.message : null,
                  trailing: secondsLeft > 0
                      ? Semantics(
                          liveRegion: true,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$secondsLeft',
                                  style: numberStyle,
                                ),
                                const TextSpan(text: ' 秒后重发'),
                              ],
                            ),
                            style: eat.text.body.copyWith(
                              fontSize: 14,
                              color: c.inkMuted,
                            ),
                          ),
                        )
                      : EatButton.mist(
                          '获取验证码',
                          height: 36,
                          onPressed: login.sending ? null : _sendCode,
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  '验证码 5 分钟内有效，60 秒后可以重发',
                  style: eat.text.caption.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: 40),
                if (failure != null && !wrongCode) ...[
                  FormMessage(failure.message),
                  const SizedBox(height: EatSpace.s14),
                ],
                EatButton.solid('登录', onPressed: ready ? _submit : null),
                const SizedBox(height: 6),
                FormLink(
                  '用密码登录',
                  onTap: () => context.push(_withQuery(Paths.loginPassword)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
