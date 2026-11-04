import 'dart:async';

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

// TODO: 轻提示的样式尚未经设计确认. 确认后按结论调整位置, 颜色和停留时长.
/// 显示一条轻提示, 如 "发布成功" "点赞失败, 请重试".
///
/// - 显示在页面底部, 导航上方, 为 `ink` 底胶囊, 不阻挡操作.
/// - 同一时刻只显示一条, 新提示替换旧提示.
/// - 读屏会朗读提示内容.
void showToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _current?.remove();
  final bottom =
      NavBarInset.of(context) + MediaQuery.paddingOf(context).bottom + 24;
  final entry = _ToastEntry(
    OverlayEntry(
      builder: (context) => _Toast(message: message, bottom: bottom),
    ),
  );
  _current = entry;
  overlay.insert(entry.overlay);
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
  entry.timer = Timer(const Duration(seconds: 2), entry.remove);
}

_ToastEntry? _current;

class _ToastEntry {
  _ToastEntry(this.overlay);

  final OverlayEntry overlay;
  Timer? timer;
  var _removed = false;

  void remove() {
    if (_removed) return;
    _removed = true;
    timer?.cancel();
    overlay.remove();
    if (identical(_current, this)) _current = null;
  }
}

class _Toast extends StatelessWidget {
  const new({required this.message, required this.bottom});

  final String message;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Positioned(
      left: EatSpace.s20,
      right: EatSpace.s20,
      bottom: bottom,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: context.motion(EatMotion.select),
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: eat.colors.ink,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: eat.text.body.copyWith(color: eat.colors.paper),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
