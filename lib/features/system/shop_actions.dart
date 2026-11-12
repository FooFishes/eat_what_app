import 'dart:async';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/external_maps.dart';
import 'package:eat/core/platform/share.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/features/system/report_panel.dart';
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
            EatPanelAction(
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

/// 加菜前检查店铺是否营业. 已关门时显示提示并返回 false.
///
/// 服务端不拒绝给已关门的店加菜, 由客户端拦截.
bool ensureShopOpen(BuildContext context, Shop shop) {
  if (!shop.closed) return true;
  showToast(context, '这家店已关门，不能加菜');
  return false;
}

/// 分享面板: 分享渠道和 "复制链接". 传入 [reportTarget] 时末尾增加 "举报".
///
/// 点击 "举报" 时关闭分享面板后打开举报面板, 不在面板上叠加面板.
Future<void> showSharePanel(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required String title,
  ReportTarget? reportTarget,
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

  final reporting = await showPanel<bool>(
    context,
    builder: (panel) => EatPanel(
      title: '分享',
      subtitle: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EatSpace.s8,
        children: [
          EatPanelAction(
            icon: EatIcons.share,
            label: '分享给朋友',
            onTap: () {
              Navigator.of(panel).pop();
              unawaited(sharer.share(link, title: title).then(report));
            },
          ),
          EatPanelAction(
            icon: EatIcons.link,
            label: '复制链接',
            onTap: () {
              Navigator.of(panel).pop();
              unawaited(sharer.copy(link).then(report));
            },
          ),
          if (reportTarget != null)
            EatPanelAction(
              icon: EatIcons.report,
              label: '举报',
              onTap: () => Navigator.of(panel).pop(true),
            ),
        ],
      ),
    ),
  );
  if (reporting == true && reportTarget != null && context.mounted) {
    await showReportPanel(context, ref, reportTarget);
  }
}
