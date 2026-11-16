import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:flutter/widgets.dart';

/// 根据地址创建图片来源, 缓存按 [imageCacheKey] 查找.
///
/// 测试中替换为内存图片, 因为磁盘缓存依赖测试环境中没有的平台插件.
@visibleForTesting
ImageProvider Function(String url) networkImageFactory = (url) =>
    CachedNetworkImageProvider(url, cacheKey: imageCacheKey(url));

/// 提取图片缓存 key, 即去掉查询串和片段后的基础地址.
///
/// 接口返回的图片地址为带有效期的预签名 URL, 若以含签名的完整地址作 key, 每次请求都会导致缓存未命中且旧地址过期后无法加载.
/// 由于存储文件名包含随机 ID, 图片内容更新时路径也会随之改变, 因此仅凭路径即可区分图片.
String imageCacheKey(String url) {
  final end = url.indexOf(RegExp('[?#]'));
  return end < 0 ? url : url.substring(0, end);
}

/// 创建网络图片来源; 当地址为空时返回 null, 由组件显示 `mist` 占位底色.
///
/// - Android 与 iOS 启用磁盘缓存使已浏览图片离线可见, Web 则依赖浏览器的 HTTP 缓存.
/// - 内存和磁盘缓存均按 [imageCacheKey] 索引, 即使签名变化也能命中同一张图片的缓存.
/// - 指定 [width] (逻辑像素) 时按显示宽度乘以屏幕密度解码, 避免将原图完整解码到内存中.
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

/// 按 `cover` 方式裁切并铺满父容器的图片组件.
///
/// - 加载过程中显示 `mist` 底色, 下载完成后淡入图片.
/// - 缺图或加载失败时在 `mist` 底中央显示图片图标以区分加载态 (不使用插画替代),
///   若短边小于 40 则仅保留 `mist` 底.
class CoverImage extends StatelessWidget {
  const new({super.key, required this.image, this.semanticLabel});

  final ImageProvider? image;

  /// 读屏朗读的描述文本; 仅当菜品图独立出现时填写.
  ///
  /// 舞台主图和列表缩略图旁已有菜名说明, 此时应留空以将图片标记为纯装饰.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    final placeholder = ColoredBox(color: c.mist);
    final missing = LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return ColoredBox(
          color: c.mist,
          child: side.isFinite && side >= 40
              ? Center(
                  child: EatIcon(
                    EatIcons.image,
                    size: (side * 0.28).clamp(18.0, 32.0),
                    color: c.disabledFg,
                  ),
                )
              : null,
        );
      },
    );
    final image = this.image;
    if (image == null) return missing;
    return Image(
      image: image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      // 内存缓存中的图片直接同步显示, 异步加载的图片则在 `mist` 底上淡入.
      frameBuilder: (context, child, frame, synchronous) => synchronous
          ? child
          : Stack(
              fit: StackFit.expand,
              children: [
                placeholder,
                AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: context.motion(EatMotion.select),
                  curve: EatMotion.select.curve,
                  child: child,
                ),
              ],
            ),
      errorBuilder: (context, error, stackTrace) => missing,
    );
  }
}
