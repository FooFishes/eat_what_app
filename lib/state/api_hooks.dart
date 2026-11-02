import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/state/cross_site_consent.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// 把网络层的会话回调接到登录态.
///
/// - 登录过期: 清除登录态.
/// - 无权限: 刷新账号状态.
/// - 需要同意: 弹出同意面板请用户确认, 用户同意后提交同意.
///   提交返回 [BizCodes.consentSignInCodes] 时清除登录态. 重新登录时服务端会返回临时凭证.
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
      requestConsent: () async {
        try {
          await container.read(crossSiteConsentProvider).grantForSession();
        } on AppFailure catch (e) {
          if (!BizCodes.consentSignInCodes.contains(e.code)) rethrow;
          container.read(sessionProvider.notifier).expire();
          throw AppFailure(
            FailureKind.sessionExpired,
            code: e.code,
            serverMessage: e.serverMessage,
          );
        }
      },
    );
  }),
];
