import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:flutter/widgets.dart';

/// 两列方块的网格，排法和设计稿一样：列间距 `space-14`、行间距 18。
///
/// 按行排、每行高度跟着内容走：系统字号放大后菜名变高也不会溢出。
class SliverTileGrid extends StatelessWidget {
  const new({super.key, required this.count, required this.builder});

  final int count;
  final IndexedWidgetBuilder builder;

  @override
  Widget build(BuildContext context) => SliverList.separated(
    itemCount: (count + 1) ~/ 2,
    separatorBuilder: (_, _) => const SizedBox(height: 18),
    itemBuilder: (context, row) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EatSpace.s14,
      children: [
        Expanded(child: builder(context, row * 2)),
        Expanded(
          child: row * 2 + 1 < count
              ? builder(context, row * 2 + 1)
              : const SizedBox(),
        ),
      ],
    ),
  );
}

/// 推荐流和「我的」里的菜品方块：上面一张直接用原图的圆角方图，菜名和店名写在图外面。
///
/// 两列网格，列间距 `space-14`、行间距 18 由网格给。不把文字压在图上，不给方块加底色、边框、阴影，
/// 也不套盘沿。整块是一个链接。
class DishTile extends StatelessWidget {
  const new({
    super.key,
    required this.image,
    required this.name,
    this.shop,
    this.likes,
    required this.onTap,
  });

  final ImageProvider? image;
  final String name;

  /// 推荐流里写店名。
  final String? shop;

  /// 「我的」里不写店名，改在菜名右边显示赞数。
  final int? likes;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final title = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: eat.text.tileTitle.copyWith(color: c.ink),
    );
    return EatTappable(
      onTap: onTap,
      button: false,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.tile),
      ),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EatSpace.s8,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(EatRadius.tile),
            child: SizedBox(height: 150, child: CoverImage(image: image)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (likes case final likes?)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: EatSpace.s8),
                    EatIcon(EatIcons.heart, size: 14, color: c.inkMuted),
                    const SizedBox(width: EatSpace.s4),
                    Text(
                      '$likes',
                      semanticsLabel: '$likes 个赞',
                      style: eat.text.count.copyWith(color: c.inkMuted),
                    ),
                  ],
                )
              else
                title,
              if (shop case final shop?)
                Text(
                  shop,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.meta.copyWith(color: c.inkMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
