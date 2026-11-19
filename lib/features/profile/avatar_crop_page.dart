import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/crop_viewport.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// 更换头像时的裁切页面, 支持拖动, 双指缩放或滑条调节取景区域, 交互手势与 "调整照片" 一致.
///
/// 点击 "完成" 返回裁切结果; 因页面依赖内存图片数据, 不纳入路由表, 由编辑资料页通过 `Navigator.push` 打开.
class AvatarCropPage extends StatefulWidget {
  const new({
    super.key,
    required this.image,
    required this.width,
    required this.height,
  });

  final ImageProvider image;

  /// 照片的像素宽度. [height] 为像素高度.
  final int width;
  final int height;

  static Route<CircleCrop> route({
    required ImageProvider image,
    required int width,
    required int height,
  }) => MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => AvatarCropPage(image: image, width: width, height: height),
  );

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  CircleCrop _crop = (centerX: 0.5, centerY: 0.5, diameter: 1.0);

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final safe = MediaQuery.viewPaddingOf(context);
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
                    color: c.white,
                  ),
                ),
              ),
            ),
          ),
        );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // 缩放滑条是 Material 组件, 需要 Material 祖先.
      child: Material(
        color: c.cropGround,
        child: Column(
          children: [
            SizedBox(height: safe.top),
            Row(
              children: [
                action('取消', () => Navigator.of(context).pop()),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      '调整头像',
                      textAlign: TextAlign.center,
                      style: eat.text.subhead.copyWith(color: c.white),
                    ),
                  ),
                ),
                action(
                  '完成',
                  () => Navigator.of(context).pop(_crop),
                  strong: true,
                ),
              ],
            ),
            Expanded(
              child: CropViewport(
                image: widget.image,
                width: widget.width,
                height: widget.height,
                crop: _crop,
                onChanged: (crop) => setState(() => _crop = crop),
              ),
            ),
            Text(
              '拖动或缩放，将头像移入圆框内',
              style: eat.text.meta.copyWith(
                color: c.white.withValues(alpha: 0.7),
              ),
            ),
            CropZoomSlider(
              crop: _crop,
              width: widget.width,
              height: widget.height,
              onChanged: (crop) => setState(() => _crop = crop),
            ),
            SizedBox(height: safe.bottom + EatSpace.s24),
          ],
        ),
      ),
    );
  }
}
