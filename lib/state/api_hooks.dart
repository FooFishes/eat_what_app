import 'package:eat/core/network/api_client.dart';
import 'package:eat/state/cross_border_consent.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// 把网络层的会话回调接到登录态.
///
/// - 登录过期: 清除登录态.
/// - 封禁: 清除登录态, 登录页显示封禁提示.
/// - 无权限: 刷新账号状态.
/// - 隐私政策已更新: 弹出同意对话框请用户确认, 用户同意后提交同意.
///
/// `core` 不能导入 `state`, 因此由本文件覆盖 `apiHooksProvider`.
/// `bootstrap` 和测试这些行为的测试都必须带上这组覆盖.
///
/// 回调通过 `ref.container` 读取 Provider.
/// 登录态和同意接口都依赖网络层, 网络层又依赖这组回调.
/// 改用 `ref.read` 会被 Riverpod 判定为循环依赖而拒绝.
final stateOverrides = <Override>[
  apiHooksProvider.overrideWith((ref) {
    final container = ref.container;
    return ApiHooks(
      onSessionExpired: () => container.read(sessionProvider.notifier).expire(),
      onBanned: () =>
          container.read(sessionProvider.notifier).expire(banned: true),
      onForbidden: () => container.read(sessionProvider.notifier).refreshUser(),
      requestConsent: () =>
          container.read(crossBorderConsentProvider).grantForSession(),
    );
  }),
];
