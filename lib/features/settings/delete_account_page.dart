import 'package:eat/core/env/pending_features.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: 注销账号没有接口, 点击按钮只提示 "待接入", 不发送请求. 接口上线后接入并移除标记.
/// 注销账号: 说明删除和保留的内容以及冷静期, 并用手机验证码确认身份.
class DeleteAccountPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final phone = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user?.phone,
      SignedOut() => null,
    };
    final body = eat.text.body.copyWith(
      fontSize: 15,
      height: 24 / 15,
      color: c.ink,
    );
    Widget section(String title, String text) => Padding(
      padding: const EdgeInsets.only(bottom: EatSpace.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(title, style: eat.text.rowTitle.copyWith(color: c.ink)),
          Text(text, style: body),
        ],
      ),
    );
    void pending() => showPending(context, PendingFeature.deleteAccount);
    return PlainScaffold(
      title: '注销账号',
      slivers: [
        SliverList.list(
          children: [
            const Align(alignment: Alignment.centerLeft, child: PendingTag()),
            const SizedBox(height: EatSpace.s14),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '申请后有 '),
                  TextSpan(text: '7', style: eat.text.count),
                  const TextSpan(text: ' 天冷静期，这期间账号不能用，重新登录就能撤销；'),
                  TextSpan(text: '7', style: eat.text.count),
                  const TextSpan(text: ' 天后彻底删除。'),
                ],
              ),
              style: body,
            ),
            const SizedBox(height: EatSpace.s20),
            section(
              '会删除',
              '资料、认证信息、收藏、我的标签、足迹、评论和回复、关注关系、屏蔽列表。'
                  '你给别人的赞、口味标签和店铺评价也会从计数里去掉。',
            ),
            section('会保留', '你上传的菜和新建的店，它们是店铺菜单的一部分。上传者会显示「已注销用户」。'),
            section('之后', '这个手机号可以重新注册，用过的统一认证和邮箱也能给新账号认证。'),
            EatFormField(
              label: phone == null
                  ? '先确认是你本人'
                  : '先确认是你本人，验证码发到 ${AccountRules.maskMobile(phone)}',
              hintText: '6 位数字',
              numeric: true,
              trailing: EatButton.mist('获取验证码', height: 36, onPressed: pending),
            ),
            const SizedBox(height: 40),
            EatButton.solid('申请注销', onPressed: pending),
            const SizedBox(height: EatSpace.s24),
          ],
        ),
      ],
    );
  }
}
