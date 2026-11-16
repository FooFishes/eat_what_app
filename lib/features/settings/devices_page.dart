import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/device_session.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 登录设备管理页面, 展示已登录设备及登录时间, 并支持踢出单台设备或其余全部设备.
///
/// 下线其他设备不会影响本机当前会话; 服务端仅记录登录时间, 未记录最近活跃时间.
class DevicesPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(deviceSessionsProvider);
    final devices = value.value;
    final others = devices?.where((d) => !d.current).length ?? 0;
    return PlainScaffold(
      title: '登录设备',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [deviceSessionsProvider],
        wait: () => ref.read(deviceSessionsProvider.future),
      ),
      slivers: [
        if (devices == null)
          SliverToBoxAdapter(
            child: value.hasError && !value.isLoading
                ? FailureState(
                    error: value.error,
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
                  '仅当前设备登录',
                  textAlign: TextAlign.center,
                  style: context.eat.text.meta.copyWith(
                    color: context.eat.colors.inkMuted,
                  ),
                )
              else
                const _RevokeOthersButton(),
              const SizedBox(height: EatSpace.s16),
              Text(
                '发现陌生设备，建议先将其下线，再修改密码。',
                textAlign: TextAlign.center,
                style: context.eat.text.caption.copyWith(
                  color: context.eat.colors.inkMuted,
                ),
              ),
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
      title: Text(device.name ?? device.platform.label),
      lines: [
        if (device.name != null) Text(device.platform.label),
        Text(device.current ? '当前设备' : _timesOf(device)),
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

/// 格式化设备登录与活跃时间 (如 "3 天前登录, 2 小时前用过"), 均缺失时返回 "登录时间未知".
String _timesOf(DeviceSession device) {
  final now = clock.now();
  final times = [
    if (device.signedInAt case final at?) '${TimeFormat.relative(at, now)}登录',
    if (device.lastActiveAt case final at?) '${TimeFormat.relative(at, now)}用过',
  ];
  return times.isEmpty ? '登录时间未知' : times.join('，');
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
    final confirmed = await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        title: '下线其他所有设备？',
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
                '全部下线',
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
            ),
          ],
        ),
        subtitle: '其他设备需要重新登录，当前设备不受影响。',
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(deviceSessionsProvider.notifier).revokeOthers();
      if (mounted) showToast(context, '其他设备已下线');
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
      EatButton.mist('下线其他设备', loading: _busy, onPressed: _revokeOthers);
}
