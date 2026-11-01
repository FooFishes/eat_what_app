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
  ///   回到 App 后由页面刷新认证状态.
  /// - Web: 在当前标签页跳转. 认证完成后, 后端重定向回 `/verify`.
  Future<bool> openSso(Uri url);
}

class UrlLauncherBrowser implements Browser {
  @override
  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.inAppBrowserView);

  @override
  Future<bool> openSso(Uri url) => kIsWeb
      ? launchUrl(url, webOnlyWindowName: '_self')
      : launchUrl(url, mode: LaunchMode.inAppBrowserView);
}

@Riverpod(keepAlive: true)
Browser browser(Ref ref) => UrlLauncherBrowser();
