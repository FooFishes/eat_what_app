import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_icon.g.dart';

/// 桌面上的 App 图标.
enum LauncherIcon {
  /// 默认图标.
  pig,
  bun,
}

/// 换桌面图标, 原生部分写在 Runner 里 (技术架构 16.4).
///
/// 当前用哪个图标以系统为准, 本地不另存. Web 不支持.
/// 安卓上换了以后要等 App 离开前台才生效, 在那之前 [current] 返回刚选的图标.
class AppIcon {
  AppIcon({MethodChannel? channel, bool? supported})
    : _channel = channel ?? const MethodChannel('you.v50to.eat/app_icon'),
      _supported =
          supported ??
          (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS));

  final MethodChannel _channel;
  final bool _supported;

  /// 当前的图标. 不支持换图标或读取失败时为 null.
  Future<LauncherIcon?> current() async {
    if (!_supported) return null;
    try {
      final name = await _channel.invokeMethod<String>('get');
      return LauncherIcon.values.asNameMap()[name];
    } on PlatformException catch (e) {
      debugPrint('app icon get failed: $e');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// 换成 [icon], 返回是否成功.
  Future<bool> select(LauncherIcon icon) async {
    if (!_supported) return false;
    try {
      await _channel.invokeMethod<void>('set', icon.name);
      return true;
    } on PlatformException catch (e) {
      debugPrint('app icon set failed: $e');
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
AppIcon appIcon(Ref ref) => AppIcon();

/// 当前的桌面图标, 个性化页面用. 不支持换图标时为 null.
@riverpod
Future<LauncherIcon?> launcherIcon(Ref ref) =>
    ref.watch(appIconProvider).current();
