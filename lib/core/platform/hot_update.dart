import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

part 'hot_update.g.dart';

/// 热更新管理, 底层由 Shorebird 实现.
///
/// 仅通过 `shorebird release` 构建的 Android 与 iOS 安装包可用.
/// Web, 调试构建及普通 `flutter build` 产物均不可用, 此时补丁号为 null 且检查更新为空操作.
class HotUpdate {
  HotUpdate([ShorebirdUpdater? updater])
    : _updater = updater ?? ShorebirdUpdater();

  final ShorebirdUpdater _updater;

  /// 当前运行的补丁号. 没有安装补丁或不可用时为 null.
  Future<int?> currentPatch() async {
    if (!_updater.isAvailable) return null;
    try {
      return (await _updater.readCurrentPatch())?.number;
    } on ReadPatchException catch (e) {
      debugPrint('$e');
      return null;
    }
  }

  // TODO: 远程配置接口未提供, 所有设备都检查 stable 轨道, 无法按比例放量. 远程配置上线后按分组号和放量比例选择 beta 或 stable 轨道.
  /// 有新补丁时在后台下载, 下次启动生效. 不提示用户.
  ///
  /// 失败时不重试, 等下次启动再检查.
  Future<void> downloadIfAvailable() async {
    if (!_updater.isAvailable) return;
    try {
      if (await _updater.checkForUpdate() == UpdateStatus.outdated) {
        await _updater.update();
      }
    } on Object catch (e) {
      debugPrint('hot update failed: $e');
    }
  }
}

@Riverpod(keepAlive: true)
HotUpdate hotUpdate(Ref ref) => HotUpdate();

/// 当前运行的补丁号. 显示在关于页, 并随崩溃上报.
@Riverpod(keepAlive: true)
Future<int?> currentPatch(Ref ref) =>
    ref.watch(hotUpdateProvider).currentPatch();
