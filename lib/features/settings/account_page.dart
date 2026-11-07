import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/account_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// TODO: 后端注销流程未完成, 注销账号一行带 "待接入" 标记. 后端完成后接入注销流程并移除标记.
/// 账号与安全页面: 学生认证, 手机号, 用户名, 密码, 登录设备和注销账号.
///
/// - 未设置用户名时可点击进入设置. 设置后只显示, 不可修改.
/// - 未设置密码时显示 "设置密码", 已设置时显示 "修改密码".
class AccountPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user,
      SignedOut() || Guest() => null,
    };
    final verified = user?.verified ?? false;
    final method = user?.verifyMethod;
    final phone = user?.phone;
    final username = user?.username;
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
              onTap: () => _open(context, ref, Capability.verify, Paths.verify),
            ),
            const SizedBox(height: 18),
            const ListGroupTitle('登录'),
            SettingsRow(
              icon: EatIcons.phone,
              label: '手机号',
              value: phone == null ? '未绑定' : AccountRules.maskMobile(phone),
              numericValue: phone != null,
              onTap: () => context.push(Paths.settingsPhone),
            ),
            SettingsRow(
              icon: EatIcons.idcard,
              label: username == null ? '设置用户名' : '用户名',
              value: username ?? '未设置',
              onTap: username == null
                  ? () => _open(
                      context,
                      ref,
                      Capability.setUsername,
                      Paths.settingsUsername,
                    )
                  : null,
            ),
            SettingsRow(
              icon: EatIcons.key,
              label: hasPassword ? '修改密码' : '设置密码',
              value: hasPassword ? null : '未设置',
              onTap: () => _open(
                context,
                ref,
                Capability.changePassword,
                Paths.settingsPassword,
              ),
            ),
            SettingsRow(
              icon: EatIcons.computer,
              label: '登录设备',
              onTap: () => context.push(Paths.settingsDevices),
            ),
            const SizedBox(height: 18),
            const ListGroupTitle('账号'),
            SettingsRow(
              icon: EatIcons.delete,
              label: '注销账号',
              pending: true,
              onTap: () => context.push(Paths.settingsDelete),
            ),
            const SizedBox(height: EatSpace.s24),
          ],
        ),
      ],
    );
  }
}

/// 按账号状态检查后打开 [path]. 封禁中时弹出拦截面板.
Future<void> _open(
  BuildContext context,
  WidgetRef ref,
  Capability capability,
  String path,
) async {
  if (await guardAction(context, ref, capability) && context.mounted) {
    await context.push(path);
  }
}
