import 'dart:async';

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

// TODO: 轻提示的样式尚未经设计确认. 确认后按结论调整位置, 颜色和停留时长.
/// 在页面底部且位于导航栏上方显示一条轻提示 (如 "发布成功" "点赞失败, 请重试"), 采用 `ink` 底胶囊且不阻挡页面操作.
///
/// - 出现时淡入并上移, 停留 2 秒后淡出; 若系统开启减少动态效果则跳过进出动画.
/// - 同一时刻只显示一条, 触发新提示时会立即替换旧提示.
/// - 弹出时自动通过读屏播报提示内容.
void showToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  // 立即移除旧提示并跳过其退场动画, 避免新旧两条提示在同一位置重叠.
  _current?.remove();
  final bottom =
      NavBarInset.of(context) + MediaQuery.paddingOf(context).bottom + 24;
  final key = GlobalKey<_ToastState>();
  late final _ToastEntry entry;
  entry = _ToastEntry(
    message,
    OverlayEntry(
      builder: (context) => _Toast(key: key, message: message, bottom: bottom),
    ),
  );
  _current = entry;
  overlay.insert(entry.overlay);
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
  entry.timer = Timer(_stay, () async {
    await key.currentState?.leave();
    entry.remove();
  });
}

/// 提示停留的时长, 不含进出动画时间.
const _stay = Duration(seconds: 2);

_ToastEntry? _current;

/// 屏幕上是否正显示着内容为 [message] 的轻提示.
bool isToastShowing(String message) => _current?.message == message;

class _ToastEntry {
  _ToastEntry(this.message, this.overlay);

  final String message;
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

/// 轻提示的胶囊视图, 进场时淡入并上移, 调用 [leave] 播放退场淡出.
class _Toast extends StatefulWidget {
  const new({super.key, required this.message, required this.bottom});

  final String message;
  final double bottom;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _controller.duration = context.motion(EatMotion.select);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 播放退场动画, 若组件已卸载则立即返回.
  Future<void> leave() async {
    if (!mounted) return;
    try {
      await _controller.reverse().orCancel;
    } on TickerCanceled {
      // 退场动画播放期间被新提示替换导致组件卸载, 属于正常情况, 无需处理.
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: EatMotion.select.curve,
    );
    return Positioned(
      left: EatSpace.s20,
      right: EatSpace.s20,
      bottom: widget.bottom,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(curved),
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
                    widget.message,
                    textAlign: TextAlign.center,
                    style: eat.text.body.copyWith(color: eat.colors.paper),
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
