import 'package:flutter/widgets.dart';

/// 登录页用到的动画表情. 图片位于 `assets/emoji/`, 每个表情有一张动图和一张取自首帧的静态图.
///
/// 不使用系统 emoji 字体, 因为各平台样式不同且 Web 上可能缺字.
///
/// 图形改编自 Twemoji (CC BY 4.0), 动画为自制. 署名和许可证全文位于
/// `assets/emoji/LICENSE-Twemoji.txt`, 启动时登记到许可证页, 更换素材时需同步更新该文件.
enum Emoji {
  thinking,
  eyes;

  /// 循环播放的动图.
  String get asset => 'assets/emoji/$name.webp';

  /// 动图的首帧, 在系统开启减少动态效果时替代动图显示.
  String get still => 'assets/emoji/${name}_still.webp';
}

/// 表情图片组件. 放在 `WidgetSpan` 中时, [size] 取所在文字的字号.
///
/// 系统开启减少动态效果时显示静态图.
class EmojiImage extends StatelessWidget {
  const new(this.emoji, {super.key, required this.size});

  final Emoji emoji;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    MediaQuery.disableAnimationsOf(context) ? emoji.still : emoji.asset,
    width: size,
    height: size,
    filterQuality: FilterQuality.medium,
    gaplessPlayback: true,
    excludeFromSemantics: true,
  );
}
