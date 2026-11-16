/// Dart 与原生之间的接口定义. 修改后须在本包目录运行
/// `fvm dart run pigeon --input pigeons/messages.dart` 重新生成三端代码.
///
/// 颜色均为 ARGB 整数; 长度单位均为逻辑像素, 由原生侧按屏幕密度换算.
library;

import 'package:pigeon/pigeon.dart';

/// 原生授权页的外观与文案配置.
///
/// 授权页由 SDK 拉起并从底部弹出, 脱敏号码与运营商协议由 SDK 自动填充.
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

  /// 登录按钮的文案, 阿里云规范要求其中必须包含 "登录".
  String loginText;

  /// 切换按钮的文案, 用于改用其他登录方式.
  String switchText;

  /// 关闭按钮的无障碍朗读名称.
  String closeLabel;

  /// 协议名称前的前缀文案, 如 "我已阅读并同意".
  String privacyPrefix;

  /// 未勾选协议直接点击登录时弹出的二次确认弹窗: 标题, 协议名称前缀与确认按钮文案.
  String alertTitle;
  String alertPrefix;
  String alertButtonText;
}

enum LoginTokenStatus {
  /// 用户点击登录并成功获取取号凭证; 此时授权页仍处于加载状态, 须调用 `closeAuthPage` 关闭.
  granted,

  /// 用户主动关闭了授权页, 页面已关闭.
  cancelled,

  /// 用户点击了切换按钮, 页面已关闭.
  switched,

  /// 授权页未能拉起或取号失败, 页面已关闭.
  failed,
}

class LoginTokenMessage {
  LoginTokenMessage({required this.status, this.token, this.code});

  LoginTokenStatus status;

  /// 一次性取号凭证, 仅在 [LoginTokenStatus.granted] 时非空.
  String? token;

  /// SDK 返回的错误码, 仅在 [LoginTokenStatus.failed] 时非空, 用于问题排查.
  String? code;
}

@HostApi()
abstract class NumberAuthHostApi {
  /// 配置方案密钥并预取号, 同时检查当前环境是否支持一键登录.
  ///
  /// 返回 null 表示可拉起授权页, 否则返回 SDK 错误码.
  @async
  String? prepare(String secret, int timeoutMs);

  /// 拉起授权页, 等待用户点击登录, 关闭或切换登录方式.
  @async
  LoginTokenMessage requestLoginToken(
    AuthPageStyleMessage style,
    int timeoutMs,
  );

  /// 关闭授权页; 若授权页未打开则忽略.
  void closeAuthPage();
}
