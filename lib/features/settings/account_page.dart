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

/// 账号与安全（`G-SettingsAccount`）：认证状态和入口，手机号、用户名、密码的现状。
///
/// 设置用户名、换绑手机、设置或修改密码在阶段六接上，现在只显示；登录设备和注销还没有接口，
/// 带「待接入」。
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
              value: user?.username ?? '还没设',
            ),
            SettingsRow(
              icon: EatIcons.key,
              label: hasPassword ? '修改密码' : '设置密码',
              value: hasPassword ? null : '还没设',
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
