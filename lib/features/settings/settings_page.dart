import 'package:eat/core/platform/app_info.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/settings/widgets/settings_group.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 设置页, 展示头像与昵称 (点击进入编辑资料), 各子页面入口以及底部的 "退出登录" 按钮.
///
/// 游客模式下仅显示 "个性化" 和 "关于与反馈" 两项.
class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final version = ref.watch(appVersionProvider).value;
    final personalize = SettingsRow(
      icon: EatIcons.eye,
      label: '个性化',
      onTap: () => context.push(Paths.settingsPersonalize),
    );
    final about = SettingsRow(
      icon: EatIcons.info,
      label: '关于与反馈',
      value: version,
      numericValue: true,
      onTap: () => context.push(Paths.settingsAbout),
    );
    final user = switch (session) {
      SignedIn(:final user) => user,
      SignedOut() || Guest() => null,
    };
    if (session is! SignedIn) {
      return PlainScaffold(
        title: '设置',
        slivers: [
          SliverToBoxAdapter(
            child: SettingsGroup(children: [personalize, about]),
          ),
        ],
      );
    }
    return PlainScaffold(
      title: '设置',
      slivers: [
        SliverToBoxAdapter(
          child: SettingsGroup(
            children: [
              _Profile(
                user: user,
                onTap: () async {
                  if (await guardAction(context, ref, Capability.editProfile) &&
                      context.mounted) {
                    await context.push(Paths.meEdit);
                  }
                },
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s20)),
        SliverToBoxAdapter(
          child: SettingsGroup(
            children: [
              SettingsRow(
                icon: EatIcons.shield,
                label: '账号与安全',
                onTap: () => context.push(Paths.settingsAccount),
              ),
              SettingsRow(
                icon: EatIcons.lock,
                label: '隐私',
                onTap: () => context.push(Paths.settingsPrivacy),
              ),
              SettingsRow(
                icon: EatIcons.bell,
                label: '通知',
                onTap: () => context.push(Paths.settingsNotify),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s20)),
        SliverToBoxAdapter(
          child: SettingsGroup(children: [personalize, about]),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        SliverToBoxAdapter(
          child: EatButton.mist(
            '退出登录',
            icon: EatIcons.logout,
            onPressed: () => _confirmLogout(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        title: '退出登录？',
        actions: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: EatSpace.s10,
          children: [
            EatButton.solid(
              '退出',
              onPressed: () => Navigator.of(dialog).pop(true),
            ),
            EatButton.mist(
              '取消',
              onPressed: () => Navigator.of(dialog).pop(false),
            ),
          ],
        ),
        subtitle: '将清除本设备上的登录状态和本地缓存，账号与云端内容不受影响，可重新登录。',
      ),
    );
    // 登录态清除后, 路由守卫负责跳转到登录页.
    if (confirmed == true) await ref.read(sessionProvider.notifier).logout();
  }
}

/// 展示用户头像, 昵称与认证状态, 点击进入编辑资料.
class _Profile extends StatelessWidget {
  const new({required this.user, required this.onTap});

  final CurrentUser? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final user = this.user;
    final name = user?.nickname ?? '同学';
    final avatar = user?.avatarUrl;
    final verified = user?.verified ?? false;
    return EatTappable(
      onTap: onTap,
      button: false,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: EatSpace.s14),
        child: Row(
          spacing: EatSpace.s14,
          children: [
            EatAvatar(
              name: name,
              color:
                  StageColor.values[(user?.id ?? 0) % StageColor.values.length],
              image: networkImage(avatar, width: 56),
              size: 56,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: eat.text.heading.copyWith(color: c.ink),
                  ),
                  Row(
                    spacing: 4,
                    children: [
                      if (verified)
                        EatIcon(EatIcons.verify, size: 16, color: c.inkMuted),
                      Text(
                        verified ? '已认证' : '未认证',
                        style: eat.text.meta.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            EatIcon(EatIcons.chevronRight, size: 20, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}
