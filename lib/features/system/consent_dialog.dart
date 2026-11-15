import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/state/cross_border_consent.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 隐私政策的同意对话框. 服务端要求同意新版政策时弹出, 返回 true 表示用户点了 "同意".
///
/// 点击 "不同意", 点击遮罩和系统返回都视为不同意.
Future<bool> showConsentDialog(BuildContext context) async =>
    await showEatDialog<bool>(
      context,
      builder: (dialog) => const _ConsentDialog(),
    ) ??
    false;

class _ConsentDialog extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final config = ref.watch(appConfigProvider);
    return EatDialog(
      icon: EatIcons.earth,
      title: '隐私政策已更新',
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '不同意',
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          Expanded(
            child: EatButton.solid(
              '同意',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '服务器位于境外，账号信息和使用记录会传到境外存储和处理。同意新版隐私政策后才能继续使用。',
            style: eat.text.body,
          ),
          _ConsentLink('查看隐私政策', config.privacyUrl),
          _ConsentLink('查看个人信息出境说明', config.crossBorderUrl),
        ],
      ),
    );
  }
}

/// 对话框里打开托管网页的链接. [url] 为空时不显示.
class _ConsentLink extends ConsumerWidget {
  const new(this.label, this.url);

  final String label;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (url.isEmpty) return const SizedBox.shrink();
    final eat = context.eat;
    return EatTappable(
      onTap: () => ref.read(browserProvider).open(Uri.parse(url)),
      label: label,
      builder: (context, _) => SizedBox(
        height: EatSize.touch,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: eat.text.body.copyWith(
              fontWeight: FontWeight.w600,
              color: eat.colors.ink,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}

/// 为已登录时的同意请求提供同意对话框. 置于应用根部, 包裹路由的内容.
///
/// 网络层的请求不属于任何页面, 因此对话框在 [navigatorKey] 对应的根导航器上弹出.
class ConsentHost extends ConsumerStatefulWidget {
  const new({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<ConsentHost> createState() => _ConsentHostState();
}

class _ConsentHostState extends ConsumerState<ConsentHost> {
  late final CrossBorderConsent _consent;

  @override
  void initState() {
    super.initState();
    _consent = ref.read(crossBorderConsentProvider)
      ..sessionPresenter = _present;
  }

  @override
  void dispose() {
    if (_consent.sessionPresenter == _present) _consent.sessionPresenter = null;
    super.dispose();
  }

  Future<bool> _present() async {
    final context = widget.navigatorKey.currentState?.overlay?.context;
    if (context == null || !context.mounted) return false;
    return showConsentDialog(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
