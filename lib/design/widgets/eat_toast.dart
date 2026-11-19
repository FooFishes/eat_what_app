import 'dart:async';
import 'dart:math' as math;

import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// 在页面底部且位于导航栏上方显示一条轻提示 (如 "发布成功" "点赞失败, 请重试"), 采用 `ink` 底胶囊.
///
/// - 出现时从下面弹上来, 停留 2 秒后滑下去淡出; 系统开启减少动态效果时直接出现和消失.
/// - 接连出现的提示像一叠卡片: 新的在最前面, 旧的往上露出一截, 缩小一点, 颜色变淡; 最多同时 3 条, 多出来时最旧的一条先走.
/// - 和屏幕上已有的某条内容相同时不再叠一条, 那一条回到最前面左右抖一下, 重新计时.
/// - 往下拖就收起, 拖得不够远时弹回原位, 重新计时. 点击穿过提示落到下面的页面上, 不挡底部的按钮.
/// - 弹出时自动通过读屏播报提示内容.
void showToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
  // 上一个 App (如测试里卸载重建) 留下的浮层已经不在了, 连同它的提示一起丢掉.
  if (_entry case final entry? when !entry.mounted || _overlay != overlay) {
    _entry = null;
    _toasts.value = const [];
  }
  final bottom =
      NavBarInset.of(context) +
      MediaQuery.paddingOf(context).bottom +
      MediaQuery.viewInsetsOf(context).bottom +
      24;
  final alive = _toasts.value.where((t) => !t.leaving).toList();
  if (alive.where((t) => t.message == message).firstOrNull case final same?) {
    _toasts.value = [..._toasts.value.where((t) => t != same), same];
    same.key.currentState?.shake();
    return;
  }
  if (alive.length >= _maxAlive) alive.first.key.currentState?.leave();
  _toasts.value = [..._toasts.value, _ToastData(message, bottom)];
  if (_entry == null) {
    _overlay = overlay;
    _entry = OverlayEntry(builder: (_) => const _ToastStack());
    overlay.insert(_entry!);
  }
}

/// 屏幕上是否正显示着内容为 [message] 的轻提示.
bool isToastShowing(String message) =>
    _toasts.value.any((t) => !t.leaving && t.message == message);

/// 提示停留的时长, 不含进出动画时间.
const _stay = Duration(seconds: 2);

/// 最多同时显示几条.
const _maxAlive = 3;

/// 进场前和退场后藏在原位下方多远.
const _hiddenOffset = 160.0;

/// 叠在后面的提示每往后一层: 往上露出多少, 缩小多少, 往背景色淡多少 (最多淡到一半).
const _layerOffset = 12.0;
const _layerScale = 0.05;
const _layerFade = 0.15;

/// 往下拖超过这么远, 或松手时往下的速度超过这么快, 就收起.
const _dismissDistance = 24.0;
const _dismissVelocity = 300.0;

/// 重复的提示左右抖一下的初速度 (逻辑像素每秒).
const _shakeVelocity = 600.0;

final _toasts = ValueNotifier<List<_ToastData>>(const []);
OverlayEntry? _entry;
OverlayState? _overlay;

class _ToastData {
  _ToastData(this.message, this.bottom);

  final String message;
  final double bottom;
  final key = GlobalKey<_ToastViewState>();

  /// 是否已开始退场. 退场中的提示不算在叠放的层数里, 也不再接受操作.
  var leaving = false;
}

void _remove(_ToastData toast) {
  _toasts.value = [..._toasts.value.where((t) => t != toast)];
  if (_toasts.value.isEmpty) {
    _entry?.remove();
    _entry = null;
  }
}

/// 所有提示放在一个浮层里, 旧的在下面, 新的盖在上面.
class _ToastStack extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _toasts,
    builder: (context, toasts, _) {
      final alive = toasts.where((t) => !t.leaving).toList();
      return Stack(
        children: [
          for (final toast in toasts)
            _ToastView(
              key: toast.key,
              toast: toast,
              layer: toast.leaving
                  ? null
                  : alive.length - 1 - alive.indexOf(toast),
            ),
        ],
      );
    },
  );
}

class _ToastView extends StatefulWidget {
  const new({super.key, required this.toast, required this.layer});

  final _ToastData toast;

