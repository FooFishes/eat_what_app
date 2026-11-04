import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 店铺行: 缩略图, 店名, 距离和商圈, 地址. 用于附近页抽屉和搜索页的 "店" 分栏.
///
/// - 缩略图依次取 [image], 第一道招牌菜的封面, 门头照片. 都没有时为 `mist` 底.
/// - 已关门的店在距离前标明 "已关门".
/// - 第二行依次取 [extra], 按菜名搜索匹配到的菜 (如 "有 酸辣粉 ¥12"), 地址.
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
    final distance = ref.watch(distanceToProvider(shop.point));
    final hub = ref.watch(hubNameProvider(shop.hubId));
    final where = [if (shop.closed) '已关门', ?distance, ?hub].join('  ');
    final matched = shop.matched.firstOrNull;
    final matchedLine = matched == null
        ? null
        : ['有', matched.name, ?DishRules.priceText(matched.price)].join(' ');
    return EatListRow(
      leading: ListThumb(
        image: networkImage(
          image ?? shop.cover ?? shop.photos.firstOrNull,
          width: EatSize.thumbLg,
        ),
        size: EatSize.thumbLg,
      ),
      title: Text(shop.name),
      lines: [
        if (where.isNotEmpty) Text(where),
        if (extra ?? matchedLine ?? shop.address case final line?) Text(line),
      ],
      onTap: onTap,
    );
  }
}
