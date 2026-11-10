import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/consent/consent_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cross_border_consent.g.dart';

/// 同意对话框展示的政策. [url] 为说明页的完整地址, 服务端未提供时为 null.
class const ConsentPolicy({required final String version, final Uri? url});

/// 弹出同意对话框并等待用户选择. 返回 true 表示用户同意.
///
/// 由界面用自身的 `BuildContext` 包装后传入, Provider 不持有 `BuildContext`.
typedef ConsentPresenter = Future<bool> Function(ConsentPolicy policy);

/// 数据跨境同意: 读取当前政策, 请用户确认, 用户同意后提交同意.
///
/// 不代替用户同意. 用户不同意时抛出业务码为 [BizCodes.consentRequired] 的 [AppFailure].
class CrossBorderConsent {
  CrossBorderConsent(this._api, this._apiBaseUrl);

  final ConsentApi _api;
  final String _apiBaseUrl;

  /// 已登录时使用的同意对话框, 由应用根部的组件注册和注销.
  ///
  /// 未注册时没有界面可以询问用户, 按用户不同意处理.
  ConsentPresenter? sessionPresenter;

  /// 请用户确认当前政策. 用户同意时返回政策版本, 不提交同意.
  Future<String> confirm(ConsentPresenter present) async {
    final policy = await _api.policy();
    final version = policy.version!;
    final agreed = await present(
      ConsentPolicy(version: version, url: _resolve(policy.url)),
    );
    if (!agreed) throw AppFailure.fromCode(BizCodes.consentRequired);
    return version;
  }

  /// 请用户确认, 用户同意后提交同意.
  ///
  /// [proof] 为登录返回的临时凭证. 不带时使用当前会话提交.
  Future<void> grant(ConsentPresenter present, {String? proof}) async {
    final version = await confirm(present);
    await _api.grant(policyVersion: version, proof: proof);
  }

  /// 已登录时用 [sessionPresenter] 请用户确认, 用户同意后用当前会话提交同意.
  Future<void> grantForSession() async {
    final present = sessionPresenter;
    if (present == null) throw AppFailure.fromCode(BizCodes.consentRequired);
    await grant(present);
  }

  /// 说明页地址可能是站内绝对路径, 如 `/api/policies/x.html`, 按接口地址补全为完整地址.
  Uri? _resolve(String? url) {
    if (url == null || url.isEmpty) return null;
    return Uri.base.resolve(_apiBaseUrl).resolve(url);
  }
}

@Riverpod(keepAlive: true)
CrossBorderConsent crossBorderConsent(Ref ref) => CrossBorderConsent(
  ref.watch(consentApiProvider),
  ref.watch(appConfigProvider).apiBaseUrl,
);
