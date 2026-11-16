import 'package:clock/clock.dart';
import 'package:eat/core/platform/app_info.dart';
import 'package:eat/core/platform/app_store.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_stage.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/models/client_config.dart';
import 'package:eat/domain/rules/remote_config_rules.dart';
import 'package:eat/features/system/notices.dart';
import 'package:eat/state/remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 强制更新页 (`/update`). 本机构建号低于最低可用构建号时, 路由守卫把所有页面导向这里, 只能去更新.
class ForceUpdatePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final line = ref.watch(currentVersionLineProvider);
    final current = ref.watch(appVersionProvider).value;
    final latest = line?.latestVersionName;
    final note = eat.text.meta.copyWith(color: eat.colors.inkMuted);
    final strong = eat.text.meta.copyWith(
      color: eat.colors.ink,
      fontWeight: FontWeight.w600,
    );
    return _BlockingStage(
      stage: StageColor.broth,
      icon: EatIcons.download,
      title: '该更新了',
      message: '这个版本太旧，有些功能已经用不了。\n更新后账号和内容都还在。',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EatSpace.s14,
        children: [
          if (current != null || latest != null)
            Row(
              children: [
                if (current != null)
                  Text.rich(
                    TextSpan(
                      text: '你现在是 ',
                      children: [TextSpan(text: current, style: strong)],
                    ),
                    style: note,
                  ),
                const Spacer(),
                if (latest != null)
                  Text.rich(
                    TextSpan(
                      text: '最新 ',
                      children: [TextSpan(text: latest, style: strong)],
                    ),
                    style: note,
                  ),
              ],
            ),
          EatButton.solid(
            kIsWeb ? '刷新页面' : '去更新',
            icon: EatIcons.download,
            onPressed: () async {
              final opened = await ref
                  .read(appStoreProvider)
                  .open(line?.storeUrl);
              if (!opened && context.mounted) {
                showToast(context, storeUnavailableMessage);
              }
            },
          ),
          Text(
            kIsWeb ? '刷新后就是最新版本。' : '会打开应用商店。',
            textAlign: TextAlign.center,
            style: eat.text.caption.copyWith(color: eat.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// 停服维护页 (`/maintenance`). 远程配置为停服维护时, 路由守卫把所有页面导向这里.
///
/// 维护结束后远程配置变化, 路由守卫自动离开本页; "再试一次" 立即重新获取配置.
class MaintenancePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends ConsumerState<MaintenancePage> {
  var _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await ref.read(remoteConfigProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _retrying = false);
    final mode = ref.read(remoteConfigProvider).maintenance.mode;
    if (mode == MaintenanceMode.down) showToast(context, '还在维护中，请稍后再试');
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final maintenance = ref.watch(
      remoteConfigProvider.select((c) => c.maintenance),
    );
    final until = maintenance.until;
    final message = maintenance.message;
    return _BlockingStage(
      stage: StageColor.bamboo,
      icon: EatIcons.tool,
      title: '正在维护',
      message: message == null
          ? '这段时间打不开，维护好了就能照常用。\n账号和内容都不受影响。'
          : '$message\n账号和内容都不受影响。',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EatSpace.s16,
        children: [
          if (until != null)
            Row(
              spacing: 12,
              children: [
                EatIcon(EatIcons.time, size: 22, color: eat.colors.ink),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '预计恢复',
                      style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
                    ),
                    Text(
                      recoveryTime(until, clock.now()),
                      style: eat.text.subhead.copyWith(color: eat.colors.ink),
                    ),
                  ],
                ),
              ],
            ),
          EatButton.mist(
            '再试一次',
            icon: EatIcons.shuffle,
            loading: _retrying,
            onPressed: _retrying ? null : _retry,
          ),
        ],
      ),
    );
  }
}

/// 强制更新页和维护页共用的布局: 舞台色背景上的图标, 大标题和说明, 底部白色面板放操作.
class _BlockingStage extends StatelessWidget {
  const new({
    required this.stage,
    required this.icon,
    required this.title,
    required this.message,
    required this.footer,
  });

  final StageColor stage;
  final EatIcons icon;
  final String title;
  final String message;
  final Widget footer;

  /// 宽屏上内容的最大宽度, 避免底部面板和按钮横跨整个窗口.
  static const _maxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return EatStage(
      stage: stage,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      EatSpace.s24,
                      72,
                      EatSpace.s24,
                      EatSpace.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: eat.colors.paper,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: EatIcon(
                                icon,
                                size: 30,
                                color: eat.colors.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Semantics(
                          header: true,
                          child: Text(title, style: eat.text.stage),
                        ),
                        const SizedBox(height: 12),
                        Text(message, style: eat.text.body),
                      ],
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: eat.colors.paper,
                  borderRadius: const BorderRadius.vertical(
                    top: EatRadius.sheet,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    EatSpace.s20,
                    EatSpace.s24,
                    EatSpace.s20,
                    EatSpace.s24 + bottom,
                  ),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: eat.colors.ink),
                    child: footer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
