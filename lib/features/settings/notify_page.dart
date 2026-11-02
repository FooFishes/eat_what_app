import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: 未接入推送 SDK, 设备未登记, 开关只保存到服务端, 设备收不到推送. 选定推送 SDK 后登记设备, 并在系统通知关闭时提示用户开启.
/// 通知页面: 各类消息是否推送, 以及免打扰时段. 点击开关后立即更新显示, 保存失败时恢复原值并提示.
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
      subtitle: '只告诉你和你有关的事，不推饭点提醒和活动',
      slivers: [
        SliverList.list(
          children: [
            const ListGroupTitle('推送哪些'),
            if (settings == null)
              value.hasError && !value.isLoading
                  ? FailureState(
                      message: (value.error as AppFailure?)?.message,
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
