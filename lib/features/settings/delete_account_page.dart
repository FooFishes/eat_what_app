import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/settings/delete_account_providers.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:eat/features/settings/widgets/account_code_field.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 注销账号页面, 用于说明数据删留规则与冷静期, 选择是否同步删除评论及回复并完成身份验证.
///
/// 已绑定手机号的账号通过短信验证码验证身份, 未绑定手机号的账号则通过密码验证.
/// 确认提交后立即退出当前登录, 冷静期内在同一台设备上重新登录即可自动撤销注销申请.
class DeleteAccountPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  String? _codeError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    for (final c in [_code, _password]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final form = ref.watch(deleteAccountProvider);
    final phone = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user?) => user.phone,
      _ => null,
    };
    final ready =
        !form.submitting &&
        (phone != null
            ? AccountRules.isSmsCode(_code.text)
            : _password.text.isNotEmpty);
    final body = eat.text.body.copyWith(color: c.ink);
    Widget section(String title, String text) => Padding(
      padding: const EdgeInsets.only(bottom: EatSpace.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(title, style: eat.text.subhead.copyWith(color: c.ink)),
          Text(text, style: body),
        ],
      ),
    );
    return PlainScaffold(
      title: '注销账号',
      slivers: [
        SliverList.list(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '申请后有 '),
                  TextSpan(text: '7', style: eat.text.count),
                  const TextSpan(text: ' 天冷静期，期间账号停用，在这台设备上重新登录即撤销；'),
                  TextSpan(text: '7', style: eat.text.count),
                  const TextSpan(text: ' 天后彻底删除。'),
                ],
              ),
              style: body,
            ),
            const SizedBox(height: EatSpace.s20),
            section(
              '会删除',
              '资料、认证信息、收藏、我的标签、足迹、关注关系、屏蔽列表。'
                  '你点过的赞、口味标签与店铺评价也会一并清除。',
            ),
            section('会保留', '你上传的菜品与新建的店铺将作为菜单的一部分保留，上传者显示为「已注销用户」。'),
            Text('评论和回复', style: eat.text.subhead.copyWith(color: c.ink)),
            EatSwitch(
              label: '同时删除我的评论和回复',
              description: form.deleteComments
                  ? '评论和回复会一起删除'
                  : '不删除时保留，作者显示为「已注销用户」',
              value: form.deleteComments,
              onChanged: form.submitting
                  ? null
                  : (value) => ref
                        .read(deleteAccountProvider.notifier)
                        .setDeleteComments(value: value),
            ),
            const SizedBox(height: EatSpace.s20),
            section('之后', '原手机号可重新注册，此前绑定过的统一认证与校园邮箱也可用于新账号认证。'),
            Text('验证身份', style: eat.text.subhead.copyWith(color: c.ink)),
            const SizedBox(height: EatSpace.s10),
            if (phone != null)
              AccountCodeField(
                controller: _code,
                phone: phone,
                purpose: AccountCodePurpose.deleteAccount,
                errorText: _codeError,
              )
            else
              EatFormField(
                label: '密码',
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                errorText: _passwordError,
              ),
            const SizedBox(height: 40),
            EatButton.solid(
              '申请注销',
              loading: form.submitting,
              onPressed: ready ? () => _confirm(byCode: phone != null) : null,
            ),
            const SizedBox(height: EatSpace.s24),
          ],
        ),
      ],
    );
  }

  Future<void> _confirm({required bool byCode}) async {
    FocusScope.of(context).unfocus();
    final deleteComments = ref.read(deleteAccountProvider).deleteComments;
    final confirmed = await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        title: '注销账号？',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '取消',
                onPressed: () => Navigator.of(dialog).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '注销',
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
            ),
          ],
        ),
        subtitle: deleteComments
            ? '7 天内在这台设备上重新登录即撤销。评论和回复将一并删除。'
            : '7 天内在这台设备上重新登录即撤销。',
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _codeError = _passwordError = null);
    final notifier = ref.read(deleteAccountProvider.notifier);
    final submitted = await notifier.submit(
      code: byCode ? _code.text : null,
      password: byCode ? null : _password.text,
    );
    if (submitted) {
      // 需在退出登录前弹出轻提示: 退出操作会关闭当前页面, 而挂在根浮层上的提示仍可继续显示.
      if (mounted) showToast(context, '已申请注销，7 天内在这台设备上登录可以撤销');
      await notifier.leave();
      return;
    }
    if (!mounted) return;
    final failure = ref.read(deleteAccountProvider).failure;
    if (failure == null || failure.kind == FailureKind.cancelled) return;
    switch (failure.code) {
      case BizCodes.wrongCode:
        setState(() => _codeError = failure.message);
      case BizCodes.wrongPassword:
        setState(() => _passwordError = '密码错误，请重新输入');
      default:
        showToast(
          context,
          failure.kind == FailureKind.unknown ? '申请失败，请重试' : failure.message,
        );
    }
  }
}
