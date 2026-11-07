import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:eat/features/settings/widgets/code_field.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 换绑手机: 验证新号码, 服务端要求时用旧手机验证码或密码确认身份.
///
/// - 新号码已注册其他账号时不能换绑.
/// - 换绑后本机的会话换发为新会话, 用户无需重新登录. 未能获取新会话时回到登录页.
class PhonePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends ConsumerState<PhonePage> {
  final _mobile = TextEditingController();
  final _newCode = TextEditingController();
  final _oldCode = TextEditingController();
  final _password = TextEditingController();

  /// 用密码确认身份. 为 false 时用旧手机验证码.
  var _byPassword = false;
  String? _mobileError;
  String? _newCodeError;
  String? _oldError;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_mobile, _newCode, _oldCode, _password]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _mobile.dispose();
    _newCode.dispose();
    _oldCode.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<CaptchaOutcome> _presentCaptcha(CaptchaParams params) async {
    if (!mounted) return const CaptchaCancelled();
    return ref.read(humanVerifierProvider).verify(context, params);
  }

  /// 发送验证码. 失败时在页面内提示并返回 false.
  Future<bool> _send(Future<bool> Function() send) async {
    try {
      return await send();
    } on AppFailure catch (e) {
      if (mounted && e.kind != FailureKind.cancelled) {
        showToast(context, e.message);
      }
      return false;
    }
  }

  Future<void> _submit({required bool oldProofRequired}) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _newCodeError = null;
      _oldError = null;
    });
    try {
      final kept = await ref
          .read(phoneChangeProvider.notifier)
          .commit(
            newCode: _newCode.text,
            oldCode: oldProofRequired && !_byPassword ? _oldCode.text : null,
            password: oldProofRequired && _byPassword ? _password.text : null,
          );
      if (!mounted) return;
      showToast(context, kept ? '手机号已换绑' : '手机号已换绑，请重新登录');
      // 登录态变化后路由会重新匹配当前地址. 在本轮重建结束后返回, 否则本页会被重新放回路由栈.
      if (kept) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) BackFallback.back(context);
        });
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        switch (e.code) {
          case BizCodes.wrongCode:
            _newCodeError = oldProofRequired && !_byPassword
                ? '验证码错误，请检查新旧两个号码收到的验证码'
                : '验证码错误，请重新输入';
          case BizCodes.wrongPassword:
            _oldError = '密码错误，请重新输入';
          default:
            if (e.kind != FailureKind.cancelled) showToast(context, e.message);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final user = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user,
      SignedOut() || Guest() => null,
    };
    final current = user?.phone;
    final change = ref.watch(phoneChangeProvider);
    final mobile = _mobile.text;
    final validMobile = AccountRules.isMobile(mobile) && mobile != current;
    final started = change != null && change.mobile == mobile;
    final oldProofRequired = started && change.oldProofRequired;
    final canUsePassword = user?.hasPassword ?? false;
    final ready =
        !_submitting &&
        started &&
        AccountRules.isSmsCode(_newCode.text) &&
        (!oldProofRequired ||
            (_byPassword
                ? _password.text.isNotEmpty
                : AccountRules.isSmsCode(_oldCode.text)));
    final note = eat.text.caption.copyWith(color: c.inkMuted);
    return PlainScaffold(
      title: '换绑手机',
      subtitle: current == null
          ? '绑定后可以用手机号登录'
          : '现在绑定的是 ${AccountRules.maskMobile(current)}',
      slivers: [
        SliverToBoxAdapter(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: EatSpace.s14),
                EatFormField(
                  label: '新手机号',
                  controller: _mobile,
                  hintText: '11 位手机号',
                  numeric: true,
                  prefix: '+86',
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  errorText: _mobileError,
                  onSubmitted: (_) => setState(
                    () => _mobileError = mobile == current
                        ? '这就是现在绑定的号码'
                        : AccountRules.isMobile(mobile)
                        ? null
                        : '请输入正确的手机号',
                  ),
                ),
                const SizedBox(height: 26),
                CodeField(
                  label: '新手机验证码',
                  controller: _newCode,
                  enabled: validMobile,
                  errorText: _newCodeError,
                  note: '新号码已经注册过别的账号时不能换',
                  onSend: () => _send(
                    () => ref
                        .read(phoneChangeProvider.notifier)
                        .sendNewCode(_presentCaptcha, mobile),
                  ),
                ),
                if (oldProofRequired) ...[
                  const SizedBox(height: 28),
                  Text(
                    '确认是你本人',
                    style: eat.text.subhead.copyWith(color: c.ink),
                  ),
                  if (canUsePassword) ...[
                    const SizedBox(height: EatSpace.s10),
                    Wrap(
                      spacing: EatSpace.s8,
                      children: [
                        EatChip.choice(
                          '旧手机验证码',
                          selected: !_byPassword,
                          onTap: () => setState(() => _byPassword = false),
                        ),
                        EatChip.choice(
                          '密码',
                          selected: _byPassword,
                          onTap: () => setState(() => _byPassword = true),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: EatSpace.s14),
                  if (_byPassword)
                    EatFormField(
                      label: '密码',
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      errorText: _oldError,
                    )
                  else
                    CodeField(
                      label: '旧手机验证码',
                      controller: _oldCode,
                      errorText: _oldError,
                      note: current == null
                          ? null
                          : '验证码发到 ${AccountRules.maskMobile(current)}',
                      onSend: () => _send(
                        () => ref
                            .read(phoneChangeProvider.notifier)
                            .sendOldCode(_presentCaptcha),
                      ),
                    ),
                ],
                const SizedBox(height: 40),
                Text('换绑后用新号码登录，其他设备要重新登录。', style: note),
                const SizedBox(height: EatSpace.s14),
                EatButton.solid(
                  '换绑',
                  loading: _submitting,
                  onPressed: ready
                      ? () => _submit(oldProofRequired: oldProofRequired)
                      : null,
                ),
                const SizedBox(height: EatSpace.s24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
