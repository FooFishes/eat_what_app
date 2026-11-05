import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'browser.g.dart';

/// 统一认证页的结束方式.
sealed class SsoOutcome {
  const SsoOutcome();
}

/// 后端重定向到了 App 的回跳地址, [link] 带 `result` 和 `code`.
///
/// 回跳地址任何 App 都能构造, 结果只用于提示.
final class SsoReturned extends SsoOutcome {
  const SsoReturned(this.link);

  final Uri link;
}

/// 用户关闭了认证页, 或没有经回跳地址回到 App.
///
/// 安卓上浏览器不支持 Auth Tab 时退回 Custom Tabs, 用户手动切回 App 也是这种结果.
/// Web 跳转离开当前页面, 同样返回本值.
final class SsoClosed extends SsoOutcome {
  const SsoClosed();
}

/// 没有可用的浏览器, 认证页没有打开.
final class SsoFailed extends SsoOutcome {
  const SsoFailed();
}

/// 打开站外网页.
abstract interface class Browser {
  /// 打开协议等普通网页. App 中使用应用内浏览器, Web 中新开标签页. 返回是否成功打开.
  Future<bool> open(Uri url);

  /// 打开学校的统一认证页, 等待认证结束.
  ///
  /// - App: 使用系统的认证会话 (iOS 为 ASWebAuthenticationSession, 安卓为 Chrome 的 Auth Tab,
  ///   浏览器不支持时退回 Custom Tabs). 后端重定向到 [ssoCallbackScheme] 开头的地址时,
  ///   会话关闭并返回该地址. 不依赖 App Links / Universal Links 的域名校验.
  /// - Web: 在当前标签页跳转. 认证结束后, 后端重定向到服务端配置的网页地址.
  Future<SsoOutcome> openSso(Uri url);
}

/// App 的统一认证回跳地址的 scheme, 即后端 `app.oauth-app-success-redirect` 配置的
/// `you.v50to.eat://auth/callback`. 改动需同步安卓清单中 `CallbackActivity` 的声明.
const ssoCallbackScheme = 'you.v50to.eat';

class SystemBrowser implements Browser {
  @override
  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.inAppBrowserView);

  @override
  Future<SsoOutcome> openSso(Uri url) async {
    if (kIsWeb) {
      final opened = await launchUrl(url, webOnlyWindowName: '_self');
      return opened ? const SsoClosed() : const SsoFailed();
    }
    try {
      final link = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: ssoCallbackScheme,
      );
      return SsoReturned(Uri.parse(link));
    } on PlatformException catch (e) {
      return e.code == 'CANCELED' ? const SsoClosed() : const SsoFailed();
    }
  }
}

@Riverpod(keepAlive: true)
Browser browser(Ref ref) => SystemBrowser();
