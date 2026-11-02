import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/state/cross_site_consent.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 跨站同步同意面板. 返回 true 表示用户点了 "同意".
///
/// 点击 "不同意", 点击遮罩和下拉关闭都视为不同意.
Future<bool> showConsentPanel(
  BuildContext context,
  ConsentPolicy policy,
) async =>
    await showPanel<bool>(
      context,
      builder: (panel) => _ConsentPanel(policy: policy),
    ) ??
    false;

class _ConsentPanel extends ConsumerWidget {
  const new({required this.policy});

  final ConsentPolicy policy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    return EatPanel(
      icon: EatIcons.earth,
      title: '同意跨站同步后继续',
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
            '账号信息和使用记录会在境内外站点之间同步，同意后才能继续使用。',
            style: eat.text.body.copyWith(height: 22 / 15),
          ),
          if (policy.url case final url?)
            EatTappable(
              onTap: () => ref.read(browserProvider).open(url),
              label: '查看跨站同步说明',
              builder: (context, _) => SizedBox(
                height: EatSize.touch,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '查看跨站同步说明',
                    style: eat.text.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 为已登录时的同意请求提供同意面板. 置于应用根部, 包裹路由的内容.
///
/// 网络层的请求不属于任何页面, 因此面板在 [navigatorKey] 对应的根导航器上弹出.
class ConsentHost extends ConsumerStatefulWidget {
  const new({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<ConsentHost> createState() => _ConsentHostState();
}

class _ConsentHostState extends ConsumerState<ConsentHost> {
  late final CrossSiteConsent _consent;

  @override
  void initState() {
    super.initState();
    _consent = ref.read(crossSiteConsentProvider)..sessionPresenter = _present;
  }

  @override
  void dispose() {
    if (_consent.sessionPresenter == _present) _consent.sessionPresenter = null;
    super.dispose();
  }

  Future<bool> _present(ConsentPolicy policy) async {
    final context = widget.navigatorKey.currentState?.overlay?.context;
    if (context == null || !context.mounted) return false;
    return showConsentPanel(context, policy);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
