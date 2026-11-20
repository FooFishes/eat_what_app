import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 手机与平板的分界, 屏幕最短边的逻辑像素. 小于它算手机.
const double phoneShortestSideLimit = 600;

/// 是否要把屏幕锁成竖屏. 只有安卓手机锁.
///
/// iPhone 由 `Info.plist` 只声明竖屏, 不用在这里锁. Web 不锁, 由浏览器窗口决定排版.
/// 尺寸未知时不锁: 最短边按 0 算会把平板也当成手机锁住.
bool locksPortrait(
  TargetPlatform platform, {
  required bool isWeb,
  required Size screenSize,
}) =>
    !isWeb &&
    platform == TargetPlatform.android &&
    !screenSize.isEmpty &&
    screenSize.shortestSide < phoneShortestSideLimit;

/// 按设备维持屏幕方向: 启动时判断一次, 屏幕尺寸变化 (如折叠屏展开, 合上) 时重新判断.
///
/// 按整块屏幕而不是 App 窗口判断. 分屏时窗口会比屏幕小, 按窗口算会把平板当成手机.
/// 判断结果没变时不发平台调用. 键盘升降动画每帧都会触发重新判断, 每次都调平台会发出大量重复请求.
class OrientationLock({
  final TargetPlatform? platform,
  final bool isWeb = kIsWeb,
  final Size Function() screenSize = _screenSize,
}) with WidgetsBindingObserver {
  /// 当前是否锁着竖屏. 初值是系统默认的不锁, 不需要锁的设备启动时不发平台调用.
  bool _locked = false;

  /// 注册到 [WidgetsBinding] 并按当前屏幕锁定方向, 在首帧前调用.
  static Future<void> start() async {
    final lock = OrientationLock();
    WidgetsBinding.instance.addObserver(lock);
    await lock.update();
  }

  /// 按当前屏幕重新判断. 需要锁时只允许正向竖屏, 不需要时恢复所有方向.
  ///
  /// 平台调用失败时不抛出, 记录退回原值, 下次屏幕变化时重试. 否则记录与系统实际方向不一致, 之后结果相同就再也不会去锁.
  Future<void> update() async {
    final locked = locksPortrait(
      platform ?? defaultTargetPlatform,
      isWeb: isWeb,
      screenSize: screenSize(),
    );
    if (locked == _locked) return;
    _locked = locked;
    try {
      await SystemChrome.setPreferredOrientations(
        locked ? const [DeviceOrientation.portraitUp] : const [],
      );
    } on PlatformException {
      _locked = !locked;
    }
  }

  @override
  void didChangeMetrics() => unawaited(update());
}

/// 屏幕的逻辑尺寸. 引擎尚未报告屏幕时退回 App 窗口的尺寸, 都没有时为 [Size.zero].
Size _screenSize() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  final display = dispatcher.displays.firstOrNull;
  if (display != null && display.devicePixelRatio > 0) {
    final size = display.size / display.devicePixelRatio;
    if (!size.isEmpty) return size;
  }
  final view = dispatcher.implicitView;
  if (view == null || view.devicePixelRatio <= 0) return Size.zero;
  return view.physicalSize / view.devicePixelRatio;
}
