import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// TODO: 登录设备和注销账号没有接口, 入口带 "待接入". 接口上线后接入并去掉标记.
// TODO: 换绑手机和设置用户名未实现, 对应行只显示当前值, 不可点. 实现对应页面后改为可点并跳转.
// TODO: 设置或修改密码未实现, 该行带 "待接入". 实现密码页面后改为可点并去掉标记.
/// 账号与安全页面: 学生认证状态和入口, 以及手机号, 用户名, 密码的当前状态.
class AccountPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user,
      SignedOut() => null,
    };
    final verified = user?.verified ?? false;
    final method = user?.verifyMethod;
    final phone = user?.phone;
    final hasPassword = user?.hasPassword ?? false;
    return PlainScaffold(
      title: '账号与安全',
      slivers: [
        SliverList.list(
          children: [
            const ListGroupTitle('身份'),
            SettingsRow(
              icon: EatIcons.verify,
              label: '学生认证',
              value: verified ? ['已认证', ?method?.label].join('，') : '未认证',
              onTap: () => context.push(Paths.verify),
            ),
            const SizedBox(height: 18),
            const ListGroupTitle('登录'),
            SettingsRow(
              icon: EatIcons.phone,
              label: '手机号',
              value: phone == null ? '未绑定' : AccountRules.maskMobile(phone),
              numericValue: phone != null,
            ),
            SettingsRow(
              icon: EatIcons.idcard,
              label: '用户名',
              value: user?.username ?? '未设置',
            ),
            SettingsRow(
              icon: EatIcons.key,
              label: hasPassword ? '修改密码' : '设置密码',
              value: hasPassword ? null : '未设置',
              pending: true,
            ),
            const SettingsRow(
              icon: EatIcons.computer,
              label: '登录设备',
              pending: true,
            ),
            const SizedBox(height: 18),
            const ListGroupTitle('账号'),
            const SettingsRow(
              icon: EatIcons.delete,
              label: '注销账号',
              pending: true,
            ),
            const SizedBox(height: EatSpace.s24),
          ],
        ),
      ],
    );
  }
}
