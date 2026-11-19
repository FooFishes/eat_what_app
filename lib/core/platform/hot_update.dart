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
    await check();
  }

  /// 检查并下载新补丁, 返回结果. 设置里点 "检查更新" 时用, 结果提示给用户.
  Future<PatchCheck> check() async {
    if (!_updater.isAvailable) return PatchCheck.unavailable;
    try {
      switch (await _updater.checkForUpdate()) {
        case UpdateStatus.outdated:
          await _updater.update();
          return PatchCheck.ready;
        case UpdateStatus.restartRequired:
          return PatchCheck.ready;
        case UpdateStatus.upToDate:
          return PatchCheck.upToDate;
        case UpdateStatus.unavailable:
          return PatchCheck.unavailable;
      }
    } on Object catch (e) {
      debugPrint('hot update failed: $e');
      return PatchCheck.failed;
    }
  }
}

/// 检查补丁的结果.
enum PatchCheck {
  /// 这个包收不到补丁: Web, 调试构建, 或不是用 `shorebird release` 打的包.
  unavailable,

  /// 已经是最新的补丁.
  upToDate,

  /// 新补丁已下载好 (这次刚下载, 或之前已下载), 重新打开 App 后生效.
  ready,

  /// 检查或下载失败.
  failed,
}

@Riverpod(keepAlive: true)
HotUpdate hotUpdate(Ref ref) => HotUpdate();

/// 当前运行的补丁号. 显示在关于页, 并随崩溃上报.
@Riverpod(keepAlive: true)
Future<int?> currentPatch(Ref ref) =>
    ref.watch(hotUpdateProvider).currentPatch();
