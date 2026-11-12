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

/// 关注按钮. 未关注时为实心 "关注" 或 "回关", 已关注时为次要样式的 "已关注" 或 "已互关", 点击取消关注.
///
/// 关注要求已认证, 取消关注不要求认证. [onStage] 为 true 时使用舞台上的按钮样式.
///
/// 任一方屏蔽了对方时服务端拒绝关注, 提示 "无法关注对方".
class FollowButton extends ConsumerWidget {
  const new({super.key, required this.profile, this.onStage = false});

  final UserProfile profile;
  final bool onStage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(followsProvider.select((m) => m[profile.id]));
    final state = ref.read(followsProvider.notifier).stateOf(profile);
    Future<void> onPressed() async {
      final following = !state.followedByMe;
      final capability = following ? Capability.follow : Capability.unfollow;
      if (!await guardAction(context, ref, capability)) return;
      final failure = await ref
          .read(followsProvider.notifier)
          .set(profile.id, following: following);
      if (failure == null || !context.mounted) return;
      if (following && failure.code == BizCodes.stateNotAllowed) {
        showToast(context, '无法关注对方');
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
