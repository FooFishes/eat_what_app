import 'dart:async';
import 'dart:math' as math;

import 'package:eat/core/env/pending_features.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/stage/stage_palette.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/stage_color_picker.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/features/system/guard.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// "调整照片" 点击 "完成" 的结果. [picked] 是用户手动选择的颜色, 未选择时为 null.
class const CropResult({
  required final CoverCrop crop,
  required final StageSuggestion suggestion,
  final StageColor? picked,
});

/// "调整照片" 页面.
///
/// - 上方: 通过拖动和双指缩放把主菜放进取景圈. 缩放滑条是双指缩放的替代操作.
/// - 下方: 从取景圈内取色推荐的三个舞台色, 以及首页效果预览.
///
/// 页面依赖内存中的照片, 无法用地址恢复, 因此不进路由表, 由加菜页通过 `Navigator.push` 打开.
class CropPage extends StatefulWidget {
  const new({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    required this.sample,
    required this.crop,
    required this.fallback,
    required this.dishName,
    this.picked,
  });

  final ImageProvider image;

  /// 照片的像素宽度. [height] 为像素高度.
  final int width;
  final int height;

  /// 取色用的缩小图. 裁切变化时用它重算推荐色, 不重新解码原图.
  final Future<StageSample> sample;
  final CoverCrop crop;

  /// 分类默认色. 照片太灰导致取色不可靠时排在推荐色第一位.
  final StageColor fallback;
  final String dishName;
  final StageColor? picked;

