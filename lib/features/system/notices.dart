import 'dart:async';

import 'package:eat/core/platform/app_info.dart';
import 'package:eat/core/platform/app_store.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/models/client_config.dart';
import 'package:eat/state/remote_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 在应用根部挂载的远程配置宿主组件.
///
/// - 回到前台时按需重新获取远程配置.
/// - 有未看过的重要公告时在根导航器上弹出 (产品 12.2), 强制更新和停服维护期间不弹出.
///
/// 本组件位于路由之上, 无法通过 `GoRouter.of` 跳转, 因此由外部传入 [openPath] 打开公告中的站内链接.
class RemoteConfigHost extends ConsumerStatefulWidget {
  const new({
    super.key,
    required this.navigatorKey,
    required this.openPath,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final void Function(String location) openPath;
  final Widget child;

  @override
  ConsumerState<RemoteConfigHost> createState() => _RemoteConfigHostState();
}

class _RemoteConfigHostState extends ConsumerState<RemoteConfigHost> {
  late final AppLifecycleListener _lifecycle;
  var _showing = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(ref.read(remoteConfigProvider.notifier).resume()),
    );
    ref.listenManual(importantNoticeProvider, (_, _) => _schedule());
    ref.listenManual(appGateProvider, (_, _) => _schedule());
    _schedule();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// 首帧之后再弹出, 此时根导航器已经可以显示对话框.
  void _schedule() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_show()));

  Future<void> _show() async {
    if (_showing || !mounted) return;
    final notice = ref.read(importantNoticeProvider);
    final gate = ref.read(appGateProvider);
    if (notice == null || gate.forceUpdate || gate.down) return;
    final context = widget.navigatorKey.currentState?.overlay?.context;
    if (context == null || !context.mounted) return;
    _showing = true;
    // 弹出即记为看过. 若关闭时才记录, 用户在对话框打开期间退出 App 会导致下次重复弹出.
    unawaited(ref.read(noticesProvider.notifier).markSeen(notice.id));
    await showNoticeDialog(context, notice, openPath: widget.openPath);
    _showing = false;
    _schedule();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 弹出公告全文. 有链接时提供 "查看详情", 站内路径交给 [openPath], https 地址用浏览器打开.
Future<void> showNoticeDialog(
  BuildContext context,
  Announcement notice, {
  required void Function(String location) openPath,
}) => showEatDialog<void>(
  context,
  builder: (dialog) => _NoticeDialog(notice: notice, openPath: openPath),
);

class _NoticeDialog extends ConsumerWidget {
  const new({required this.notice, required this.openPath});

  final Announcement notice;
  final void Function(String location) openPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final link = notice.linkUrl;
    final important = notice.level == AnnouncementLevel.important;
    final close = EatButton.solid(
      '知道了',
      onPressed: () => Navigator.of(context).pop(),
    );
    return EatDialog(
      icon: EatIcons.announce,
      title: notice.title ?? (important ? '重要公告' : '公告'),
      actions: link == null
          ? close
          : Row(
              spacing: EatSpace.s10,
              children: [
                Expanded(
                  child: EatButton.mist(
                    '知道了',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: EatButton.solid(
                    '查看详情',
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openLink(ref, link, openPath);
                    },
                  ),
                ),
              ],
            ),
      child: Text(
        notice.content,
        style: eat.text.body.copyWith(color: eat.colors.inkMuted),
      ),
    );
  }
}

/// 打开公告链接. 后端只接受 https 地址和站内绝对路径, 其余形式忽略.
void _openLink(
  WidgetRef ref,
  String link,
  void Function(String location) openPath,
) {
  if (link.startsWith('/') && !link.startsWith('//')) {
    openPath(link);
    return;
  }
  final uri = Uri.tryParse(link);
  if (uri != null && uri.scheme == 'https') {
    unawaited(ref.read(browserProvider).open(uri));
  }
}

