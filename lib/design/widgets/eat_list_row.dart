import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:flutter/widgets.dart';

/// 无卡片的列表行. 左侧为缩略图或头像, 中间为两到三行文字, 右侧为可选内容.
///
/// - [title] 默认使用 `row-title`. [lines] 的每一行默认使用 `meta` 和 `ink-muted`.
/// - 消息正文等需要其他样式的行, 传入自定义的 `Text`.
/// - 整行可点时, 整行是一个链接. [action] 独立可点, 不属于整行链接.
/// - 行间距由列表提供. 行本身不加背景, 圆角和分隔线.
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

  /// 缩略图 [ListThumb] 或头像 [EatAvatar].
  final Widget? leading;

  final Widget title;

  final List<Widget> lines;

  /// 右侧内容, 属于整行链接的一部分, 如时间, 价格和相关菜品的缩略图.
  final Widget? trailing;

  /// 独立可点的按钮, 如 "回关" 和收藏. 每行最多一个.
  final Widget? action;

  /// 是否未读. 未读时行首显示 [UnreadDot], 位于页面左边距内.
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

/// 未读标记圆点. 已读后不再显示.
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

/// 列表分组的小标题, 如 "今天" "本周" "主食".
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

/// 列表中的方圆角缩略图. 图片加载完成前显示 `mist` 底.
///
/// 尺寸不小于 [EatSize.thumbLg] 时使用 `radius-thumb-lg`, 其余使用 `radius-thumb`.
class ListThumb extends StatelessWidget {
  const new({super.key, required this.image, this.size = EatSize.thumb});

  final ImageProvider? image;

  /// 边长. 消息用 48, 选店用 52, 足迹用 56, 附近用 64.
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

/// 圆形头像. 没有头像图时显示名字的首字, 底色取一个舞台色, 字色随底色深浅.
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
