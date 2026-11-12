import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 隐私页面: 是否公开关注和粉丝列表, 个性化推荐开关, 屏蔽的人.
///
/// 点击开关后立即更新显示, 保存失败时恢复原值并提示.
/// 个性化推荐开关标为待接入, 显示默认的开启状态, 不读取也不保存.
class PrivacyPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = ref.watch(privacyProvider);
    Future<bool> allowed() =>
        guardAction(context, ref, Capability.changePrivacy);
    void report(AppFailure? failure) {
      if (failure == null || !context.mounted) return;
      showToast(
        context,
        failure.kind == FailureKind.unknown ? '保存失败，请重试' : failure.message,
      );
    }

    Widget loading(AsyncValue<Object> value, VoidCallback retry) =>
        value.hasError && !value.isLoading
        ? FailureState(
            message: (value.error as AppFailure?)?.message,
            onRetry: retry,
          )
        : const RowListPlaceholder(count: 2);

    return PlainScaffold(
      title: '隐私',
      slivers: [
        SliverList.list(
          children: [
            const ListGroupTitle('别人能看到什么'),
            if (privacy.value case final settings?) ...[
              EatSwitch(
                label: '公开我的关注列表',
                description: '关闭后他人查看时将显示「对方未公开」',
                value: settings.followingsPublic,
                onChanged: (on) async => report(
                  !await allowed()
                      ? null
                      : await ref
                            .read(privacyProvider.notifier)
                            .set(
                              PrivacySettings(
                                followingsPublic: on,
                                fansPublic: settings.fansPublic,
                              ),
                            ),
                ),
              ),
              EatSwitch(
                label: '公开我的粉丝列表',
                description: '关闭后他人查看时将显示「对方未公开」',
                value: settings.fansPublic,
                onChanged: (on) async => report(
                  !await allowed()
                      ? null
                      : await ref
                            .read(privacyProvider.notifier)
                            .set(
                              PrivacySettings(
                                followingsPublic: settings.followingsPublic,
                                fansPublic: on,
                              ),
                            ),
                ),
              ),
            ] else
              loading(privacy, () => ref.invalidate(privacyProvider)),
            const SizedBox(height: 18),
            const ListGroupTitle('推荐'),
            // TODO: 后端 v2 删除了个性化推荐开关的接口, 开关标为待接入. 后端恢复接口后改回读取和保存 personalizedProvider.
            EatSwitch(
              label: '个性化推荐',
              description: '结合你的点赞与收藏为你推荐。关闭后仅按大众口碑推荐',
              value: true,
              onChanged: (_) =>
                  showPending(context, PendingFeature.personalizedRecommend),
              pending: true,
            ),
            const SizedBox(height: 18),
            const ListGroupTitle('屏蔽'),
            SettingsRow(
              icon: EatIcons.block,
              label: '屏蔽的人',
              onTap: () => context.push(Paths.settingsBlocked),
            ),
            const SizedBox(height: EatSpace.s24),
          ],
        ),
      ],
    );
  }
}
