import 'dart:async';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/platform/external_maps.dart';
import 'package:eat/core/platform/share.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/features/system/guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "导航去店里".
///
/// - 只有一个可用的地图时直接打开.
/// - 有多个时弹出面板让用户选择.
/// - 未安装地图 App 或在 Web 上时, 可用的只有高德网页版.
Future<void> navigateToShop(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required GcjPoint point,
}) async {
  final maps = ref.read(externalMapsProvider);
  final apps = await maps.available(lat: point.lat, lng: point.lng, name: name);
  if (!context.mounted) return;
  if (apps.length == 1) {
    if (!await maps.open(apps.single) && context.mounted) {
      showToast(context, '无法打开地图，请重试');
    }
    return;
  }
  final picked = await showPanel<MapApp>(
    context,
    builder: (panel) => EatPanel(
      title: '用哪个地图去',
      subtitle: name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EatSpace.s8,
        children: [
          for (final app in apps)
            _PanelRow(
              icon: EatIcons.navigate,
              label: app.name,
              onTap: () => Navigator.of(panel).pop(app),
            ),
        ],
      ),
    ),
  );
  if (picked == null) return;
  if (!await maps.open(picked) && context.mounted) {
    showToast(context, '无法打开地图，请重试');
  }
}

// TODO: 举报没有接口, 入口带 "待接入". 接口上线后接入并去掉标记.
/// 分享面板: 分享渠道和 "复制链接". [reportable] 为 true 时末尾增加 "举报".
Future<void> showSharePanel(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required String title,
  bool reportable = false,
}) async {
  final base = ref.read(appConfigProvider).webBaseUrl;
  final link = Uri.parse(base.isEmpty ? path : '$base$path');
  final sharer = ref.read(linkSharerProvider);
  void report(ShareOutcome outcome) {
    if (!context.mounted) return;
    switch (outcome) {
      case ShareOutcome.copied:
        showToast(context, '链接已复制');
      case ShareOutcome.failed:
        showToast(context, '分享失败，请重试');
      case ShareOutcome.shared:
    }
  }

  await showPanel<void>(
    context,
    builder: (panel) => EatPanel(
      title: '分享',
      subtitle: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EatSpace.s8,
        children: [
          _PanelRow(
            icon: EatIcons.share,
            label: '分享给朋友',
            onTap: () {
              Navigator.of(panel).pop();
              unawaited(sharer.share(link, title: title).then(report));
            },
          ),
          _PanelRow(
            icon: EatIcons.link,
            label: '复制链接',
            onTap: () {
              Navigator.of(panel).pop();
              unawaited(sharer.copy(link).then(report));
            },
          ),
          if (reportable)
            _PanelRow(
              icon: EatIcons.report,
              label: '举报',
              pending: true,
              onTap: () => showPending(panel, PendingFeature.report),
            ),
        ],
      ),
    ),
  );
}

class _PanelRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    this.pending = false,
  });

  final EatIcons icon;
  final String label;
  final VoidCallback onTap;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return EatListRow(
      leading: Container(
        width: EatSize.touch,
        height: EatSize.touch,
        decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
        child: Center(child: EatIcon(icon, size: 20, color: c.ink)),
      ),
      title: Row(
        spacing: EatSpace.s8,
        children: [Text(label), if (pending) const PendingTag()],
      ),
      onTap: onTap,
    );
  }
}
