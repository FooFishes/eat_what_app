import 'dart:async';

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// 一句轻提示：「发布成功」「点赞失败，请重试」。
///
/// 样式按技术架构待确认 A6 的推荐：页面底部、导航上方的 `ink` 底胶囊，2 秒后消失，不挡操作。
/// 同时只显示一条，新的顶掉旧的；读屏会念出来。
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
                  style: eat.text.body.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    color: eat.colors.paper,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
