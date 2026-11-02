import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'browser.g.dart';

/// 打开站外网页.
abstract interface class Browser {
  /// 打开协议等普通网页. App 中使用应用内浏览器, Web 中新开标签页. 返回是否成功打开.
  Future<bool> open(Uri url);

  /// 打开学校的统一认证页.
  ///
  /// - App: 使用应用内浏览器 (iOS 为 SFSafariViewController, Android 为 Custom Tabs).
  ///   认证结束后, 后端重定向到回跳链接, 由 App Links / Universal Links 唤起 App.
  /// - Web: 在当前标签页跳转. 认证结束后, 后端重定向到服务端配置的网页地址.
  Future<bool> openSso(Uri url);

  /// 回跳链接唤起 App 后, 关闭仍停留在认证页的应用内浏览器. 平台不支持时不做任何操作.
  ///
  /// iOS 的 SFSafariViewController 在 App 收到链接后仍覆盖在页面上方, 需要主动关闭.
  /// Android 的 Custom Tabs 无法通过 url_launcher 关闭, 由 `singleTask` 启动模式关闭.
  Future<void> closeSso();
}

class UrlLauncherBrowser implements Browser {
  @override
  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.inAppBrowserView);

  @override
  Future<bool> openSso(Uri url) => kIsWeb
      ? launchUrl(url, webOnlyWindowName: '_self')
      : launchUrl(url, mode: LaunchMode.inAppBrowserView);

  @override
  Future<void> closeSso() async {
    if (kIsWeb) return;
    if (await supportsCloseForLaunchMode(LaunchMode.inAppBrowserView)) {
      await closeInAppWebView();
    }
  }
}

@Riverpod(keepAlive: true)
Browser browser(Ref ref) => UrlLauncherBrowser();
