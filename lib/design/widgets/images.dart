import 'package:eat/design/theme/eat_theme.dart';
import 'package:flutter/widgets.dart';

/// 铺满父组件的图片，按 `cover` 裁；还没加载出来或加载失败时是 `mist` 底，不用插画顶替。
class CoverImage extends StatelessWidget {
  const new({super.key, required this.image, this.semanticLabel});

  final ImageProvider? image;

  /// 单独出现的菜品图才写；舞台主图、列表缩略图旁边已经有菜名，留空标为装饰。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(color: context.eat.colors.mist);
    final image = this.image;
    if (image == null) return placeholder;
    return Image(
      image: image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      frameBuilder: (context, child, frame, synchronous) =>
          synchronous || frame != null ? child : placeholder,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
