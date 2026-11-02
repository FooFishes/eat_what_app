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

/// 受限操作的权限检查. 允许时返回 true, 不允许时弹出拦截面板并返回 false.
///
/// 受限按钮正常显示, 不隐藏也不置灰. 点击后由拦截面板说明原因和下一步.
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
      (label: '期限', value: banTerm(status, DateTime.now()), strong: false),
    ]),
  ),
);

/// 封禁期限, 如 "封禁至 11 月 30 日". 没有截止时间时为 "永久封禁".
String banTerm(BannedStatus status, DateTime now) => switch (status.until) {
  final until? => '封禁至 ${TimeFormat.date(until, now)}',
  null => '永久封禁',
};

/// 操作失败后的反馈.
///
/// - 服务端判定无权限时, 刷新账号状态后弹出拦截面板.
/// - 其余失败显示轻提示.
///
/// [fallback] 是该操作的失败提示, 如 "点赞失败, 请重试". 只在失败类型没有固定提示时使用.
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
      // 刷新后仍判定为允许时, 拦截面板不会出现. 此时显示无权限的统一提示, 否则点击后界面没有任何反馈.
      if (context.mounted && await guardAction(context, ref, capability)) {
        if (context.mounted) showToast(context, failure.message);
      }
    case FailureKind.network ||
        FailureKind.tooFrequent ||
        FailureKind.server ||
        FailureKind.business:
      showToast(context, failure.message);
    case FailureKind.unknown:
      showToast(context, fallback);
  }
}

/// 点击 "待接入" 入口后的反馈. 不发请求, 只显示轻提示.
///
/// [feature] 不影响提示内容, 用于在接口上线时按枚举值找到所有入口.
void showPending(BuildContext context, PendingFeature feature) =>
    showToast(context, '该功能暂未开放');
