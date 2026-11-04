import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/device_session.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 登录设备: 已登录的设备和最近使用时间, 可以使单台设备或其他全部设备下线.
///
/// 其他设备全部下线后, 本机的会话换发为新会话, 用户无需重新登录.
/// 未能获取新会话时回到登录页.
class DevicesPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(deviceSessionsProvider);
    final devices = value.value;
    final others = devices?.where((d) => !d.current).length ?? 0;
    return PlainScaffold(
      title: '登录设备',
      subtitle: '看到不认识的设备，先让它下线，再修改密码。',
      slivers: [
        if (devices == null)
          SliverToBoxAdapter(
            child: value.hasError && !value.isLoading
                ? FailureState(
                    message: (value.error as AppFailure?)?.message,
                    onRetry: () => ref.invalidate(deviceSessionsProvider),
                  )
                : const RowListPlaceholder(count: 3, thumbSize: EatSize.avatar),
          )
        else
          SliverList.list(
            children: [
              for (final device in devices) ...[
                _DeviceRow(device: device),
                const SizedBox(height: EatSpace.s16),
              ],
              const SizedBox(height: 12),
              if (others == 0)
                Text(
                  '只有这台设备登录着',
                  textAlign: TextAlign.center,
                  style: context.eat.text.meta.copyWith(
                    color: context.eat.colors.inkMuted,
                  ),
                )
              else
                const _RevokeOthersButton(),
              const SizedBox(height: EatSpace.s24),
            ],
          ),
      ],
    );
  }
}

class _DeviceRow extends ConsumerStatefulWidget {
  const new({required this.device});

  final DeviceSession device;

  @override
  ConsumerState<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends ConsumerState<_DeviceRow> {
  var _busy = false;

  Future<void> _revoke() async {
    setState(() => _busy = true);
    try {
      await ref.read(deviceSessionsProvider.notifier).revoke(widget.device);
      if (mounted) showToast(context, '已下线');
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(
        context,
        e.kind == FailureKind.unknown ? '下线失败，请重试' : e.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final device = widget.device;
    final lastUsed = device.lastUsedAt;
    return EatListRow(
      leading: Container(
        width: EatSize.avatar,
        height: EatSize.avatar,
        decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
        child: Center(
          child: EatIcon(
            device.platform == DevicePlatform.web
                ? EatIcons.computer
                : EatIcons.phone,
            size: 22,
            color: c.ink,
          ),
        ),
      ),
      title: Text(device.platform.label),
      lines: [
        Text(
          device.current
              ? '这台设备，正在用'
              : lastUsed == null
              ? '最近使用时间未知'
              : '${TimeFormat.relative(lastUsed, clock.now())}用过',
        ),
      ],
      action: device.current
          ? null
          : EatButton.mist(
              '下线',
              height: 36,
              loading: _busy,
              onPressed: _revoke,
            ),
    );
  }
}

class _RevokeOthersButton extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_RevokeOthersButton> createState() =>
      _RevokeOthersButtonState();
}

class _RevokeOthersButtonState extends ConsumerState<_RevokeOthersButton> {
  var _busy = false;

  Future<void> _revokeOthers() async {
    final confirmed = await showPanel<bool>(
      context,
      builder: (panel) => EatPanel(
        title: '让其他设备都下线？',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '先不下线',
                onPressed: () => Navigator.of(panel).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '都下线',
                onPressed: () => Navigator.of(panel).pop(true),
              ),
            ),
          ],
        ),
        child: Text(
          '其他设备要重新登录，这台设备不受影响。',
          style: panel.eat.text.body.copyWith(color: panel.eat.colors.inkSoft),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final kept = await ref
          .read(deviceSessionsProvider.notifier)
          .revokeOthers();
      if (mounted) {
        showToast(context, kept ? '其他设备已下线' : '其他设备已下线，请重新登录');
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      showToast(
        context,
        e.kind == FailureKind.unknown ? '下线失败，请重试' : e.message,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      EatButton.mist('让其他设备都下线', loading: _busy, onPressed: _revokeOthers);
}
