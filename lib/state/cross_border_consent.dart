import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/consent/consent_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cross_border_consent.g.dart';

/// 弹出协议确认对话框并等待用户选择, 返回 true 表示用户同意.
///
/// 由界面用自身的 `BuildContext` 包装后传入, Provider 不持有 `BuildContext`.
typedef ConsentPresenter = Future<bool> Function();

/// 隐私政策与数据跨境传输的合规确认流程, 负责查询当前协议版本, 弹窗请求确认并在用户授权后提交记录.
///
/// 客户端不代用户默认授权; 若用户拒绝或无界面可弹窗, 则抛出业务码为 [BizCodes.consentRequired] 的 [AppFailure].
/// 协议正文托管于独立网页, 对话框仅需收集用户的确认结果.
class CrossBorderConsent {
  CrossBorderConsent(this._api);

  final ConsentApi _api;

  /// 已登录状态下使用的协议确认弹窗回调, 由应用根组件负责注册与注销.
  ///
  /// 若未注册则无法向用户展示弹窗, 流程按拒绝处理.
  ConsentPresenter? sessionPresenter;

  /// 获取服务端当前生效的协议版本号; 若服务端尚未发布任何协议则返回 null, 此时登录请求无需携带版本号.
  Future<String?> currentVersion() async =>
      switch ((await _api.policy()).version) {
        final version? when version.isNotEmpty => version,
        _ => null,
      };

  /// 请求用户确认当前版本的协议. 用户同意后返回对应版本号但不立即提交记录; 若服务端尚未发布协议则返回 null 且不弹窗.
  Future<String?> confirm(ConsentPresenter present) async {
    final version = await currentVersion();
    if (version == null) return null;
    if (!await present()) throw AppFailure.fromCode(BizCodes.consentRequired);
    return version;
  }

  /// 在已登录状态下通过 [sessionPresenter] 请求用户确认最新协议, 确认后使用当前会话向服务端提交记录.
  Future<void> grantForSession() async {
    final present = sessionPresenter;
    if (present == null) throw AppFailure.fromCode(BizCodes.consentRequired);
    final version = await confirm(present);
    if (version == null) throw AppFailure.fromCode(BizCodes.consentRequired);
    await _api.grant(policyVersion: version);
  }
}

@Riverpod(keepAlive: true)
CrossBorderConsent crossBorderConsent(Ref ref) =>
    CrossBorderConsent(ref.watch(consentApiProvider));
