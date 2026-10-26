import 'package:eat/core/platform/app_info.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 设置（`G-Settings`）：头像和昵称、各个子页，最下面「退出登录」。
///
/// 隐私和通知两页放在后面的阶段做（开发计划阶段六），现在不列入口。
class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user,
      SignedOut() => null,
    };
    final version = ref.watch(appVersionProvider).value;
    return PlainScaffold(
      title: '设置',
      slivers: [
        SliverToBoxAdapter(child: _Profile(user: user)),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s20)),
        SliverList.list(
          children: [
            SettingsRow(
              icon: EatIcons.shield,
              label: '账号与安全',
              onTap: () => context.push(Paths.settingsAccount),
            ),
            SettingsRow(
              icon: EatIcons.info,
              label: '关于与反馈',
              value: version,
              numericValue: true,
              onTap: () => context.push(Paths.settingsAbout),
            ),
          ],
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
    final confirmed = await showPanel<bool>(
      context,
      builder: (panel) => EatPanel(
        title: '退出登录？',
        actions: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: EatSpace.s10,
          children: [
            EatButton.solid(
              '退出',
              onPressed: () => Navigator.of(panel).pop(true),
            ),
            EatButton.mist(
              '先不退',
              onPressed: () => Navigator.of(panel).pop(false),
            ),
          ],
        ),
        child: Text(
          '这台设备上的登录信息和个人数据会清掉，你的账号和内容都还在，用手机号再登录就行。',
          style: panel.eat.text.body.copyWith(
            fontSize: 14,
            height: 22 / 14,
            color: panel.eat.colors.inkSoft,
          ),
        ),
      ),
    );
    // 清掉登录态后守卫会把页面带到登录页。
    if (confirmed == true) await ref.read(sessionProvider.notifier).logout();
  }
}

/// 头像、昵称和认证状态。编辑资料在阶段六接上，现在不能点。
class _Profile extends StatelessWidget {
  const new({required this.user});

  final CurrentUser? user;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final user = this.user;
    final name = user?.nickname ?? '同学';
    final avatar = user?.avatarUrl;
    final verified = user?.verified ?? false;
    return MergeSemantics(
      child: Row(
        spacing: EatSpace.s14,
        children: [
          EatAvatar(
            name: name,
            color: StageColor.mango,
            image: avatar == null ? null : NetworkImage(avatar),
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
                  style: eat.text.rowTitle.copyWith(fontSize: 18, color: c.ink),
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
        ],
      ),
    );
  }
}
