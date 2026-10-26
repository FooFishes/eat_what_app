import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/auth/auth_repository.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// 把网络层的回调接到登录态上：过期时清登录态，没权限时刷新账号状态，需要同意时自动同意。
///
/// `core` 不能导入 `state`，所以由这里覆盖 `apiHooksProvider`；`bootstrap` 和要测这些行为的测试
/// 都要带上这组覆盖。
///
/// 回调里经 `ref.container` 读：登录态和同意接口本身都依赖网络层，也就依赖这组回调，用 `ref.read`
/// 会被 Riverpod 当成循环依赖拒绝。
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
