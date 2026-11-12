import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/consent/consent_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cross_border_consent.g.dart';

/// 弹出同意对话框并等待用户选择. 返回 true 表示用户同意.
///
/// 由界面用自身的 `BuildContext` 包装后传入, Provider 不持有 `BuildContext`.
typedef ConsentPresenter = Future<bool> Function();

/// 隐私政策和数据跨境说明的同意: 读取当前版本, 请用户确认, 用户同意后提交同意.
///
/// 不代替用户同意. 用户不同意时抛出业务码为 [BizCodes.consentRequired] 的 [AppFailure].
/// 政策正文使用托管的网页, 对话框只需要知道用户是否同意.
class CrossBorderConsent {
  CrossBorderConsent(this._api);

  final ConsentApi _api;

  /// 已登录时使用的同意对话框, 由应用根部的组件注册和注销.
  ///
  /// 未注册时没有界面可以询问用户, 按用户不同意处理.
  ConsentPresenter? sessionPresenter;

  /// 当前政策的版本. 服务端还没发布过政策时为 null, 此时登录不需要带版本.
  Future<String?> currentVersion() async =>
      switch ((await _api.policy()).version) {
        final version? when version.isNotEmpty => version,
        _ => null,
      };

  /// 请用户确认当前政策. 用户同意时返回政策版本, 不提交同意.
  ///
  /// 服务端还没发布过政策时不询问, 返回 null.
  Future<String?> confirm(ConsentPresenter present) async {
    final version = await currentVersion();
    if (version == null) return null;
    if (!await present()) throw AppFailure.fromCode(BizCodes.consentRequired);
    return version;
  }

  /// 已登录时用 [sessionPresenter] 请用户确认, 用户同意后用当前会话提交同意.
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
