import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'app_store.g.dart';

/// 更新 App 的入口: App 中打开应用商店, Web 中刷新页面.
abstract interface class AppStore {
  /// App 中用外部应用打开商店地址 [storeUrl], Web 中忽略该地址并刷新当前页面以载入新版本. 返回是否成功打开.
  Future<bool> open(String? storeUrl);
}

class SystemAppStore implements AppStore {
  @override
  Future<bool> open(String? storeUrl) async {
    // Web 的新版本在下次加载页面时生效, 在当前标签页重新打开当前地址即刷新页面.
    if (kIsWeb) return launchUrl(Uri.base, webOnlyWindowName: '_self');
    final uri = storeUrl == null ? null : Uri.tryParse(storeUrl);
    if (uri == null) return false;
    // `market` 与 `itms-apps` 链接需交给商店应用处理, 应用内浏览器无法打开.
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
AppStore appStore(Ref ref) => SystemAppStore();