/// 发现页抽屉顶部的通知区域.
///
/// - 有普通公告时显示一条公告条, 点击查看全文, 关掉后同一条不再出现.
/// - 有建议更新时弹出一次 "有新版本" (产品 12.1). 仅在发现页位于最上层时弹出, 有待弹出的重要公告时让其先弹.
class DiscoverNotices extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DiscoverNotices> createState() => _DiscoverNoticesState();
}

class _DiscoverNoticesState extends ConsumerState<DiscoverNotices> {
  var _prompting = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(updatePromptProvider, (_, _) => _schedulePrompt());
    ref.listenManual(importantNoticeProvider, (_, _) => _schedulePrompt());
  }

  /// 发现页被其他页面覆盖或切换到其他标签时 [TickerMode] 关闭, 回到发现页时本方法再次调用.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) _schedulePrompt();
  }

  void _schedulePrompt() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_prompt()));

  Future<void> _prompt() async {
    if (_prompting || !mounted || !TickerMode.valuesOf(context).enabled) {
      return;
    }
    final line = ref.read(updatePromptProvider);
    if (line == null || ref.read(importantNoticeProvider) != null) return;
    _prompting = true;
    unawaited(
      ref.read(noticesProvider.notifier).markPrompted(line.latestBuild),
    );
    await showUpdatePrompt(context, line);
    _prompting = false;
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(bannerNoticeProvider);
    if (notice == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s20,
        0,
        EatSpace.s20,
        EatSpace.s14,
      ),
      child: _NoticeBar(notice: notice),
    );
  }
}

/// 普通公告条: 公告图标, 单行标题 (没有标题时用正文) 和关闭按钮.
class _NoticeBar extends ConsumerWidget {
  const new({required this.notice});

  final Announcement notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final text = notice.title ?? notice.content;
    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: EatSize.touch),
        decoration: BoxDecoration(
          color: c.mist,
          borderRadius: const BorderRadius.all(EatRadius.thumb),
        ),
        child: Row(
          children: [
            Expanded(
              child: EatTappable(
                onTap: () => showNoticeDialog(
                  context,
                  notice,
                  openPath: (location) => context.push(location),
                ),
                label: '公告：$text',
                focusShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(EatRadius.thumb),
                ),
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EatSpace.s14,
                    EatSpace.s10,
                    0,
                    EatSpace.s10,
                  ),
                  child: Row(
                    spacing: EatSpace.s10,
                    children: [
                      EatIcon(EatIcons.announce, size: 18, color: c.ink),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: eat.text.body.copyWith(color: c.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            EatIconButton(
              EatIcons.close,
              label: '关掉这条公告',
              onPressed: () =>
                  ref.read(noticesProvider.notifier).dismiss(notice.id),
            ),
          ],
        ),
      ),
    );
  }
}

/// 弹出建议更新对话框 "有新版本", 按钮为 "下次再说" 和 "去更新".
Future<void> showUpdatePrompt(BuildContext context, VersionLine line) =>
    showEatDialog<void>(
      context,
      builder: (dialog) => _UpdatePrompt(line: line),
    );

class _UpdatePrompt extends ConsumerWidget {
  const new({required this.line});

  final VersionLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final current = ref.watch(appVersionProvider).value;
    final latest = line.latestVersionName;
    final notes = line.releaseNotes;
    return EatDialog(
      icon: EatIcons.download,
      title: '有新版本',
      subtitle: switch ((current, latest)) {
        (final from?, final to?) => '$from 升到 $to',
        (null, final to?) => '新版本 $to',
        _ => null,
      },
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '下次再说',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: EatButton.solid(
              '去更新',
              onPressed: () async {
                final opened = await ref
                    .read(appStoreProvider)
                    .open(line.storeUrl);
                if (!context.mounted) return;
                if (opened) {
                  Navigator.of(context).pop();
                } else {
                  showToast(context, storeUnavailableMessage);
                }
              },
            ),
          ),
        ],
      ),
      child: notes == null
          ? null
          : Text(
              notes,
              style: eat.text.body.copyWith(color: eat.colors.inkMuted),
            ),
    );
  }
}

/// 没有商店地址或打不开商店时的提示.
const storeUnavailableMessage = '打不开应用商店，请在应用商店搜索「沙软今天吃什么」';
