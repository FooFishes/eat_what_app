import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/auth/auth_providers.dart';
import 'package:eat/features/auth/widgets/auth_form.dart';
import 'package:eat/features/system/consent_dialog.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 密码登录页, 支持使用手机号, 用户名或邮箱登录 (仅限已设置密码的账号).
///
/// 登录失败时就地提示且保留账号输入. 由于服务端不区分账号不存在, 未设密码与密码错误, 页面常驻引导未设密码的用户改用验证码登录.
/// 同一账号连续输错密码达到上限后, 服务端会要求先完成人机验证. 页面不提供找回密码, 忘记密码时需改用验证码登录.
class PasswordLoginPage extends ConsumerStatefulWidget {
  const new({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  ConsumerState<PasswordLoginPage> createState() => _PasswordLoginPageState();
}

class _PasswordLoginPageState extends ConsumerState<PasswordLoginPage> {
  final _account = TextEditingController();
  final _password = TextEditingController();
  var _showPassword = false;

  @override
  void initState() {
    super.initState();
    if (!ref.read(loginAgreementProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(_withQuery(Paths.login));
      });
    }
    _account.addListener(_onChanged);
    _password.addListener(_onChanged);
  }

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  /// 在当前页面弹出政策同意对话框; 若页面已卸载则按拒绝处理.
  Future<bool> _presentConsent() async {
    if (!mounted) return false;
    return showConsentDialog(context);
  }

  /// 在当前页面弹出人机验证; 若页面已卸载则按取消处理.
  Future<CaptchaOutcome> _presentCaptcha(Future<CaptchaParams?> params) async {
    if (!mounted) return const CaptchaCancelled();
    return ref.read(humanVerifierProvider).verify(context, params);
  }

  void _onChanged() => setState(() {});

  String _withQuery(String path) => Uri(
    path: path,
    queryParameters: widget.query.isEmpty ? null : widget.query,
  ).toString();

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(passwordLoginProvider.notifier)
        .submit(
          _presentConsent,
          _presentCaptcha,
          _account.text.trim(),
          _password.text,
        );
  }

  /// 切换至验证码登录.
  ///
  /// 若当前页面是从手机号登录页 push 进入的, 则直接返回上一页; 若从登录页进入或由深链直接打开, 则替换为手机号登录页.
  void _useCode() {
    final matches = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .matches;
    if (matches.isNotEmpty && matches.last is ImperativeRouteMatch) {
      context.pop();
    } else {
      context.go(_withQuery(Paths.loginPhone));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final login = ref.watch(passwordLoginProvider);
    final failure = switch (login.failure) {
      final failure? when failure.kind != FailureKind.cancelled => failure,
      _ => null,
    };
    final wrong = failure != null && isWrongCredentials(failure);
    final ready =
        AccountRules.isLoginAccount(_account.text.trim()) &&
        AccountRules.isPassword(_password.text);

    return PlainScaffold(
      title: '密码登录',
      slivers: [
        SliverToBoxAdapter(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EatFormField(
                  label: '账号',
                  controller: _account,
                  hintText: '手机号或用户名',
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  inputFormatters: [LengthLimitingTextInputFormatter(64)],
                ),
                const SizedBox(height: 26),
                EatFormField(
                  label: '密码',
                  controller: _password,
                  hintText: '6–64 位',
                  obscureText: !_showPassword,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  inputFormatters: [LengthLimitingTextInputFormatter(64)],
                  onSubmitted: (_) {
                    if (ready && !login.submitting) _submit();
                  },
                  // 只有账号或密码错误时下划线显示 `warn` 色.
                  // 网络不可达等错误与输入无关, 提示显示在表单下方.
                  errorText: wrong ? '账号或密码错误' : null,
                  trailing: EatIconButton(
                    _showPassword ? EatIcons.eye : EatIcons.eyeOff,
                    label: _showPassword ? '隐藏密码' : '显示密码',
                    color: c.inkMuted,
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '没设过密码的用验证码登录',
                  style: eat.text.caption.copyWith(color: c.inkMuted),
                ),
                if (failure != null && !wrong) ...[
                  const SizedBox(height: EatSpace.s10),
                  FormMessage(failure.message),
                ],
                const SizedBox(height: 40),
                EatButton.solid(
                  '登录',
                  loading: login.submitting,
                  onPressed: ready ? _submit : null,
                ),
                const SizedBox(height: 6),
                FormLink('用验证码登录', onTap: _useCode),
                const SizedBox(height: EatSpace.s24),
                Text(
                  '忘记密码时可用验证码登录，登录后在设置中修改',
                  textAlign: TextAlign.center,
                  style: eat.text.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
