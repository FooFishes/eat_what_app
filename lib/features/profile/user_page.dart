import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
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

/// 展示其他用户个人主页的页面.
///
/// - 舞台区域展示对方获赞最多的菜品, 头像, 昵称, 签名及三项统计.
/// - 右上角提供关注按钮 ("关注", "回关", "已关注", "已互关") 和 "更多" 菜单 (屏蔽, 举报).
/// - 抽屉区域仅包含 "上传" 一栏, 因为收藏, 评论, 标签和足迹属于私有内容.
///
/// 打开当前用户自己的主页时不显示关注按钮和 "更多" 菜单.
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
    final top = DishRules.mostLiked(
      uploads.value?.pages.items ?? const <Dish>[],
      count: 1,
    ).firstOrNull;
    final blocked = isMe
        ? false
        : ref.watch(blockStateProvider(userId)).value ?? false;
    if (profile == null && profileValue.hasError && !profileValue.isLoading) {
      final error = profileValue.error;
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
              child: isMissingUser(error)
                  ? const EmptyState(icon: EatIcons.me, title: '该用户不存在')
                  : FailureState(
                      message: (error as AppFailure?)?.message,
                      onRetry: () =>
                          ref.invalidate(userProfileProvider(userId)),
                    ),
            ),
          ),
        ],
      );
    }
    return StageScaffold(
      stage: top?.stage ?? StageColor.mango,
      onRefresh: () async {
        ref.invalidate(userUploadsProvider(userId));
        ref.invalidate(userProfileProvider(userId));
        try {
          await ref.read(userProfileProvider(userId).future);
        } on AppFailure catch (e) {
          if (context.mounted) showToast(context, e.message);
        }
      },
      topBar: Row(
        children: [
          const EatBackButton(),
          Expanded(child: StageBarTitle(profile?.nickname ?? '')),
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
        signature: profile?.signature,
        profile: profile,
        uploads: uploads.value?.pages.total,
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
            tabs: [EatTabItem('上传', count: uploads.value?.pages.total)],
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
            EatPanelAction(
              icon: EatIcons.block,
              label: blocked ? '解除屏蔽' : '屏蔽',
              onTap: () => Navigator.of(panel).pop(_MoreAction.block),
            ),
            EatPanelAction(
              icon: EatIcons.report,
              label: '举报',
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
      await showEatDialog<bool>(
        context,
        builder: (dialog) => EatDialog(
          title: '屏蔽「$name」？',
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
                  '屏蔽',
                  onPressed: () => Navigator.of(dialog).pop(true),
                ),
              ),
            ],
          ),
          subtitle:
              '屏蔽后，你将看不到对方的评论、回复与上传的菜，也不会收到对方的互动通知。'
              '双方已有关注关系将解除，对方也无法再关注你。可在「设置 → 隐私」中解除屏蔽。',
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
