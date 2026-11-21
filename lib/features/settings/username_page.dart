import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
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

/// 设置用户名页, 用于首次且唯一一次设置密码登录所用的用户名.
///
/// - 通过绑定手机的验证码校验身份, 若尚未设置密码可一并设置.
/// - 设置后本机保持登录并返回上一页, 若同时设置了密码, 则其他设备需重新登录.
/// - 若已设置过用户名, 则仅作只读展示.
class UsernamePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends ConsumerState<UsernamePage> {
  final _username = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  String? _usernameError;
  String? _codeError;
  String? _passwordError;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_username, _code, _password]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _submit({required bool askPassword}) async {
    FocusScope.of(context).unfocus();
    final username = _username.text;
    final password = _password.text;
    setState(() {
      _usernameError = AccountRules.isUsername(username)
          ? null
          : '用户名为 3–10 位字母、数字或下划线';
      _codeError = AccountRules.isSmsCode(_code.text) ? null : '请输入 6 位验证码';
      _passwordError =
          askPassword &&
              password.isNotEmpty &&
              !AccountRules.isPassword(password)
          ? '密码为 6–64 位'
          : null;
    });
    if (_usernameError != null ||
        _codeError != null ||
        _passwordError != null) {
      return;
    }
    setState(() => _submitting = true);
    final auth = ref.read(authRepositoryProvider);
    final withPassword = askPassword && password.isNotEmpty;
    try {
      await auth.checkUsername(username);
      await auth.setUsername(
        username,
        _code.text,
        password: withPassword ? password : null,
      );
      await ref.read(sessionProvider.notifier).refreshUser();
      if (!mounted) return;
      showToast(context, withPassword ? '用户名和密码已设置，其他设备需要重新登录' : '用户名已设置');
      // 刷新用户信息会触发路由重新匹配当前路径, 因此等待本帧重建结束后再返回, 避免本页被重新压入路由栈.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) BackFallback.back(context);
      });
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        switch (e.code) {
          case BizCodes.usernameTaken:
            _usernameError = e.userMessage ?? '用户名已被占用，换一个试试';
          // 10001 也可能说的是密码或验证码, 不放在用户名下面; 这里的提示还写明了规则.
          case 10001:
            _usernameError = '用户名为 3–10 位字母、数字或下划线';
          case BizCodes.wrongCode:
            _codeError = e.message;
          default:
            if (e.kind != FailureKind.cancelled) {
              showToast(
                context,
                e.kind == FailureKind.unknown ? '设置失败，请重试' : e.message,
              );
            }
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
    final note = eat.text.caption.copyWith(color: c.inkMuted);
    if (user?.username case final username?) {
      return PlainScaffold(
        title: '用户名',
        slivers: [
          SliverList.list(
            children: [
              Text(username, style: eat.text.heading.copyWith(color: c.ink)),
              const SizedBox(height: EatSpace.s8),
              Text('用户名设置后无法修改，可用于配合密码登录。', style: note),
            ],
          ),
        ],
      );
    }
    final askPassword = !(user?.hasPassword ?? false);
    final ready =
        _username.text.isNotEmpty && _code.text.length == 6 && !_submitting;
    return PlainScaffold(
      title: '设置用户名',
      slivers: [
        SliverToBoxAdapter(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EatFormField(
                  label: '用户名',
                  controller: _username,
                  hintText: '3–10 位字母、数字或下划线',
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9_]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  errorText: _usernameError,
                ),
                const SizedBox(height: 6),
                Text('用于密码登录，区分大小写，设置后无法修改', style: note),
                const SizedBox(height: 26),
                AccountCodeField(
                  controller: _code,
                  phone: user?.phone,
                  errorText: _codeError,
                ),
                if (askPassword) ...[
                  const SizedBox(height: 26),
                  EatFormField(
                    label: '密码，选填',
                    controller: _password,
                    hintText: '6–64 位',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 6),
                  Text('同时设置密码后，可直接用用户名和密码登录', style: note),
                ],
                const SizedBox(height: 40),
                if (askPassword) ...[
                  Text('同时设置密码后，其他设备需要重新登录。', style: note),
                  const SizedBox(height: EatSpace.s14),
                ],
                EatButton.solid(
                  '设置用户名',
                  loading: _submitting,
                  onPressed: ready
                      ? () => _submit(askPassword: askPassword)
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
