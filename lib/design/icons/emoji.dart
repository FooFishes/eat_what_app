import 'package:flutter/widgets.dart';

/// 文案里用到的 emoji. 图片位于 `assets/emoji/`, 取自 Microsoft Fluent Emoji 的 3D 版 (MIT 许可).
///
/// 不用系统 emoji 字体: 各平台样式不同, Web 上可能缺字.
enum Emoji {
  thinking;

  String get asset => 'assets/emoji/$name.png';
}

/// emoji 图片. 放在 `WidgetSpan` 里时, [size] 取所在文字的字号.
class EmojiImage extends StatelessWidget {
  const new(this.emoji, {super.key, required this.size});

  final Emoji emoji;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    emoji.asset,
    width: size,
    height: size,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
}
