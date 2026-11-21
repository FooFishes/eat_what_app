import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

part 'hot_update.g.dart';

/// 热更新管理, 底层由 Shorebird 实现.
///
/// 仅通过 `shorebird release` 构建的 Android 与 iOS 安装包可用.
/// Web, 调试构建及普通 `flutter build` 产物均不可用, 此时补丁号为 null 且检查更新为空操作.
/// 只检查 `stable` 轨道, 补丁发给哪些设备由 Shorebird 服务端按放量比例决定.
///
/// 同意隐私政策后检查一次 ([downloadIfAvailable]), 之后回到前台时调用 [resume] (技术架构 16.2).
class HotUpdate {
  HotUpdate([ShorebirdUpdater? updater])
    : _updater = updater ?? ShorebirdUpdater();

  /// 回到前台时, 距上次成功检查超过该时长才重新检查.
  static const staleAfter = Duration(minutes: 10);

  final ShorebirdUpdater _updater;
  DateTime? _checkedAt;
  Future<PatchCheck>? _checking;

  /// 是否已开始检查. 同意隐私政策之前不检查, 因此回到前台时也不检查.
  var _started = false;

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

  /// 有新补丁时在后台下载, 下次启动生效. 不提示用户.
  ///
  /// 失败时不立即重试, 等下次回到前台或下次启动再检查.
  Future<void> downloadIfAvailable() async {
    await check();
  }

  /// 回到前台时调用. 已开始检查过, 且距上次成功检查超过 [staleAfter] (或还没成功过) 时再查一次, 同样静默下载.
  Future<void> resume() async {
    if (!_started) return;
    final checked = _checkedAt;
    if (checked != null && clock.now().difference(checked) < staleAfter) {
      return;
    }
    await check();
  }

  /// 检查并下载新补丁, 返回结果. 设置里点 "检查更新" 时也用它, 结果提示给用户.
  ///
  /// 并发调用共用同一次检查, 不会重复下载.
  Future<PatchCheck> check() {
    _started = true;
    return _checking ??= _check().whenComplete(() => _checking = null);
  }

  Future<PatchCheck> _check() async {
    final result = await _checkOnce();
    if (result != PatchCheck.failed) _checkedAt = clock.now();
    return result;
  }

  Future<PatchCheck> _checkOnce() async {
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
