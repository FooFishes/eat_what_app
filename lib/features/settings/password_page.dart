import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/settings/widgets/account_code_field.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 设置或修改密码. 密码 6–64 位.
///
/// - 未设置密码: 用绑定手机的验证码设置.
/// - 已设置密码: 用旧密码或手机验证码修改, 在顶部切换方式.
/// - 成功后其他设备需要重新登录, 本机不受影响.
class PasswordPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends ConsumerState<PasswordPage> {
  final _old = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  /// 已设置密码时是否用验证码修改. 为 false 时用旧密码.
  var _byCode = false;
  String? _oldError;
  String? _codeError;
  String? _passwordError;
  String? _repeatError;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_old, _code, _password, _repeat]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _old.dispose();
    _code.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _submit({required bool hasPassword}) async {
    FocusScope.of(context).unfocus();
    final byCode = !hasPassword || _byCode;
    final password = _password.text;
    setState(() {
      _oldError = null;
      _codeError = byCode && !AccountRules.isSmsCode(_code.text)
          ? '请输入 6 位验证码'
          : null;
      _passwordError = AccountRules.isPassword(password) ? null : '密码为 6–64 位';
      _repeatError = _repeat.text == password ? null : '两次输入的密码不一致';
    });
    if (_codeError != null || _passwordError != null || _repeatError != null) {
      return;
    }
    setState(() => _submitting = true);
    final auth = ref.read(authRepositoryProvider);
    try {
      if (byCode) {
        await auth.resetPassword(_code.text, password);
      } else {
        await auth.changePassword(_old.text, password);
      }
      await ref.read(sessionProvider.notifier).refreshUser();
      if (!mounted) return;
      showToast(context, hasPassword ? '密码已修改，其他设备需要重新登录' : '密码已设置');
      // 登录态变化后路由会重新匹配当前地址. 在本轮重建结束后返回, 否则本页会被重新放回路由栈.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) BackFallback.back(context);
      });
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        switch (e.code) {
          case BizCodes.wrongPassword:
            _oldError = '旧密码错误，请重新输入';
          case BizCodes.passwordNotSet:
            _byCode = true;
            showToast(context, '该账号还没设过密码，请用验证码设置');
          case BizCodes.wrongCode:
            _codeError = e.message;
          default:
            if (e.kind != FailureKind.cancelled) {
              showToast(
                context,
                e.kind == FailureKind.unknown ? '保存失败，请重试' : e.message,
              );
            }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final user = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user,
      SignedOut() || Guest() => null,
    };
    final hasPassword = user?.hasPassword ?? false;
    final byCode = !hasPassword || _byCode;
    final ready =
        !_submitting &&
        (byCode ? _code.text.length == 6 : _old.text.isNotEmpty) &&
        _password.text.isNotEmpty &&
        _repeat.text.isNotEmpty;
    return PlainScaffold(
      title: hasPassword ? '修改密码' : '设置密码',
      slivers: [
        SliverToBoxAdapter(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasPassword) ...[
                  Wrap(
                    spacing: EatSpace.s8,
                    children: [
                      EatChip.choice(
                        '用旧密码',
                        selected: !_byCode,
                        onTap: () => setState(() => _byCode = false),
                      ),
                      EatChip.choice(
                        '用验证码',
                        selected: _byCode,
                        onTap: () => setState(() => _byCode = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: EatSpace.s20),
                ],
                if (byCode)
                  AccountCodeField(
                    controller: _code,
                    phone: user?.phone,
                    errorText: _codeError,
                  )
                else
                  EatFormField(
                    label: '旧密码',
                    controller: _old,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    errorText: _oldError,
                  ),
                const SizedBox(height: 26),
                EatFormField(
                  label: '新密码',
                  controller: _password,
                  hintText: '6–64 位',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  errorText: _passwordError,
                ),
                const SizedBox(height: 26),
                EatFormField(
                  label: '再输一次新密码',
                  controller: _repeat,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  errorText: _repeatError,
                  onSubmitted: (_) {
                    if (ready) _submit(hasPassword: hasPassword);
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  hasPassword ? '修改后，其他设备需要重新登录。' : '设置后可使用手机号或用户名配合密码登录。',
                  style: eat.text.caption.copyWith(color: eat.colors.inkMuted),
                ),
                const SizedBox(height: EatSpace.s14),
                EatButton.solid(
                  hasPassword ? '修改密码' : '设置密码',
                  loading: _submitting,
                  onPressed: ready
                      ? () => _submit(hasPassword: hasPassword)
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
