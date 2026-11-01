import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// 把网络层的会话回调接到登录态.
///
/// - 登录过期: 清除登录态.
/// - 无权限: 刷新账号状态.
/// - 需要同意: 自动调用同意接口.
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
      onForbidden: () => container.read(sessionProvider.notifier).refreshUser(),
      grantConsent: () =>
          container.read(authRepositoryProvider).grantConsentForSession(),
    );
  }),
];
