import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 隐私页面: 是否公开关注和粉丝列表, 个性化推荐开关, 屏蔽的人.
///
/// 点击开关后立即更新显示, 保存失败时恢复原值并提示.
class PrivacyPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = ref.watch(privacyProvider);
    // 受限会话不能读写推荐设置. 封禁中不请求推荐设置, 点击开关时弹出拦截对话框.
    final banned = ref.watch(accountStatusProvider) is BannedStatus;
    final personalized = banned ? null : ref.watch(personalizedProvider);
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
                description: '关掉后别人点开，看到的是「对方未公开」',
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
                description: '关掉后别人点开，看到的是「对方未公开」',
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
            if (personalized == null)
              SettingsRow(
                icon: EatIcons.discover,
                label: '个性化推荐',
                onTap: allowed,
              )
            else if (personalized.value case final on?)
              EatSwitch(
                label: '个性化推荐',
                description: '参考你赞过、收藏过的菜。关掉后推荐只看大家公认的好菜',
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
