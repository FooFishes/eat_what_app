import 'package:eat/core/config/app_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'number_auth_io.dart'
    if (dart.library.js_interop) 'number_auth_web.dart'
    as platform;

part 'number_auth.g.dart';

/// 授权页的结果.
sealed class NumberAuthOutcome {
  const NumberAuthOutcome();
}

/// 用户在授权页点了登录, 运营商签发了取号凭证.
///
/// 授权页还开着并显示加载, 向服务端登录完后用 [NumberAuth.closeAuthPage] 关闭.
/// [token] 交给服务端换手机号, 只能用一次. 只放在登录请求的请求体里, 不写入 URL 和本地存储.
final class NumberAuthGranted extends NumberAuthOutcome {
  const NumberAuthGranted(this.token);

  final String token;
}

/// 用户关掉了授权页. 授权页已关闭.
final class NumberAuthCancelled extends NumberAuthOutcome {
  const NumberAuthCancelled();
}

/// 用户在授权页点了 "其他号码登录". 授权页已关闭.
final class NumberAuthSwitched extends NumberAuthOutcome {
  const NumberAuthSwitched();
}

/// 授权页没拉起来, 或运营商没有签发凭证. 授权页已关闭.
final class NumberAuthFailed extends NumberAuthOutcome {
  const NumberAuthFailed();
}

/// 运营商一键登录 (阿里云号码认证 SDK): 用户在运营商的授权页上确认后, 用本机号码登录, 不用收验证码.
///
/// 授权页是 SDK 的原生页面, 从底部升起. 号码和运营商协议由 SDK 显示, App 读不到号码,
/// 只拿到一个取号凭证, 由服务端向阿里云换手机号.
///
/// SDK 会联网并读取网络和 SIM 卡状态, 因此 [prepare] 只能在用户同意隐私政策之后调用.
/// 任何失败都只表现为 "不可用", 由调用方改用验证码登录.
abstract interface class NumberAuth {
  /// 当前构建能否一键登录: 平台是 Android 或 iOS, 且配置了方案密钥. 不访问 SDK.
  bool get supported;

  /// 初始化 SDK, 检查当前环境 (SIM 卡, 蜂窝网络, 方案密钥) 并预取号. 返回能否拉起授权页.
  ///
  /// 预取号成功后授权页才能立刻弹出. 可以重复调用.
  Future<bool> prepare();

  /// 拉起授权页, 等用户点登录, 关闭或切换. 要先 [prepare] 成功.
  Future<NumberAuthOutcome> requestToken();

  /// 关闭授权页. 授权页没开着时什么也不做.
  Future<void> closeAuthPage();
}

/// 不能一键登录的环境: Web, 以及没配方案密钥的构建.
class UnsupportedNumberAuth implements NumberAuth {
  const new();

  @override
  bool get supported => false;

  @override
  Future<bool> prepare() async => false;

  @override
  Future<NumberAuthOutcome> requestToken() async => const NumberAuthFailed();

  @override
  Future<void> closeAuthPage() async {}
}

@Riverpod(keepAlive: true)
NumberAuth numberAuth(Ref ref) =>
    platform.createNumberAuth(ref.watch(appConfigProvider));
