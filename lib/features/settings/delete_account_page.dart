import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/features/settings/delete_account_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 注销账号: 说明删除和保留的内容以及冷静期, 让用户选择是否同时删除评论和回复.
///
/// 确认后提交申请并退出登录. 冷静期内在这台设备上重新登录可以撤销, 见登录流程的撤销注销页.
class DeleteAccountPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final form = ref.watch(deleteAccountProvider);
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
                  const TextSpan(text: ' 天冷静期，期间账号停用，在当前设备重新登录可撤销；'),
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
                  : '若不删除，内容将保留，作者显示为「已注销用户」',
              value: form.deleteComments,
              onChanged: form.submitting
                  ? null
                  : (value) => ref
                        .read(deleteAccountProvider.notifier)
                        .setDeleteComments(value: value),
            ),
            const SizedBox(height: EatSpace.s20),
            section('之后', '原手机号可重新注册，此前绑定过的统一认证与校园邮箱也可用于新账号认证。'),
            const SizedBox(height: EatSpace.s20),
            EatButton.solid(
              '申请注销',
              loading: form.submitting,
              onPressed: () => _confirm(context, ref),
            ),
            const SizedBox(height: EatSpace.s24),
          ],
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
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
            ? '7 天内在当前设备重新登录可撤销。评论和回复将一并删除。'
            : '7 天内在当前设备重新登录可撤销。',
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final notifier = ref.read(deleteAccountProvider.notifier);
    if (await notifier.submit()) {
      // 先提示再退出登录. 退出后本页关闭, 提示在根浮层上, 仍会显示.
      if (context.mounted) showToast(context, '已申请注销，7 天内重新登录可以撤销');
      await notifier.leave();
      return;
    }
    if (!context.mounted) return;
    final failure = ref.read(deleteAccountProvider).failure;
    if (failure == null || failure.kind == FailureKind.cancelled) return;
    showToast(
      context,
      failure.kind == FailureKind.unknown ? '申请失败，请重试' : failure.message,
    );
  }
}
