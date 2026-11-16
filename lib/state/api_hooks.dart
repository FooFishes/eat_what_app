import 'package:eat/core/network/api_client.dart';
import 'package:eat/state/cross_border_consent.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// 将网络层的会话与合规回调接入应用状态层.
///
/// - 登录过期: 清除登录态.
/// - 无权限: 刷新账号状态.
/// - 隐私政策已更新: 弹出确认对话框, 待用户确认后向服务端提交记录.
///
/// 由于 `core` 层不能导入 `state` 层, 因此由本文件提供 `apiHooksProvider` 的覆盖实现.
/// `bootstrap` 与涉及这些行为的测试均须注入这组覆盖.
///
/// 回调内部通过 `ref.container` 延迟读取 Provider, 因为登录态与同意接口依赖网络层,
/// 而网络层又依赖这组回调, 若改用 `ref.read` 会被 Riverpod 判定为循环依赖而拒绝.
final stateOverrides = <Override>[
  apiHooksProvider.overrideWith((ref) {
    final container = ref.container;
    return ApiHooks(
      onSessionExpired: () => container.read(sessionProvider.notifier).expire(),
      onForbidden: () => container.read(sessionProvider.notifier).refreshUser(),
      requestConsent: () =>
          container.read(crossBorderConsentProvider).grantForSession(),
    );
  }),
];
