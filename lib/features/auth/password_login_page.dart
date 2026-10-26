import 'package:eat/core/failure/app_failure.dart';
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
import 'package:eat/router/paths.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 密码登录（`G-PasswordLogin`）：手机号或用户名加密码，只有设过密码的账号能用。
///
/// 出错时就地提示，不清空账号（产品 6.2）。忘了密码就用验证码登录，不单独做找回。
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

  void _onChanged() => setState(() {});

  String _withQuery(String path) => Uri(
    path: path,
    queryParameters: widget.query.isEmpty ? null : widget.query,
  ).toString();

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(passwordLoginProvider.notifier)
        .submit(_account.text.trim(), _password.text);
  }

  /// 从手机号登录页点进来的就退回去；直接打开的没有上一页，换成手机号登录页。
  void _useCode() {
    if (context.canPop()) {
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
        AccountRules.isPassword(_password.text) &&
        !login.submitting;

    return PlainScaffold(
      title: '密码登录',
      subtitle: '设过密码的账号才能用',
      slivers: [
        SliverToBoxAdapter(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: EatSpace.s14),
                EatFormField(
                  label: '手机号或用户名',
                  controller: _account,
                  hintText: '11 位手机号或用户名',
                  textInputAction: TextInputAction.next,
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
                    if (ready) _submit();
                  },
                  // 只有账号或密码不对时下划线变 `warn`；没设过密码、没网这类不是输错了，提示写在下面。
                  errorText: wrong ? '账号或密码错误' : null,
                  trailing: EatIconButton(
                    _showPassword ? EatIcons.eye : EatIcons.eyeOff,
                    label: _showPassword ? '隐藏密码' : '显示密码',
                    color: c.inkMuted,
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                if (failure != null && !wrong) ...[
                  const SizedBox(height: EatSpace.s10),
                  FormMessage(failure.message),
                ],
                const SizedBox(height: 40),
                EatButton.solid('登录', onPressed: ready ? _submit : null),
                const SizedBox(height: 6),
                FormLink('用验证码登录', onTap: _useCode),
                const SizedBox(height: EatSpace.s24),
                Text(
                  '忘了密码就用验证码登录，进去后在设置里改',
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
