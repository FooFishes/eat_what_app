import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show InteractiveViewer, MaterialPageRoute;

/// 看大图：左右翻，双指放大，每张标出是谁拍的（产品 6.5）。
///
/// 只放上传者的照片；评论里的照片等评论接口上线后接在后面。依赖内存里的图片地址，不给路由地址
/// （技术架构 5.1）。
class PhotoViewer extends StatefulWidget {
  const new({super.key, required this.images, this.uploader});

  final List<String> images;
  final String? uploader;

  static Route<void> route({required List<String> images, String? uploader}) =>
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PhotoViewer(images: images, uploader: uploader),
      );

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    return ColoredBox(
      color: eat.colors.ink,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image(
                  image: networkImage(widget.images[i], width: width)!,
                  fit: BoxFit.contain,
                  semanticLabel: '第 ${i + 1} 张照片',
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            ),
          ),
          Positioned(
            top: media.padding.top + 4,
            left: 8,
            child: EatIconButton(
              EatIcons.close,
              label: '关闭',
              color: eat.colors.paper,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: EatSpace.s20,
            right: EatSpace.s20,
            bottom: media.padding.bottom + EatSpace.s24,
            child: Text(
              [
                '${_index + 1} / ${widget.images.length}',
                if (widget.uploader case final name?) '$name 拍的',
              ].join('  ·  '),
              style: eat.text.meta.copyWith(color: eat.colors.paper),
            ),
          ),
        ],
      ),
    );
  }
}
