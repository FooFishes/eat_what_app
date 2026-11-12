import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 受限操作的权限检查. 允许时返回 true, 不允许时弹出拦截对话框并返回 false.
///
/// 受限按钮正常显示, 不隐藏也不置灰. 点击后由拦截对话框说明原因和下一步.
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
  }
}

/// 游客的拦截对话框. "去登录" 带上当前地址进登录页, 登录后回到这里, 不替用户完成刚才的动作.
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

/// 操作失败后的反馈.
///
/// - 服务端判定无权限时, 刷新账号状态后弹出拦截对话框.
/// - 游客收到要求登录的响应时弹出登录对话框. 游客没有可过期的登录态, 不走登录过期流程.
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
    case FailureKind.cancelled:
      return;
    case FailureKind.sessionExpired:
      // 已登录时由网络层清除登录态, 守卫随后带去登录页, 这里不再提示.
      if (ref.read(sessionProvider) is Guest) {
        await guardAction(context, ref, capability);
      }
    case FailureKind.forbidden:
      await ref.read(sessionProvider.notifier).refreshUser();
      // 刷新后仍判定为允许时, 拦截对话框不会出现. 此时显示无权限的统一提示, 否则点击后界面没有任何反馈.
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
    showToast(context, '该功能即将上线');
