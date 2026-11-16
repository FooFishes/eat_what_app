import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/fact_list.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 执行受限操作前的权限校验. 允许时返回 true, 否则弹出对应的拦截对话框并返回 false.
///
/// 受限操作按钮在界面上正常显示而不隐藏或置灰, 由点击后的拦截对话框向用户说明原因及后续引导.
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
      await _showSignIn(context, capability);
      return false;
    case NeedsVerification():
      await showEatDialog<void>(
        context,
        builder: (dialog) => EatDialog(
          icon: EatIcons.verify,
          title: '认证后才能${capability.verb}',
          subtitle: '用山大统一认证或山大邮箱认证，认证后可以发布和互动。',
          actions: Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(
                child: EatButton.mist(
                  '先逛逛',
                  onPressed: () => Navigator.of(dialog).pop(),
                ),
              ),
              Expanded(
                child: EatButton.solid(
                  '去认证',
                  onPressed: () {
                    Navigator.of(dialog).pop();
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
) => showEatDialog<void>(
  context,
  builder: (dialog) => EatDialog(
    icon: EatIcons.block,
    title: '账号封禁中，暂时不能${capability.verb}',
    actions: EatButton.solid(
      '知道了',
      onPressed: () => Navigator.of(dialog).pop(),
    ),
    child: FactList([
      if (status.reason case final reason?)
        (label: '原因', value: reason, strong: false),
      (
        label: '期限',
        value: banTerm(status.until, DateTime.now()),
        strong: false,
      ),
    ]),
  ),
);

/// 格式化账号封禁期限文案 (如 "封禁至 11 月 30 日"), 若截止时间 [until] 为 null 则返回 "永久封禁".
String banTerm(DateTime? until, DateTime now) => switch (until) {
  final until? => '封禁至 ${TimeFormat.date(until, now)}',
  null => '永久封禁',
};

/// 游客操作拦截对话框. 点击 "去登录" 时携带当前路径跳转至登录页, 登录完成后返回原页面而不自动重放刚才的操作.
Future<void> _showSignIn(BuildContext context, Capability capability) {
  final router = GoRouter.of(context);
  return showEatDialog<void>(
    context,
    builder: (dialog) => EatDialog(
      icon: EatIcons.me,
      title: '登录后才能${capability.verb}',
      subtitle: '用手机号登录，没注册过的号码会自动注册。',
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '先逛逛',
              onPressed: () => Navigator.of(dialog).pop(),
            ),
          ),
          Expanded(
            child: EatButton.solid(
              '去登录',
              onPressed: () {
                final from = router.state.uri.toString();
                Navigator.of(dialog).pop();
                router.go(Paths.loginFrom(from));
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// 统一处理操作失败后的界面反馈.
///
/// - 服务端判定无权限时, 先刷新账号状态再弹出拦截对话框.
/// - 游客收到会话过期响应时弹出登录引导对话框, 因游客不存在可过期的登录态而跳过登录过期处理流程.
/// - 其余失败展示轻提示.
///
/// [fallback] 为未知失败类型时的兜底提示文案 (如 "点赞失败, 请重试").
Future<void> reportActionFailure(
  BuildContext context,
  WidgetRef ref,
  AppFailure failure, {
  required Capability capability,
  required String fallback,
}) async {
  switch (failure.kind) {
    case FailureKind.cancelled:
      return;
    case FailureKind.sessionExpired:
      // 已登录状态下的会话过期由网络层清除登录态并交由路由守卫跳转至登录页, 此处不再额外提示.
      if (ref.read(sessionProvider) is Guest) {
        await guardAction(context, ref, capability);
      }
    case FailureKind.forbidden:
      await ref.read(sessionProvider.notifier).refreshUser();
      // 若刷新账号状态后本地仍判定为允许, guardAction 不会弹出拦截对话框, 因此需展示服务端返回的无权限提示以避免点击无响应.
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

/// 点击 "待接入" 占位入口时的反馈提示, 不发起请求而仅弹出轻提示.
///
/// [feature] 不影响展示文案, 仅用于在对应接口上线时按枚举值全局检索所有待接入入口.
void showPending(BuildContext context, PendingFeature feature) =>
    showToast(context, '该功能即将上线');
