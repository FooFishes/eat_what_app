import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_layout.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:flutter/widgets.dart';

/// 没有卡片的列表行：左边缩略图或头像，中间两到三行文字，右边可选的内容；行与行之间只靠留白分开。
///
/// [title] 默认用 `row-title`，[lines] 里的每一行默认 `meta` 加 `ink-muted`；消息正文这类
/// 要换样式的，传自己的 `Text`。整行可点时整行是一个链接，[action] 单独可点、不算在整行里。
/// 行与行之间 16–20px 由列表给，不要给行加背景、圆角或分隔线。
class EatListRow extends StatelessWidget {
  const new({
    super.key,
    this.leading,
    required this.title,
    this.lines = const [],
    this.trailing,
    this.action,
    this.unread = false,
    this.onTap,
  });

  /// 缩略图（[ListThumb]）或头像（[EatAvatar]）。
  final Widget? leading;

  final Widget title;

  final List<Widget> lines;

  /// 整行的一部分：时间、价格、相关菜品的缩略图。
  final Widget? trailing;

  /// 单独可点的按钮，如「回关」、收藏。一行里最多一个。
  final Widget? action;

  /// 未读时行首放一个 7px 的 `ink` 圆点，落在页面左边距里。
  final bool unread;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    Widget content = Row(
      children: [
        if (leading case final leading?) ...[
          leading,
          const SizedBox(width: EatSpace.s14),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              DefaultTextStyle.merge(
                style: eat.text.rowTitle.copyWith(color: eat.colors.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                child: title,
              ),
              for (final line in lines)
                DefaultTextStyle.merge(
                  style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: line,
                ),
            ],
          ),
        ),
        if (trailing case final trailing?) ...[
          const SizedBox(width: EatSpace.s14),
          trailing,
        ],
      ],
    );
    if (unread) {
      content = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          content,
          const Positioned(left: -13, child: UnreadDot()),
        ],
      );
    }
    if (onTap != null) {
      final row = content;
      content = EatTappable(
        onTap: onTap,
        button: false,
        focusShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(EatRadius.thumb),
        ),
        builder: (context, _) => row,
      );
    }
    if (action == null) return content;
    return Row(
      children: [
        Expanded(child: content),
        const SizedBox(width: EatSpace.s14),
        action!,
      ],
    );
  }
}

/// 未读的 7px 圆点，读过就去掉。
class UnreadDot extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: '未读',
    child: Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: context.eat.colors.ink,
        shape: BoxShape.circle,
      ),
    ),
  );
}

/// 列表分组的小标题：「今天」「本周」「主食」。
class ListGroupTitle extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Semantics(
      header: true,
      child: Text(
        text,
        style: eat.text.meta.copyWith(
          fontWeight: FontWeight.w600,
          color: eat.colors.inkMuted,
        ),
      ),
    );
  }
}

/// 列表里的方圆角缩略图。64px 用 `radius-thumb-lg`，其余用 `radius-thumb`；图没加载出来时是 `mist` 底。
class ListThumb extends StatelessWidget {
  const new({super.key, required this.image, this.size = EatSize.thumb});

  final ImageProvider? image;

  /// 48（消息）、52（选店）、56（足迹）或 64（附近）。
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.all(
      size >= EatSize.thumbLg ? EatRadius.thumbLg : EatRadius.thumb,
    ),
    child: SizedBox.square(
      dimension: size,
      child: CoverImage(image: image),
    ),
  );
}

/// 圆形头像。没有头像图时写名字的第一个字，底色取一个舞台色，字色按它的深浅。
class EatAvatar extends StatelessWidget {
  const new({
    super.key,
    required this.name,
    required this.color,
    this.image,
    this.size = EatSize.avatar,
  });

  final String name;
  final StageColor color;
  final ImageProvider? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: image != null
              ? CoverImage(image: image)
              : ColoredBox(
                  color: color.color,
                  child: Center(
                    child: Text(
                      name.characters.firstOrNull ?? '',
                      style: eat.text.rowTitle.copyWith(
                        fontSize: size * 17 / 44,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: color.foreground,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
