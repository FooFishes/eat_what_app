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

/// 隐私设置页面, 包含关注与粉丝列表公开控制, 个性化推荐开关和推荐偏好入口, 使用统计开关及屏蔽列表入口.
///
/// 切换开关后立即更新界面状态, 若保存失败则回滚至原值并弹出提示; 其中使用统计开关对封禁中账号同样开放, 不经过权限拦截.
class PrivacyPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = ref.watch(privacyProvider);
    final personalized = ref.watch(personalizedProvider);
    final usage = ref.watch(usageStatsSettingProvider);
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
        ? FailureState(error: value.error, onRetry: retry)
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
            if (personalized.value case final on?)
              EatSwitch(
                label: '个性化推荐',
                description: '结合你的点赞与收藏为你推荐。关闭后仅按大众口碑推荐',
                value: on,
                onChanged: (on) async => report(
                  !await allowed()
                      ? null
                      : await ref
                            .read(personalizedProvider.notifier)
                            .set(personalized: on),
                ),
              )
            else
              loading(personalized, () => ref.invalidate(personalizedProvider)),
            SettingsRow(
              icon: EatIcons.filter,
              label: '推荐偏好',
              onTap: () => context.push(Paths.settingsPreferences),
            ),
            const SizedBox(height: 18),
            const ListGroupTitle('使用统计'),
            if (usage.value case final stats?)
              EatSwitch(
                label: '使用统计',
                description: [
                  '记录你用了哪些功能，用来改进体验',
                  if (stats.retentionDays case final days?) '保存 $days 天',
                  '关闭后删除已收集的记录',
                ].join('，'),
                value: stats.enabled,
                onChanged: (on) async => report(
                  await ref
                      .read(usageStatsSettingProvider.notifier)
                      .set(enabled: on),
                ),
              )
            else
              loading(usage, () => ref.invalidate(usageStatsSettingProvider)),
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
