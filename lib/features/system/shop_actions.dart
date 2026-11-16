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

/// 发起店铺位置导航.
///
/// 仅有一个可用地图应用时立即唤起, 存在多个可用应用时弹出选择面板.
/// 未安装本地地图应用或处于 Web 环境时仅提供高德网页版.
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

/// 加菜前校验店铺是否处于营业状态, 若已关门则弹出提示并返回 false.
///
/// 由于服务端不拦截针对已关门店铺的加菜请求, 需由客户端负责阻止.
bool ensureShopOpen(BuildContext context, Shop shop) {
  if (!shop.closed) return true;
  showToast(context, '这家店已关门，不能加菜');
  return false;
}

/// 打开分享面板, 提供系统分享与 "复制链接" 操作, 传入 [reportTarget] 时在末尾追加 "举报" 入口.
///
/// 选择 "举报" 时先关闭分享面板再打开举报面板, 避免双层面板叠加.
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
