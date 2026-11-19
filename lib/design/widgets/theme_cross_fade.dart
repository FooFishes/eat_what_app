import 'dart:ui' as ui;

import 'package:eat/design/theme/eat_motion.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 换深浅色时的过渡: 换之前截下当前画面盖在最上面, 底下一次换成新主题, 再让截图淡出.
///
/// 逐帧插值主题要每帧重建整棵树, 会卡; 这里只在换的那一帧重建一次, 淡出时每帧只改一张图的不透明度.
/// 截图盖着的时候不挡点击. 系统开启减少动态效果时不截图, 直接换.
class ThemeCrossFade extends StatefulWidget {
  const new({super.key, required this.followsSystem, required this.child});

  /// 为 true 时系统切换深浅色也播过渡. 固定深浅色时系统切换不影响界面, 不必截图.
  final bool followsSystem;

  final Widget child;

  /// 在换主题之前调用: 截下当前画面并开始淡出.
  static void capture(BuildContext context) =>
      context.findAncestorStateOfType<_ThemeCrossFadeState>()?._capture();

  @override
  State<ThemeCrossFade> createState() => _ThemeCrossFadeState();
}

class _ThemeCrossFadeState extends State<ThemeCrossFade>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _boundary = GlobalKey();
  late final _fade = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _clear();
    });
  late final _opacity = ReverseAnimation(
    CurvedAnimation(parent: _fade, curve: EatMotion.themeSwitch.curve),
  );
  ui.Image? _snapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fade.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  /// 系统换深浅色后, 下一帧才按新主题重建, 此时屏幕上还是旧画面, 来得及截图.
  @override
  void didChangePlatformBrightness() {
    if (widget.followsSystem) _capture();
  }

  void _capture() {
    final duration = context.motion(EatMotion.themeSwitch);
    final boundary = _boundary.currentContext?.findRenderObject();
    if (duration == Duration.zero || boundary is! RenderRepaintBoundary) {
      return;
    }
    var dirty = false;
    assert(() {
      dirty = boundary.debugNeedsPaint;
      return true;
    }());
    if (dirty) return;
    final image = boundary.toImageSync(
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    _snapshot?.dispose();
    setState(() => _snapshot = image);
    _fade
      ..duration = duration
      ..forward(from: 0);
  }

  void _clear() {
    final image = _snapshot;
    if (image == null || !mounted) return;
    setState(() => _snapshot = null);
    image.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.passthrough,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: FadeTransition(
                  opacity: _opacity,
                  child: RawImage(image: snapshot, fit: BoxFit.fill),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
