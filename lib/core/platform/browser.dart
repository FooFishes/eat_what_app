import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'browser.g.dart';

/// 打开站外的网页。
abstract interface class Browser {
  /// 协议这类普通网页：App 里用应用内浏览器，Web 新开一个标签页。返回是否打开了。
  Future<bool> open(Uri url);

  /// 学校的统一认证页：App 用应用内浏览器（iOS SFSafariViewController，安卓 Custom Tabs），
  /// 回到 App 时刷新认证状态；Web 在当前标签页跳过去，完成后后端把人送回 `/verify`（技术架构 18.1）。
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
