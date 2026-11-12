import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 店铺行: 缩略图, 店名, 距离和商圈, 地址, 招牌菜. 右侧是推荐率. 用于附近页抽屉和搜索页的 "店" 分栏.
///
/// - 缩略图依次取 [image], 第一道招牌菜的封面, 门头照片. 都没有时为 `mist` 底.
/// - 已关门的店在距离前标明 "已关门".
/// - 第二行是地址. 第三行依次取 [extra], 按菜名搜索匹配到的菜 (如 "有 酸辣粉 ¥12"), 招牌菜 (如 "招牌：鲜虾蟹籽云吞").
/// - 评价满 5 人时右侧显示推荐率, 不满时不显示.
class ShopRow extends ConsumerWidget {
  const new({
    super.key,
    required this.shop,
    this.extra,
    this.image,
    required this.onTap,
  });

  final Shop shop;
  final String? extra;

  /// 缩略图地址.
  final String? image;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final distance = ref.watch(distanceToProvider(shop.point));
    final hub = ref.watch(hubNameProvider(shop.hubId));
    final where = [if (shop.closed) '已关门', ?distance, ?hub].join('  ');
    final matched = shop.matched.firstOrNull;
    final matchedLine = matched == null
        ? null
        : ['有', matched.name, ?DishRules.priceText(matched.price)].join(' ');
    final signature = shop.signatures.firstOrNull;
    final signatureLine = signature == null ? null : '招牌：${signature.name}';
    final rate = shop.recommendRate;
    return EatListRow(
      leading: ListThumb(
        image: networkImage(
          image ?? shop.cover ?? shop.photos.firstOrNull,
          width: EatSize.thumbLg,
        ),
        size: EatSize.thumbLg,
      ),
      title: Text(shop.name, maxLines: 1),
      lines: [
        if (where.isNotEmpty) Text(where),
        if (shop.address case final address?) Text(address),
        if (extra ?? matchedLine ?? signatureLine case final line?)
          Text(line, style: TextStyle(color: eat.colors.inkSoft)),
      ],
      trailing: rate == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$rate%',
                  style: eat.text.priceInline.copyWith(color: eat.colors.ink),
                ),
                Text(
                  '推荐',
                  style: eat.text.caption.copyWith(color: eat.colors.inkMuted),
                ),
              ],
            ),
      onTap: onTap,
    );
  }
}
