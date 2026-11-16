import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/number_auth/number_auth.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat_number_auth/eat_number_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 方案密钥按平台分开: 阿里云的认证方案绑定包名和签名 (Android) 或 Bundle ID (iOS).
NumberAuth createNumberAuth(AppConfig config) {
  final secret = switch (defaultTargetPlatform) {
    TargetPlatform.android => config.numberAuthKeyAndroid,
    TargetPlatform.iOS => config.numberAuthKeyIos,
    _ => '',
  };
  return secret.isEmpty
      ? const UnsupportedNumberAuth()
      : _SdkNumberAuth(secret);
}

/// Android 和 iOS 上的一键登录, 经本地插件 `eat_number_auth` 调用号码认证 SDK.
///
/// SDK 的返回码只打印出来供排查, 不区分处理. 常见的有 600007 没有 SIM 卡, 600008 没开蜂窝网络,
/// 600017 方案密钥和包名签名对不上 (debug 签名的包就是这样), 600015 超时.
class _SdkNumberAuth implements NumberAuth {
  _SdkNumberAuth(this._secret);

  final String _secret;

  @override
  bool get supported => true;

  @override
  Future<bool> prepare() async {
    try {
      final code = await NumberAuthSdk.prepare(_secret, timeout: _timeout);
      if (code != null) debugPrint('number auth unavailable: $code');
      return code == null;
    } on PlatformException catch (e) {
      debugPrint('number auth prepare failed: ${e.code}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<NumberAuthOutcome> requestToken() async {
    try {
      final result = await NumberAuthSdk.requestLoginToken(
        _style,
        timeout: _timeout,
      );
      switch (result.status) {
        case LoginTokenStatus.granted:
          final token = result.token;
          if (token != null && token.isNotEmpty) {
            return NumberAuthGranted(token);
          }
          await closeAuthPage();
          return const NumberAuthFailed();
        case LoginTokenStatus.cancelled:
          return const NumberAuthCancelled();
        case LoginTokenStatus.switched:
          return const NumberAuthSwitched();
        case LoginTokenStatus.failed:
          debugPrint('number auth token failed: ${result.code}');
          return const NumberAuthFailed();
      }
    } on PlatformException catch (e) {
      debugPrint('number auth token failed: ${e.code}');
      return const NumberAuthFailed();
    } on MissingPluginException {
      return const NumberAuthFailed();
    }
  }

  @override
  Future<void> closeAuthPage() async {
    try {
      await NumberAuthSdk.closeAuthPage();
    } on PlatformException catch (e) {
      debugPrint('number auth close failed: ${e.code}');
    } on MissingPluginException {
      // 没有原生实现的平台上没有授权页可关.
    }
  }

  /// 预取号和取凭证各自的超时. 超时后改用验证码登录, 不让用户久等.
  static const _timeout = Duration(seconds: 5);

  /// 授权页的外观: 白底面板, `ink` 实心胶囊按钮, 和 App 里的底部面板一致.
  ///
  /// 授权页在 Flutter 之外, 读不到主题, 所以直接取令牌的原始值.
  /// 阿里云要求登录按钮的文字包含 "登录", 号码, 运营商标语和运营商协议不能隐藏.
  static final _style = AuthPageStyleMessage(
    background: EatPalette.paper.toARGB32(),
    scrim: EatPalette.scrim.toARGB32(),
    primary: EatPalette.ink.toARGB32(),
    onPrimary: EatPalette.paper.toARGB32(),
    secondary: EatPalette.ink.toARGB32(),
    muted: EatPalette.inkMuted.toARGB32(),
    cornerRadius: EatRadius.sheet.x,
    margin: EatSpace.s20,
    buttonHeight: EatSize.button,
    loginText: '本机号码一键登录',
    switchText: '其他号码登录',
    closeLabel: '关闭',
    privacyPrefix: '我已阅读并同意',
    alertTitle: '请先同意协议',
    alertPrefix: '登录前请阅读并同意',
    alertButtonText: '同意并继续',
  );
}
