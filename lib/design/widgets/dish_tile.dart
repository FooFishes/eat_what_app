import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:flutter/widgets.dart';

/// 菜品方块的两列网格.
///
/// 按行排列且行高由该行内容决定, 避免系统字号放大使菜名变高时方块发生溢出.
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

/// 推荐流和 "我的" 页面中的菜品方块, 上方为原图裁成的圆角方图, 文字位于图片下方.
///
/// - 第一行: 菜名在左, 价格在右. 菜名过长时截断, 价格始终完整显示.
/// - 第二行: 店名和距离在左, 评分和赞数在右; 均无数据时不占这一行.
/// - 文字不叠加在图片上.
/// - 方块不加底色, 边框, 阴影和盘沿.
/// - 整个方块作为整体可点击链接.
///
/// 方块之间的间距由 [SliverTileGrid] 提供.
class DishTile extends StatelessWidget {
  const new({
    super.key,
    required this.image,
    required this.name,
    this.price,
    this.shop,
    this.distance,
    this.likes,
    this.score,
    this.compact = false,
    required this.onTap,
  });

  final ImageProvider? image;
  final String name;

  /// 价格文字 (如 "¥ 18"), 为 null 时不显示.
  final String? price;

  /// 店名, 用于推荐流和搜索结果.
  final String? shop;

  /// 距离文字 (如 "320 m"), 跟在店名后面; 店名过长时只截断店名.
  final String? distance;

  /// 赞数, 用于 "我的" 和餐厅详情.
  final int? likes;

  /// 平均分文字 (如 "4.3 分"), 用于餐厅详情, 排在赞数前面. 窄版式不显示.
  final String? score;

  /// 三列排列时使用的窄版式: 图片为正方形, 菜名独占第一行, 价格移到第二行, 且不显示店名和距离.
  ///
  /// 窄版式宽度约为 108px, 若价格与菜名同一行, 菜名只能显示三个字.
  final bool compact;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final meta = eat.text.meta.copyWith(color: c.inkMuted);
    final count = eat.text.count.copyWith(color: c.inkMuted);
    final hasSecond =
        shop != null ||
        distance != null ||
        likes != null ||
        (score != null && !compact) ||
        (compact && price != null);
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
            borderRadius: BorderRadius.all(
              compact ? EatRadius.thumbLg : EatRadius.tile,
            ),
            child: compact
                ? AspectRatio(aspectRatio: 1, child: CoverImage(image: image))
                : SizedBox(height: 150, child: CoverImage(image: image)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: EatSpace.s8,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: eat.text.subhead.copyWith(color: c.ink),
                    ),
                  ),
                  if (price case final price? when !compact)
                    Text(
                      price,
                      style: eat.text.priceInline.copyWith(color: c.ink),
                    ),
                ],
              ),
              if (hasSecond)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (price case final price? when compact)
                      Expanded(
                        child: Text(
                          price,
                          style: eat.text.priceInline.copyWith(
                            fontSize: 14,
                            height: 20 / 14,
                            color: c.ink,
                          ),
                        ),
                      ),
                    if (shop case final shop? when !compact)
                      Flexible(
                        child: Text(
                          shop,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: meta,
                        ),
                      ),
                    if (distance case final distance? when !compact) ...[
                      if (shop != null) const SizedBox(width: EatSpace.s8),
                      Text(distance, style: count),
                    ],
                    if (!compact && (shop != null || distance != null))
                      if (score != null || likes != null) const Spacer(),
                    if (score case final score? when !compact) ...[
                      Text(score, semanticsLabel: '评分 $score', style: count),
                      if (likes != null) const SizedBox(width: EatSpace.s10),
                    ],
                    if (likes case final likes?) ...[
                      EatIcon(EatIcons.heart, size: 14, color: c.inkMuted),
                      const SizedBox(width: EatSpace.s4),
                      Text('$likes', semanticsLabel: '$likes 个赞', style: count),
                    ],
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
