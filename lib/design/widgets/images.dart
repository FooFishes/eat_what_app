import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:flutter/widgets.dart';

/// 按地址造图片来源。测试里换成内存图片：磁盘缓存要用到测试环境里没有的平台插件。
@visibleForTesting
ImageProvider Function(String url) networkImageFactory =
    CachedNetworkImageProvider.new;

/// 网络图片：安卓、iOS 有磁盘缓存，看过的图离线能看；Web 靠浏览器缓存（技术架构 10.4）。
///
/// [width] 是显示宽度（逻辑像素），按它乘屏幕密度解码，不把原图整张解码进内存。
/// 没有地址时返回 null，组件显示 `mist` 底。
ImageProvider? networkImage(String? url, {double? width, double dpr = 3}) {
  if (url == null || url.isEmpty) return null;
  final provider = networkImageFactory(url);
  if (width == null) return provider;
  return ResizeImage(
    provider,
    width: (width * dpr).round(),
    policy: ResizeImagePolicy.fit,
  );
}

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
