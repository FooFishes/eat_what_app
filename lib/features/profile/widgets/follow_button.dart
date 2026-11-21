import 'package:eat/core/failure/messages.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/state/social.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 展示并切换用户关注状态的按钮; 未关注时显示实心 "关注" 或 "回关", 已关注时显示次要样式的 "已关注" 或 "已互关", 点击可取消关注.
///
/// 关注操作要求账号已认证, 取消关注则不要求认证; 当 [onStage] 为 true 时采用舞台专用按钮样式.
/// 若任一方已屏蔽对方, 服务端会拒绝关注请求, 此时提示 "无法关注对方".
///
/// [followedByMe] 和 [followsMe] 是服务端给的关系, 点击后的变化记在 [Follows] 里, 调用方不用更新.
class FollowButton extends ConsumerWidget {
  const new({
    super.key,
    required this.userId,
    required this.followedByMe,
    required this.followsMe,
    this.onStage = false,
  });

  /// 取 [profile] 里的关注关系.
  FollowButton.of(UserProfile profile, {Key? key, bool onStage = false})
    : this(
        key: key,
        userId: profile.id,
        followedByMe: profile.followedByMe,
        followsMe: profile.followsMe,
        onStage: onStage,
      );

  final int userId;
  final bool followedByMe;
  final bool followsMe;
  final bool onStage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(followsProvider.select((m) => m[userId]));
    final state = ref
        .read(followsProvider.notifier)
        .stateOf(userId, followedByMe: followedByMe, followsMe: followsMe);
    Future<void> onPressed() async {
      final following = !state.followedByMe;
      final capability = following ? Capability.follow : Capability.unfollow;
      if (!await guardAction(context, ref, capability)) return;
      final failure = await ref
          .read(followsProvider.notifier)
          .set(userId, following: following);
      if (failure == null || !context.mounted) return;
      if (following && failure.code == BizCodes.stateNotAllowed) {
        showToast(context, failure.userMessage ?? '无法关注对方');
      } else {
        await reportActionFailure(
          context,
          ref,
          failure,
          capability: capability,
          fallback: following ? '关注失败，请重试' : '取消关注失败，请重试',
        );
      }
    }

    const height = 36.0;
    if (onStage) {
      return state.followedByMe
          ? EatButton.stageGhost(
              state.label,
              height: height,
              onPressed: onPressed,
            )
          : EatButton.stageSolid(
              state.label,
              icon: EatIcons.follow,
              height: height,
              onPressed: onPressed,
            );
    }
    return state.followedByMe
        ? EatButton.mist(state.label, height: height, onPressed: onPressed)
        : EatButton.solid(state.label, height: height, onPressed: onPressed);
  }
}
