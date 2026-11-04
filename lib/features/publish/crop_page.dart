import 'dart:async';

import 'package:eat/core/env/pending_features.dart';
import 'package:eat/design/stage/stage_palette.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/crop_viewport.dart';
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
                child: CropViewport(
                  image: widget.image,
                  width: widget.width,
                  height: widget.height,
                  crop: _circle,
                  onChanged: _setCrop,
                ),
              ),
              Text(
                '拖动、缩放，把主菜放进圈里',
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
