import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:flutter/widgets.dart';

/// 菜品方块的两列网格.
///
/// 逐行排列, 行高由该行内容决定. 系统字号放大使菜名变高时, 方块不会溢出.
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

/// 推荐流和 "我的" 中的菜品方块. 上方为原图裁成的圆角方图, 菜名和店名位于图片下方.
///
/// - 文字不叠加在图片上.
/// - 方块不加底色, 边框, 阴影和盘沿.
/// - 整个方块是一个链接.
///
/// 方块之间的间距由 [SliverTileGrid] 提供.
class DishTile extends StatelessWidget {
  const new({
    super.key,
    required this.image,
    required this.name,
    this.shop,
    this.distance,
    this.likes,
    required this.onTap,
  });

  final ImageProvider? image;
  final String name;

  /// 店名, 用于推荐流和搜索结果.
  final String? shop;

  /// 距离文字, 如 "320 m". 跟在店名后面, 店名过长时只截断店名.
  final String? distance;

  /// 赞数, 用于 "我的". 显示在菜名右侧, 此时不传店名.
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
      style: eat.text.subhead.copyWith(color: c.ink),
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
              if (distance case final distance?)
                Row(
                  spacing: EatSpace.s8,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (shop case final shop?)
                      Flexible(
                        child: Text(
                          shop,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: eat.text.meta.copyWith(color: c.inkMuted),
                        ),
                      ),
                    Text(
                      distance,
                      style: eat.text.count.copyWith(color: c.inkMuted),
                    ),
                  ],
                )
              else if (shop case final shop?)
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