  /// 从前往后数在第几层, 最前面是 0. 退场中为 null, 停在原来的层上.
  final int? layer;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with TickerProviderStateMixin {
  /// 0 是在原位, 1 是藏在下方 [_hiddenOffset] 处.
  late final _slide = AnimationController.unbounded(vsync: this, value: 1);
  late final _layer = AnimationController.unbounded(
    vsync: this,
    value: (widget.layer ?? 0).toDouble(),
  );
  late final _shake = AnimationController.unbounded(vsync: this);

  /// 手指往下拖出的距离.
  late final _drag = AnimationController.unbounded(vsync: this);
  Timer? _timer;
  var _started = false;

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_still) {
      _slide.value = 0;
    } else {
      _slide.animateWith(SpringSimulation(EatMotion.springBouncy, 1, 0, 0));
    }
    _restartTimer();
  }

  @override
  void didUpdateWidget(_ToastView old) {
    super.didUpdateWidget(old);
    final layer = widget.layer;
    if (layer == null || layer == old.layer) return;
    if (_still) {
      _layer.value = layer.toDouble();
    } else {
      _layer.animateWith(
        SpringSimulation(
          EatMotion.springBouncy,
          _layer.value,
          layer.toDouble(),
          _layer.velocity,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slide.dispose();
    _layer.dispose();
    _shake.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer(_stay, leave);
  }

  /// 同样的提示又来了一次: 左右抖一下, 重新计时.
  void shake() {
    if (widget.toast.leaving) return;
    _restartTimer();
    if (_still) return;
    _shake.animateWith(
      SpringSimulation(EatMotion.springBouncy, 0, 0, _shakeVelocity),
    );
  }

  /// 滑下去淡出, 结束后从浮层移除.
  Future<void> leave() async {
    final toast = widget.toast;
    if (toast.leaving) return;
    toast.leaving = true;
    _timer?.cancel();
    _toasts.value = [..._toasts.value];
    if (!_still) {
      try {
        await _slide
            .animateWith(
              SpringSimulation(
                EatMotion.springSnappy,
                _slide.value,
                1,
                _slide.velocity,
              ),
            )
            .orCancel;
      } on TickerCanceled {
        // 动画播放期间浮层被卸载 (如 App 重建), 直接移除即可.
      }
    }
    _remove(toast);
  }

  void _dragStart(DragStartDetails _) {
    _timer?.cancel();
    _drag.stop();
  }

  void _dragUpdate(DragUpdateDetails details) {
    _drag.value = (_drag.value + details.delta.dy).clamp(0, 320);
  }

  void _dragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_drag.value > _dismissDistance || velocity > _dismissVelocity) {
      unawaited(leave());
      return;
    }
    _restartTimer();
    if (_still) {
      _drag.value = 0;
    } else {
      _drag.animateWith(
        SpringSimulation(EatMotion.springSnappy, _drag.value, 0, velocity),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final front = widget.layer == 0;
    final pill = AnimatedBuilder(
      animation: Listenable.merge([_slide, _layer, _shake, _drag]),
      builder: (context, child) {
        final layer = math.max(0.0, _layer.value);
        final hidden = _slide.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(
            _shake.value,
            _slide.value * _hiddenOffset + _drag.value - layer * _layerOffset,
          ),
          child: Transform.scale(
            scale: 1 - _layerScale * layer,
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: widget.toast.leaving ? 1 - hidden : 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: Color.lerp(
                    c.ink,
                    c.paper,
                    math.min(_layerFade * layer, 0.5),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Text(
          widget.toast.message,
          textAlign: TextAlign.center,
          style: eat.text.body.copyWith(color: c.paper),
        ),
      ),
    );
    return Positioned(
      left: EatSpace.s20,
      right: EatSpace.s20,
      bottom: widget.toast.bottom,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ExcludeSemantics(
          child: IgnorePointer(
            ignoring: !front || widget.toast.leaving,
            // 胶囊本身不接点击, 手势检测用 translucent: 拖动由这里接住, 点击照常落到下面的页面上.
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: _dragStart,
              onVerticalDragUpdate: _dragUpdate,
              onVerticalDragEnd: _dragEnd,
              onVerticalDragCancel: () => _dragEnd(DragEndDetails()),
              child: IgnorePointer(child: pill),
            ),
          ),
        ),
      ),
    );
  }
}
