/// Dart 与原生之间的接口定义. 改完后在本包目录运行
/// `fvm dart run pigeon --input pigeons/messages.dart` 重新生成三端代码.
///
/// 颜色一律是 ARGB 整数. 长度一律是逻辑像素, 由原生侧按屏幕密度换算.
library;

import 'package:pigeon/pigeon.dart';

/// 授权页的外观和文案. 授权页是 SDK 的原生页面, 从底部升起, 号码和运营商协议由 SDK 填.
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartPackageName: 'eat_number_auth',
    kotlinOut:
        'android/src/main/kotlin/you/v50to/eat/number_auth/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'you.v50to.eat.number_auth'),
    swiftOut: 'ios/eat_number_auth/Sources/eat_number_auth/Messages.g.swift',
  ),
)
class AuthPageStyleMessage {
  AuthPageStyleMessage({
    required this.background,
    required this.scrim,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.muted,
    required this.cornerRadius,
    required this.margin,
    required this.buttonHeight,
    required this.loginText,
    required this.switchText,
    required this.closeLabel,
    required this.privacyPrefix,
    required this.alertTitle,
    required this.alertPrefix,
    required this.alertButtonText,
  });

  /// 面板的底色.
  int background;

  /// 面板背后的遮罩, 透明度取自颜色的 alpha.
  int scrim;

  /// 号码的颜色, 登录按钮的底色.
  int primary;

  /// 登录按钮上文字的颜色.
  int onPrimary;

  /// 切换按钮和协议名的颜色.
  int secondary;

  /// 运营商标语和协议正文的颜色.
  int muted;

  /// 面板顶部两个角的圆角.
  double cornerRadius;

  /// 内容的左右边距.
  double margin;

  double buttonHeight;

  /// 登录按钮的文字. 阿里云要求包含 "登录".
  String loginText;

  /// 切换按钮的文字, 点了改用别的登录方式.
  String switchText;

  /// 关闭按钮给读屏用的名字.
  String closeLabel;

  /// 协议名前面的文字, 如 "我已阅读并同意".
  String privacyPrefix;

  /// 没勾协议就点登录时弹出的二次确认弹窗: 标题, 协议名前面的文字, 按钮文字.
  String alertTitle;
  String alertPrefix;
  String alertButtonText;
}

enum LoginTokenStatus {
  /// 用户点了登录, 拿到取号凭证. 授权页还开着并显示加载, 用 `closeAuthPage` 关闭.
  granted,

  /// 用户关掉了授权页. 授权页已关闭.
  cancelled,

  /// 用户点了切换按钮. 授权页已关闭.
  switched,

  /// 授权页没拉起来, 或取凭证失败. 授权页已关闭.
  failed,
}

class LoginTokenMessage {
  LoginTokenMessage({required this.status, this.token, this.code});

  LoginTokenStatus status;

  /// 取号凭证, 只在 [LoginTokenStatus.granted] 时有值. 只能用一次.
  String? token;

  /// SDK 的返回码, 只在 [LoginTokenStatus.failed] 时有值, 用于排查.
  String? code;
}

@HostApi()
abstract class NumberAuthHostApi {
  /// 设置方案密钥, 检查当前环境能否一键登录, 并预取号.
  ///
  /// 返回 null 表示可以拉起授权页, 否则是 SDK 的返回码.
  @async
  String? prepare(String secret, int timeoutMs);

  /// 拉起授权页, 等用户点登录, 关闭或切换.
  @async
  LoginTokenMessage requestLoginToken(
    AuthPageStyleMessage style,
    int timeoutMs,
  );

  /// 关闭授权页. 授权页没开着时什么也不做.
  void closeAuthPage();
}
