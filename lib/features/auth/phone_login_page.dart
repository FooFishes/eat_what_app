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
import 'package:eat/features/system/consent_panel.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/cross_site_consent.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 手机号登录页. 使用手机号和短信验证码登录, 新号码验证后自动注册.
///
/// 发送验证码前先完成人机验证, 重发有冷却时间.
/// 登录成功后由守卫导回原目标页面, 新号码导向认证引导.
class PhoneLoginPage extends ConsumerStatefulWidget {
  const new({super.key, this.query = const {}});

  /// 登录页传入的 `from` 和 `expired`, 原样向下传递.
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
    // Web 上直接打开或刷新本页时协议尚未勾选, 返回登录页勾选.
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

  /// 在本页弹出人机验证. 页面已关闭时按用户取消处理.
  Future<CaptchaOutcome> _presentCaptcha(CaptchaParams params) async {
    if (!mounted) return const CaptchaCancelled();
    return ref.read(humanVerifierProvider).verify(context, params);
  }

  /// 在本页弹出同意面板. 页面已关闭时按用户不同意处理.
  Future<bool> _presentConsent(ConsentPolicy policy) async {
    if (!mounted) return false;
    return showConsentPanel(context, policy);
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
    ref
        .read(phoneLoginProvider.notifier)
        .submit(_presentConsent, _mobile.text, _code.text);
  }

  void _showLimited(AppFailure failure) => showPanel<void>(
    context,
    builder: (panel) => EatPanel(
      icon: EatIcons.time,
      title: '发送太频繁，${failure.retryHint}',
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
      child: Text('已设置密码的账号可使用密码登录。', style: panel.eat.text.body),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final login = ref.watch(phoneLoginProvider);
    ref.listen(phoneLoginProvider.select((s) => s.event), (_, event) {
      switch (event) {
        case AuthCodeLimited(:final failure):
          _showLimited(failure);
        case AuthCodeConsumed():
          _code.clear();
        case AuthRestoreRequired():
          _code.clear();
          context.push(Paths.loginRestore);
        default:
      }
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
    // 20010 在验证码登录中表示发码后账号绑定已变化, 旧验证码不能再用.
    // 未登录时网络层不清除会话, 因此页面就地提示重新获取, 不显示 "登录已过期".
    final codeError = switch (failure?.code) {
      BizCodes.wrongCode => failure!.message,
      BizCodes.authorizationExpired => '验证码已失效，请重新获取',
      _ when login.event is AuthCodeConsumed => '验证码已失效，请重新获取',
      _ => null,
    };
    final ready =
        AccountRules.isMobile(_mobile.text) &&
        AccountRules.isSmsCode(_code.text);
    final numberStyle = eat.text.count.copyWith(color: c.inkMuted);

    return PlainScaffold(
      title: '手机号登录',
      subtitle: '未注册的号码验证后自动注册',
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
                  autofocus: true,
                  inputFormatters: const [MobileInputFormatter()],
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
                    if (ready && !login.submitting) _submit();
                  },
                  errorText: codeError,
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
                            style: eat.text.body.copyWith(color: c.inkMuted),
                          ),
                        )
                      : EatButton.mist(
                          '获取验证码',
                          height: 36,
                          loading: login.sending,
                          onPressed: _sendCode,
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  '验证码 5 分钟内有效，60 秒后可重新发送',
                  style: eat.text.caption.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: 40),
                if (failure != null && codeError == null) ...[
                  FormMessage(failure.message),
                  const SizedBox(height: EatSpace.s14),
                ],
                EatButton.solid(
                  '登录',
                  loading: login.submitting,
                  onPressed: ready ? _submit : null,
                ),
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
