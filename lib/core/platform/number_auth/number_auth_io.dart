import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/number_auth/number_auth.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat_number_auth/eat_number_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 根据当前平台读取对应的阿里云号码认证方案密钥, 其分别绑定 Android 包名签名或 iOS Bundle ID.
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

/// Android 与 iOS 端的一键登录实现, 通过本地插件 `eat_number_auth` 调用号码认证 SDK.
///
/// SDK 返回码仅打印用于排查而不作分支区分, 常见码包括:
/// 600007 (无 SIM 卡), 600008 (未开启蜂窝网络), 600017 (方案密钥与包名签名不匹配, 如 debug 签名包), 600015 (超时).
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
      // 未接入原生实现的平台上不存在已打开的授权页, 无需处理.
    }
  }

  /// 预取号与获取登录凭证各自的超时上限, 超时后降级为验证码登录以避免长时间等待.
  static const _timeout = Duration(seconds: 5);

  /// 授权页外观配置, 采用与 App 底部面板一致的白底与 `ink` 实心胶囊按钮风格.
  ///
  /// 由于授权页运行在 Flutter 视图之外无法读取主题, 此处直接传入设计令牌的原始色值与尺寸.
  /// 依据阿里云合规要求, 登录按钮文案须包含 "登录", 且掩码号码, 运营商标语与协议链接均不得隐藏.
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
    alertTitle: '请先阅读并同意协议',
    alertPrefix: '登录前请阅读并同意',
    alertButtonText: '同意并继续',
  );
}
