import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/profile/widgets/follow_button.dart';
import 'package:eat/features/profile/widgets/profile_stage.dart';
import 'package:eat/features/system/report_panel.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/social.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 他人主页.
///
/// - 舞台: 对方获赞最多的菜, 头像, 昵称和四项统计.
/// - 右上角: 关注按钮 ("关注" "回关" "已关注" "已互关") 和 "更多" (屏蔽, 举报).
/// - 抽屉: 只有 "上传" 一栏. 收藏, 评论, 标签和足迹是私人的.
///
/// 打开当前用户自己的主页时不显示关注和 "更多".
class UserPage extends ConsumerWidget {
  const new({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(
      sessionProvider.select((s) => s is SignedIn ? s.user?.id : null),
    );
    final isMe = me == userId;
    final profileValue = ref.watch(userProfileProvider(userId));
    final profile = profileValue.value;
    final uploads = ref.watch(userUploadsProvider(userId));
    final top = DishRules.signatures(
      uploads.value?.pages.items ?? const <Dish>[],
      count: 1,
    ).firstOrNull;
    final blocked = isMe
        ? false
        : ref.watch(blockStateProvider(userId)).value ?? false;
    if (profile == null && profileValue.hasError && !profileValue.isLoading) {
      return StageScaffold(
        stage: StageColor.mango,
        topBar: const Row(children: [EatBackButton()]),
        stageContent: const SizedBox(),
        sheetSlivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: EatSpace.s20,
              vertical: EatSpace.s24,
            ),
            sliver: SliverToBoxAdapter(
              child: FailureState(
                message: (profileValue.error as AppFailure?)?.message,
                onRetry: () => ref.invalidate(userProfileProvider(userId)),
              ),
            ),
          ),
        ],
      );
    }
    return StageScaffold(
      stage: top?.stage ?? StageColor.mango,
      topBar: Row(
        children: [
          const EatBackButton(),
          const Spacer(),
          if (!isMe && profile != null) ...[
            FollowButton(profile: profile, onStage: true),
            EatIconButton(
              EatIcons.more,
              label: '更多',
              onPressed: () => _showMore(context, ref, profile, blocked),
            ),
          ],
        ],
      ),
      stageContent: ProfileStage(
        userId: userId,
        name: profile?.nickname ?? '',
        avatarUrl: profile?.avatarUrl,
        profile: profile,
        top: top,
        loading: uploads.isLoading,
      ),
      sheetSlivers: [
        if (blocked)
          SliverToBoxAdapter(
            child: StageNotice(
              icon: EatIcons.block,
              text: '你已屏蔽对方',
              action: EatButton.mist(
                '解除屏蔽',
                height: 36,
                onPressed: () => _setBlocked(context, ref, blocked: false),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: EatTabs(
            tabs: [EatTabItem('上传', count: profile?.uploadedDishes)],
            selected: 0,
            onSelected: (_) {},
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: DishGridSliver(
            value: uploads,
            onRetry: () => ref.invalidate(userUploadsProvider(userId)),
            onLoadMore: () =>
                ref.read(userUploadsProvider(userId).notifier).loadMore(),
            empty: const EmptyState(
              icon: EatIcons.bowl,
              title: '还没发布过菜',
              message: '对方发布的菜会出现在这里。',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showMore(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    bool blocked,
  ) async {
    final action = await showPanel<_MoreAction>(
      context,
      builder: (panel) => EatPanel(
        title: profile.nickname,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: EatSpace.s8,
          children: [
            EatListRow(
              leading: EatIcon(
                EatIcons.block,
                size: 22,
                color: panel.eat.colors.ink,
              ),
              title: Text(blocked ? '解除屏蔽' : '屏蔽'),
              onTap: () => Navigator.of(panel).pop(_MoreAction.block),
            ),
            EatListRow(
              leading: EatIcon(
                EatIcons.report,
                size: 22,
                color: panel.eat.colors.ink,
              ),
              title: const Text('举报'),
              onTap: () => Navigator.of(panel).pop(_MoreAction.report),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _MoreAction.block when blocked:
        await _setBlocked(context, ref, blocked: false);
      case _MoreAction.block:
        if (await _confirmBlock(context, profile.nickname) && context.mounted) {
          await _setBlocked(context, ref, blocked: true);
        }
      case _MoreAction.report:
        await showReportPanel(context, ref, ReportTarget.user(userId));
      case null:
    }
  }

  Future<bool> _confirmBlock(BuildContext context, String name) async =>
      await showPanel<bool>(
        context,
        builder: (panel) => EatPanel(
          title: '屏蔽「$name」？',
          actions: Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(
                child: EatButton.mist(
                  '先不屏蔽',
                  onPressed: () => Navigator.of(panel).pop(false),
                ),
              ),
              Expanded(
                child: EatButton.solid(
                  '屏蔽',
                  onPressed: () => Navigator.of(panel).pop(true),
                ),
              ),
            ],
          ),
          child: Text(
            '屏蔽后，对方的评论和回复对你隐藏，对方的赞、评论和关注不再通知你，'
            '对方也不能关注你，已有的关注关系会解除。'
            '对方上传的菜不会出现在你的转盘里。可以在设置 → 隐私里解除。',
            style: panel.eat.text.body.copyWith(
              fontSize: 14,
              height: 22 / 14,
              color: panel.eat.colors.inkSoft,
            ),
          ),
        ),
      ) ==
      true;

  Future<void> _setBlocked(
    BuildContext context,
    WidgetRef ref, {
    required bool blocked,
  }) async {
    try {
      await ref.read(blockStateProvider(userId).notifier).set(blocked: blocked);
      if (context.mounted) showToast(context, blocked ? '已屏蔽' : '已解除屏蔽');
    } on AppFailure catch (e) {
      if (context.mounted) {
        showToast(
          context,
          e.kind == FailureKind.unknown
              ? (blocked ? '屏蔽失败，请重试' : '解除屏蔽失败，请重试')
              : e.message,
        );
      }
    }
  }
}

enum _MoreAction { block, report }
