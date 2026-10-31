import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 受限的按钮都先过这一道（技术架构 8.3）：能做就返回 true；不能做就弹拦截面板，返回 false。
///
/// 按钮照常显示，不隐藏、不置灰（产品 7.3）。
Future<bool> guardAction(
  BuildContext context,
  WidgetRef ref,
  Capability capability,
) async {
  final result = checkPermission(ref.read(accountStatusProvider), capability);
  switch (result) {
    case Allowed():
      return true;
    case NeedsSignIn():
      context.go(Paths.login);
      return false;
    case NeedsVerification():
      await showPanel<void>(
        context,
        builder: (panel) => EatPanel(
          icon: EatIcons.verify,
          title: '认证后才能${capability.verb}',
          subtitle: '用山大统一认证或山大邮箱认证，认证后可以发布和互动。',
          actions: Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(
                child: EatButton.mist(
                  '先逛逛',
                  onPressed: () => Navigator.of(panel).pop(),
                ),
              ),
              Expanded(
                child: EatButton.solid(
                  '去认证',
                  onPressed: () {
                    Navigator.of(panel).pop();
                    context.push(Paths.verify);
                  },
                ),
              ),
            ],
          ),
        ),
      );
      return false;
    case BlockedByBan(:final status):
      await _showBanned(context, capability, status);
      return false;
  }
}

Future<void> _showBanned(
  BuildContext context,
  Capability capability,
  BannedStatus status,
) => showPanel<void>(
  context,
  builder: (panel) => EatPanel(
    icon: EatIcons.block,
    title: '账号封禁中，暂时不能${capability.verb}',
    actions: EatButton.solid('知道了', onPressed: () => Navigator.of(panel).pop()),
    child: PanelFacts([
      if (status.reason case final reason?)
        (label: '原因', value: reason, strong: false),
      if (status.since case final since?)
        (
          label: '开始',
          value: TimeFormat.date(since, DateTime.now()),
          strong: false,
        ),
    ]),
  ),
);

/// 动作失败后的反馈：服务端说没权限时按最新的账号状态弹拦截面板，其余给一句轻提示。
///
/// [fallback] 是这个动作失败时的说法，如「点赞失败，请重试」；没网、太频繁这类有固定说法的用固定的。
Future<void> reportActionFailure(
  BuildContext context,
  WidgetRef ref,
  AppFailure failure, {
  required Capability capability,
  required String fallback,
}) async {
  switch (failure.kind) {
    case FailureKind.cancelled || FailureKind.sessionExpired:
      return;
    case FailureKind.forbidden:
      await ref.read(sessionProvider.notifier).refreshUser();
      if (context.mounted) await guardAction(context, ref, capability);
    case FailureKind.network ||
        FailureKind.tooFrequent ||
        FailureKind.server ||
        FailureKind.business:
      showToast(context, failure.message);
    case FailureKind.unknown:
      showToast(context, fallback);
  }
}

/// 「待接入」的入口点了以后：不发请求，只说一句。[feature] 标明是哪一项，接口上线后好找到入口。
void showPending(BuildContext context, PendingFeature feature) =>
    showToast(context, '该功能暂未开放');
