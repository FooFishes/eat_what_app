import 'package:eat/core/config/app_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'number_auth_io.dart'
    if (dart.library.js_interop) 'number_auth_web.dart'
    as platform;

part 'number_auth.g.dart';

/// 一键登录授权页的交互结果.
sealed class NumberAuthOutcome {
  const NumberAuthOutcome();
}

/// 用户点击登录后由运营商签发取号凭证.
///
/// 此时授权页仍处于打开加载态, 需在服务端登录完成后调用 [NumberAuth.closeAuthPage] 关闭.
/// [token] 仅单次有效且仅通过登录请求体提交给服务端换取手机号, 不得写入 URL 或本地存储.
final class NumberAuthGranted extends NumberAuthOutcome {
  const NumberAuthGranted(this.token);

  final String token;
}

/// 用户主动关闭了授权页 (此时授权页已关闭).
final class NumberAuthCancelled extends NumberAuthOutcome {
  const NumberAuthCancelled();
}

/// 用户点击了 "其他号码登录" 切换登录方式 (此时授权页已关闭).
final class NumberAuthSwitched extends NumberAuthOutcome {
  const NumberAuthSwitched();
}

/// 授权页未能拉起或运营商未签发凭证 (此时授权页已关闭).
final class NumberAuthFailed extends NumberAuthOutcome {
  const NumberAuthFailed();
}

/// 运营商一键登录接口 (基于阿里云号码认证 SDK), 允许用户在确认后直接以本机号码免验证码登录.
///
/// 授权页为 SDK 原生底部弹窗, 掩码号码与运营商协议均由 SDK 托管展示, 客户端无法读取真实号码,
/// 仅获取取号凭证交由服务端向阿里云换取手机号.
///
/// 由于 SDK 会联网并读取网络及 SIM 卡状态, [prepare] 必须在用户同意隐私政策后方可调用.
/// 任意环节失败均统一视为不可用, 由调用方降级为验证码登录.
abstract interface class NumberAuth {
  /// 当前构建是否具备一键登录条件 (即处于 Android 或 iOS 平台且已配置方案密钥), 不会触发 SDK 访问.
  bool get supported;

  /// 初始化 SDK, 检查当前环境 (SIM 卡, 蜂窝网络, 方案密钥) 并预取号. 返回能否拉起授权页.
  ///
  /// 预取号成功后授权页才能立刻弹出. 可以重复调用.
  Future<bool> prepare();

  /// 拉起授权页并等待用户登录, 关闭或切换登录方式, 需先确保 [prepare] 调用成功.
  Future<NumberAuthOutcome> requestToken();

  /// 关闭授权页, 若授权页未处于打开状态则为空操作.
  Future<void> closeAuthPage();
}

/// 不支持一键登录的环境实现, 适用于 Web 端及未配置方案密钥的构建.
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
