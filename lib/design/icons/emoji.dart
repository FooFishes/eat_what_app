import 'package:flutter/widgets.dart';

/// 登录页用到的动画表情. 图片位于 `assets/emoji/`, 每个表情有一张动图和一张取自首帧的静态图.
///
/// 不用系统 emoji 字体: 各平台样式不同, Web 上可能缺字.
///
/// TODO: 素材是 Telegram 的动画表情, 许可没有确认. 上架前要确认可以使用, 否则换成有开放许可的素材.
enum Emoji {
  thinking,
  eyes;

  /// 循环播放的动图.
  String get asset => 'assets/emoji/$name.webp';

  /// 动图的首帧. 系统开启减少动态效果时用它.
  String get still => 'assets/emoji/${name}_still.webp';
}

/// 表情图片. 放在 `WidgetSpan` 里时, [size] 取所在文字的字号.
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