  static Route<CropResult> route({
    required ImageProvider image,
    required int width,
    required int height,
    required Future<StageSample> sample,
    required CoverCrop crop,
    required StageColor fallback,
    required String dishName,
    StageColor? picked,
  }) => MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => CropPage(
      image: image,
      width: width,
      height: height,
      sample: sample,
      crop: crop,
      fallback: fallback,
      dishName: dishName,
      picked: picked,
    ),
  );

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  late CoverCrop _crop = widget.crop;
  late StageColor? _picked = widget.picked;
  StageSample? _sample;
  StageSuggestion? _suggestion;
  Timer? _debounce;
  CoverCrop? _gestureStart;

  /// 取景圈直径占照片短边比例的下限, 决定最大放大倍数.
  static const _minDiameter = 0.25;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.sample.then((sample) {
        if (!mounted) return;
        _sample = sample;
        _resuggest();
      }, onError: (Object _) {}),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<StageColor> get _candidates =>
      _suggestion?.top3(widget.fallback) ?? [widget.fallback];

  StageColor get _selected => _picked ?? _candidates.first;

  void _resuggest() {
    final sample = _sample;
    if (sample == null) return;
    setState(() {
      _suggestion = sample.suggest(
        centerX: _crop.centerX,
        centerY: _crop.centerY,
        diameter: _crop.diameter,
      );
      if (_picked != null && !_candidates.contains(_picked)) _picked = null;
    });
  }

  /// 更新裁切. 照片位置立即更新, 推荐色在裁切停止变化后经过防抖再重算.
  ///
  /// 取色在主线程执行, 防抖避免拖动的每一帧都重算.
  void _setCrop(CoverCrop crop) {
    setState(() => _crop = _clamp(crop));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), _resuggest);
  }

  /// 把裁切限制在照片范围内: 直径限制在 [_minDiameter] 到 1, 取景圈不超出照片边缘.
  CoverCrop _clamp(CoverCrop crop) {
    final diameter = crop.diameter.clamp(_minDiameter, 1.0);
    final short = math.min(widget.width, widget.height).toDouble();
    final rx = diameter * short / 2 / widget.width;
    final ry = diameter * short / 2 / widget.height;
    return CoverCrop(
      centerX: crop.centerX.clamp(rx, 1 - rx),
      centerY: crop.centerY.clamp(ry, 1 - ry),
      diameter: diameter,
    );
  }

  void _done() {
    final sample = _sample;
    final suggestion =
        sample?.suggest(
          centerX: _crop.centerX,
          centerY: _crop.centerY,
          diameter: _crop.diameter,
        ) ??
        _suggestion;
    if (suggestion == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context)
        .pop(CropResult(crop: _crop, suggestion: suggestion, picked: _picked));
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final media = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // 缩放滑条是 Material 组件, 需要 Material 祖先.
      child: Material(
        color: c.cropGround,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: c.paper),
          child: Column(
            children: [
              SizedBox(height: media.padding.top),
              _TopBar(
                onCancel: () => Navigator.of(context).pop(),
                onDone: _done,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => _Viewport(
                    image: widget.image,
                    width: widget.width,
                    height: widget.height,
                    crop: _crop,
                    circle: math.min(
                      math.min(constraints.maxWidth - 48, 320),
                      constraints.maxHeight - 48,
                    ),
                    onStart: () => _gestureStart = _crop,
                    onUpdate: (scale, delta, pxPerImage) {
                      final start = _gestureStart ?? _crop;
                      _setCrop(
                        CoverCrop(
                          centerX:
                              _crop.centerX -
                              delta.dx / pxPerImage / widget.width,
                          centerY:
                              _crop.centerY -
                              delta.dy / pxPerImage / widget.height,
                          diameter: start.diameter / scale,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Text(
                '拖动、缩放，把主菜放进圈里',
                style: eat.text.meta.copyWith(
                  color: c.paper.withValues(alpha: 0.7),
                ),
              ),
              _ZoomSlider(
                zoom: 1 / _crop.diameter,
                max: 1 / _minDiameter,
                onChanged: (zoom) => _setCrop(
                  CoverCrop(
                    centerX: _crop.centerX,
                    centerY: _crop.centerY,
                    diameter: 1 / zoom,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.cropPanel,
                  borderRadius: const BorderRadius.vertical(
                    top: EatRadius.sheet,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    EatSpace.s20,
                    EatSpace.s16,
                    EatSpace.s20,
                    media.padding.bottom + EatSpace.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _RemoveBackground(),
                      const SizedBox(height: EatSpace.s14),
                      StageColorPicker(
                        candidates: _candidates,
                        selected: _selected,
                        onSelected: (color) => setState(() => _picked = color),
                        dishName: widget.dishName,
                        image: widget.image,
                        centerX: _crop.centerX,
                        centerY: _crop.centerY,
                        diameter: _crop.diameter,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const new({required this.onCancel, required this.onDone});

  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    Widget action(String label, VoidCallback onTap, {bool strong = false}) =>
        EatTappable(
          onTap: onTap,
          builder: (context, _) => SizedBox(
            height: EatSize.touch,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: EatSpace.s16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: eat.text.body.copyWith(
                    fontSize: 16,
                    fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
                    color: eat.colors.paper,
                  ),
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        action('取消', onCancel),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              '调整照片',
              textAlign: TextAlign.center,
              style: eat.text.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: eat.colors.paper,
              ),
            ),
          ),
        ),
        action('完成', onDone, strong: true),
      ],
    );
  }
}

/// 取景区域. 照片位于取景圈下方, 圈外覆盖 `crop-scrim`. 手势同时处理拖动和双指缩放.
class _Viewport extends StatelessWidget {
  const new({
    required this.image,
    required this.width,
    required this.height,
    required this.crop,
    required this.circle,
    required this.onStart,
    required this.onUpdate,
  });

  final ImageProvider image;
  final int width;
  final int height;
  final CoverCrop crop;

  /// 取景圈在屏幕上的直径.
  final double circle;
  final VoidCallback onStart;

  /// 手势更新回调.
  ///
  /// - [scale]: 本次手势开始以来的累计缩放.
  /// - [delta]: 本帧手指的位移.
  /// - [pxPerImage]: 照片一个像素在屏幕上的宽度.
  final void Function(double scale, Offset delta, double pxPerImage) onUpdate;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    final short = math.min(width, height);
    final pxPerImage = circle / (crop.diameter * short);
    return Semantics(
      label: '照片取景，拖动调整位置，双指缩放',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (_) => onStart(),
        onScaleUpdate: (d) => onUpdate(d.scale, d.focalPointDelta, pxPerImage),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final center = constraints.biggest.center(Offset.zero);
            final w = width * pxPerImage;
            final h = height * pxPerImage;
            return ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: center.dx - crop.centerX * w,
                    top: center.dy - crop.centerY * h,
                    width: w,
                    height: h,
                    child: Image(
                      image: image,
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                      gaplessPlayback: true,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScrimPainter(
                        center: center,
                        radius: circle / 2,
                        scrim: c.cropScrim,
                        ring: c.paper,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.center,
    required this.radius,
    required this.scrim,
    required this.ring,
  });

  final Offset center;
  final double radius;
  final Color scrim;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = Rect.fromCircle(center: center, radius: radius);
    canvas
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addOval(hole),
        Paint()..color = scrim,
      )
      ..drawOval(
        hole,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ring,
      );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.center != center ||
      old.radius != radius ||
      old.scrim != scrim ||
      old.ring != ring;
}

/// 缩放滑条. 无障碍要求每个手势操作都有非手势的替代, 它是双指缩放的替代.
class _ZoomSlider extends StatelessWidget {
  const new({required this.zoom, required this.max, required this.onChanged});

  final double zoom;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
      child: Row(
        children: [
          ExcludeSemantics(
            child: EatIcon(EatIcons.image, size: 16, color: c.paper),
          ),
          Expanded(
            child: Slider(
              value: zoom.clamp(1.0, max),
              min: 1,
              max: max,
              activeColor: c.paper,
              inactiveColor: c.paper.withValues(alpha: 0.25),
              thumbColor: c.paper,
              semanticFormatterCallback: (v) => '放大 ${v.toStringAsFixed(1)} 倍',
              onChanged: onChanged,
            ),
          ),
          ExcludeSemantics(
            child: EatIcon(EatIcons.image, size: 22, color: c.paper),
          ),
        ],
      ),
    );
  }
}

// TODO: 接口只保存 "自动去掉背景" 开关, 后端不生成去背景的图片. 后端支持后接入开关并去掉 "待接入".
/// "自动去掉背景" 开关.
class _RemoveBackground extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final paper = eat.colors.paper;
    return EatTappable(
      onTap: () => showPending(context, PendingFeature.removeBackground),
      button: false,
      toggled: false,
      label: '自动去掉背景，待接入',
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Row(
                  spacing: EatSpace.s8,
                  children: [
                    Text(
                      '自动去掉背景',
                      style: eat.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: paper,
                      ),
                    ),
                    const PendingTag(),
                  ],
                ),
                Text(
                  '只留下碗盘，效果不好就关掉',
                  style: eat.text.caption.copyWith(
                    color: paper.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 26,
            padding: const EdgeInsets.all(3),
            alignment: Alignment.centerLeft,
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: paper.withValues(alpha: 0.25),
            ),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle, color: paper),
            ),
          ),
        ],
      ),
    );
  }
}
