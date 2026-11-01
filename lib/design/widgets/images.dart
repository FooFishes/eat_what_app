import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:flutter/widgets.dart';

/// 根据地址创建图片来源.
///
/// 测试中替换为内存图片, 因为磁盘缓存依赖测试环境中没有的平台插件.
@visibleForTesting
ImageProvider Function(String url) networkImageFactory =
    CachedNetworkImageProvider.new;

/// 创建网络图片来源. 没有地址时返回 null, 组件显示 `mist` 底.
///
/// - Android 和 iOS 使用磁盘缓存, 浏览过的图片离线可见. Web 依赖浏览器的 HTTP 缓存.
/// - 按显示宽度 [width] (逻辑像素) 乘以屏幕密度解码, 不把原图完整解码到内存.
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

/// 铺满父组件的图片, 按 `cover` 裁切.
///
/// 加载完成前或加载失败时显示 `mist` 底, 不用插画替代.
class CoverImage extends StatelessWidget {
  const new({super.key, required this.image, this.semanticLabel});

  final ImageProvider? image;

  /// 读屏文字. 菜品图单独出现时填写.
  ///
  /// 舞台主图和列表缩略图旁已有菜名, 此时留空, 图片标记为装饰.
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
