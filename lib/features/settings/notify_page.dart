import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/client_config.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:eat/features/system/remote_gate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: 尚未接入推送 SDK 且未登记设备, 当前开关状态仅保存至服务端而无法实际推送至设备. 选定推送 SDK 后完成设备登记, 并在系统通知权限关闭时引导用户开启.
/// 通知设置页面, 用于配置各类消息的推送开关并展示免打扰时段; 切换开关后立即更新界面, 若保存失败则回滚状态并弹出提示.
class NotifyPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final note = eat.text.meta.copyWith(color: eat.colors.inkMuted);
    final value = ref.watch(pushSettingsProvider);
    final settings = value.value;
    return PlainScaffold(
      title: '通知',
      slivers: [
        SliverList.list(
          children: [
            const ListGroupTitle('推送哪些'),
            Text('只告诉你和你有关的事，不推饭点提醒和活动', style: note),
            const SizedBox(height: EatSpace.s8),
            if (settings == null)
              value.hasError && !value.isLoading
                  ? FailureState(
                      error: value.error,
                      onRetry: () => ref.invalidate(pushSettingsProvider),
                    )
                  : const RowListPlaceholder(count: 4)
            else
              for (final setting in settings)
                EatSwitch(
                  label: setting.category.label,
                  description: setting.category.description,
                  value: setting.enabled,
                  onChanged: (on) async {
                    if (!guardRemote(
                      context,
                      ref,
                      feature: RemoteFeature.push,
                    )) {
                      return;
                    }
                    final failure = await ref
                        .read(pushSettingsProvider.notifier)
                        .set(setting.category, enabled: on);
                    if (failure != null && context.mounted) {
                      showToast(
                        context,
                        failure.kind == FailureKind.unknown
                            ? '保存失败，请重试'
                            : failure.message,
                      );
                    }
                  },
                ),
            const SizedBox(height: 18),
            const ListGroupTitle('免打扰'),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '23:00–08:00', style: eat.text.count),
                  const TextSpan(text: ' 不推送，这段时间的消息只进消息页。网页版没有推送，消息都在消息页里。'),
                ],
              ),
              style: note,
            ),
            const SizedBox(height: EatSpace.s24),
          ],
        ),
      ],
    );
  }
}
