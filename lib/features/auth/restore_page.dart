import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/auth/restore_providers.dart';
import 'package:eat/features/auth/widgets/auth_form.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 撤销注销: 登录时发现账号在注销冷静期内, 验证身份后撤销, 然后重新登录.
///
/// 用验证码或密码验证, 默认与登录方式一致. 撤销凭的是申请时保存在本机的恢复凭据,
/// 申请不是在这台设备上提交的时只说明原因, 不能撤销.
class RestorePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends ConsumerState<RestorePage> {
  final _code = TextEditingController();
  final _account = TextEditingController();
  final _password = TextEditingController();
  final _codeFocus = FocusNode();
  late final AccountRestore _restore;
  Timer? _ticker;
  var _showPassword = false;

  @override
  void initState() {
    super.initState();
    _restore = ref.read(accountRestoreProvider.notifier);
    final restore = ref.read(accountRestoreProvider);
    _account.text = restore.account;
    // 直接打开或刷新本页时没有要撤销的申请, 回到登录页.
    if (restore.pending == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Paths.login);
      });
    }
    for (final c in [_code, _account, _password]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    _account.dispose();
    _password.dispose();
    _codeFocus.dispose();
    // 凭据只在本页使用. 离开后清除, 下次登录时重新读取.
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore.clear());
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _sendCode() async {
    await _restore.sendCode();
    if (!mounted || ref.read(accountRestoreProvider).failure != null) return;
    _codeFocus.requestFocus();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final resendAt = ref.read(accountRestoreProvider).resendAt;
      if (resendAt == null || !clock.now().isBefore(resendAt)) timer.cancel();
      setState(() {});
    });
  }

  void _submit(RestoreMethod method) {
    FocusScope.of(context).unfocus();
    switch (method) {
      case RestoreMethod.code:
        _restore.submitCode(_code.text);
      case RestoreMethod.password:
        _restore.submitPassword(_account.text.trim(), _password.text);
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Paths.login);
    }
  }

  /// 失败提示. 返回的第一项显示在输入框下, 第二项显示在表单下方.
  static (String?, String?) _messages(AppFailure? failure) {
    if (failure == null || failure.kind == FailureKind.cancelled) {
      return (null, null);
    }
    return switch (failure.code) {
      BizCodes.wrongCode => (failure.message, null),
      BizCodes.wrongPassword || BizCodes.userNotFound => ('账号或密码错误', null),
      // 恢复凭据不匹配, 账号没有设置密码, 或冷静期已结束.
      BizCodes.authorizationExpired => (null, '验证未通过，请重新登录后再试'),
      _ => (null, failure.message),
    };
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final restore = ref.watch(accountRestoreProvider);
    ref.listen(accountRestoreProvider.select((s) => s.restored), (_, done) {
      if (!done) return;
      showToast(context, '已撤销注销，请重新登录');
      _leave();
    });
    final body = eat.text.body.copyWith(color: c.ink);

    if (restore.pending == null || restore.loading) {
      return const PlainScaffold(title: '撤销注销', slivers: []);
    }
    if (restore.missing) {
      return PlainScaffold(
        title: '撤销注销',
        slivers: [
          SliverList.list(
            children: [
              const SizedBox(height: EatSpace.s14),
              Text('账号正在注销。注销申请是在其他设备上提交的，在那台设备上登录可以撤销。', style: body),
              const SizedBox(height: 40),
              EatButton.solid('知道了', onPressed: _leave),
            ],
          ),
        ],
      );
    }

    final method = restore.method;
    final (fieldError, formError) = _messages(restore.failure);
    final deadline = restore.deadline;
    final ready = switch (method) {
      RestoreMethod.code =>
        restore.resendAt != null && AccountRules.isSmsCode(_code.text),
      RestoreMethod.password =>
        AccountRules.isLoginAccount(_account.text.trim()) &&
            AccountRules.isPassword(_password.text),
    };
    final resendAt = restore.resendAt;
    final secondsLeft = resendAt == null
        ? 0
        : (resendAt.difference(clock.now()).inMilliseconds / 1000).ceil();

    return PlainScaffold(
      title: '撤销注销',
      subtitle: '验证身份后账号恢复正常',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: EatSpace.s14),
              Text(
                deadline == null
                    ? '账号正在注销，冷静期结束后彻底删除。'
                    : '账号正在注销，将在 ${TimeFormat.date(deadline, clock.now())}彻底删除。',
                style: body,
              ),
              const SizedBox(height: 26),
              if (method == RestoreMethod.code)
                EatFormField(
                  label: '验证码发到绑定的手机',
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
                    if (ready && !restore.submitting) _submit(method);
                  },
                  errorText: fieldError,
                  trailing: secondsLeft > 0
                      ? Semantics(
                          liveRegion: true,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$secondsLeft',
                                  style: eat.text.count.copyWith(
                                    color: c.inkMuted,
                                  ),
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
                          loading: restore.sending,
                          onPressed: _sendCode,
                        ),
                )
              else ...[
                EatFormField(
                  label: '账号',
                  controller: _account,
                  hintText: '手机号或用户名',
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
                    if (ready && !restore.submitting) _submit(method);
                  },
                  errorText: fieldError,
                  trailing: EatIconButton(
                    _showPassword ? EatIcons.eye : EatIcons.eyeOff,
                    label: _showPassword ? '隐藏密码' : '显示密码',
                    color: c.inkMuted,
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ],
              if (formError != null) ...[
                const SizedBox(height: EatSpace.s10),
                FormMessage(formError),
              ],
              const SizedBox(height: 40),
              EatButton.solid(
                '撤销注销',
                loading: restore.submitting,
                onPressed: ready ? () => _submit(method) : null,
              ),
              const SizedBox(height: 6),
              FormLink(
                method == RestoreMethod.code ? '改用密码验证' : '改用验证码验证',
                onTap: () => _restore.useMethod(
                  method == RestoreMethod.code
                      ? RestoreMethod.password
                      : RestoreMethod.code,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
