import 'dart:async';

import 'package:eat/design/stage/stage_palette.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/crop_viewport.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/stage_color_picker.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// "调整照片" 页面确认返回的结果, 其中 [picked] 为用户手动选定的舞台色, 未手动选择时为 null.
class const CropResult({
  required final CoverCrop crop,
  required final StageSuggestion suggestion,
  final StageColor? picked,
});

/// 调整菜品封面取景与舞台色的页面.
///
/// - 上方区域支持拖动与双指缩放以将主菜移入取景圈, 并提供缩放滑条作为双指缩放的替代交互.
/// - 下方区域展示从取景圈内提取的三个推荐舞台色及首页效果预览.
///
/// 因页面依赖内存中的照片数据且无法通过 URL 恢复状态, 故不纳入路由表, 而是由加菜页通过 `Navigator.push` 打开.
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

  /// 照片原始像素宽度; [height] 为对应的像素高度.
  final int width;
  final int height;

  /// 用于取色计算的缩略图样本; 裁切变化时直接复用该样本重算推荐色, 避免重复解码原图.
  final Future<StageSample> sample;
  final CoverCrop crop;

  /// 分类默认舞台色; 当照片整体偏灰导致取色不可靠时, 该颜色排在推荐色首位.
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

  /// 更新封面裁切范围: 照片位置立即响应变化, 而推荐色在拖动停止并经过防抖后重算.
  ///
  /// 因取色计算在主线程执行, 防抖可避免拖动过程中的每一帧都触发重算.
  void _setCrop(CircleCrop crop) {
    setState(
      () => _crop = CoverCrop(
        centerX: crop.centerX,
        centerY: crop.centerY,
        diameter: crop.diameter,
      ),
    );
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), _resuggest);
  }

  CircleCrop get _circle => (
    centerX: _crop.centerX,
    centerY: _crop.centerY,
    diameter: _crop.diameter,
  );

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
    final safe = MediaQuery.viewPaddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // 缩放滑条是 Material 组件, 需要 Material 祖先.
      child: Material(
        color: c.cropGround,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: c.paper),
          child: Column(
            children: [
              SizedBox(height: safe.top),
              _TopBar(
                onCancel: () => Navigator.of(context).pop(),
                onDone: _done,
              ),
              Expanded(
                child: CropViewport(
                  image: widget.image,
                  width: widget.width,
                  height: widget.height,
                  crop: _circle,
                  onChanged: _setCrop,
                ),
              ),
              Text(
                '拖动或缩放，将主菜移入圆框内',
                style: eat.text.meta.copyWith(
                  color: c.paper.withValues(alpha: 0.7),
                ),
              ),
              CropZoomSlider(
                crop: _circle,
                width: widget.width,
                height: widget.height,
                onChanged: _setCrop,
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
                    safe.bottom + EatSpace.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                  style: eat.text.subhead.copyWith(
                    fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
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
              style: eat.text.subhead.copyWith(color: eat.colors.paper),
            ),
          ),
        ),
        action('完成', onDone, strong: true),
      ],
    );
  }
}
