import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:flutter/widgets.dart';

/// 根据地址创建图片来源, 缓存按 [imageCacheKey] 查找.
///
/// 测试中替换为内存图片, 因为磁盘缓存依赖测试环境中没有的平台插件.
@visibleForTesting
ImageProvider Function(String url) networkImageFactory = (url) =>
    CachedNetworkImageProvider(url, cacheKey: imageCacheKey(url));

/// 图片缓存的 key: 去掉查询串和片段后的地址.
///
/// 接口返回的图片地址是带有效期的预签名地址, 签名在查询串中, 每次请求都不同.
/// 以完整地址作 key 时缓存无法命中, 缓存数据中的旧地址过期后也无法加载.
/// 存储中的文件名含随机 id, 图片内容变化时路径随之变化, 因此路径足以区分图片.
String imageCacheKey(String url) {
  final end = url.indexOf(RegExp('[?#]'));
  return end < 0 ? url : url.substring(0, end);
}

/// 创建网络图片来源. 没有地址时返回 null, 组件显示 `mist` 底.
///
/// - Android 和 iOS 使用磁盘缓存, 浏览过的图片离线可见. Web 依赖浏览器的 HTTP 缓存.
/// - 内存和磁盘缓存都按 [imageCacheKey] 查找, 签名不同的同一张图片也能命中缓存.
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
