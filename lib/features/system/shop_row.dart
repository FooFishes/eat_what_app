import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 店铺行: 门头照片, 店名, 距离和商圈, 地址, 招牌菜. 右侧是推荐率. 用于附近页抽屉, 搜索页的 "店" 分栏和收藏的店.
///
/// - 缩略图依次取 [image], 门头照片. 都没有时为 `mist` 底.
/// - 第一行依次是 "已关门", 距离, 商圈名.
/// - 第二行是地址. 第三行依次取 [extra], 搜店时因菜名命中的菜 (如 "有「鲜虾蟹籽云吞」¥18"),
///   第一道招牌菜 (如 "招牌：鲜虾蟹籽云吞"). 店铺接口不带招牌菜, 只有推荐卡片有.
/// - 推荐率按 `ShopRules.rateOf` 显示, 评价不满门槛时不显示. 外卖的推荐率写作 "外卖推荐".
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
    final where = [if (shop.closed) '已关门', ?distance, ?shop.hubName].join('  ');
    final dishLine = switch ((shop.matchedDish, shop.signatures.firstOrNull)) {
      (final matched?, _) => [
        '有「${matched.name}」',
        ?DishRules.priceText(matched.price),
      ].join(' '),
      (null, final signature?) => '招牌：${signature.name}',
      (null, null) => null,
    };
    final rate = ShopRules.rateOf(shop);
    return EatListRow(
      leading: ListThumb(
        image: networkImage(image ?? shop.photo, width: EatSize.thumbLg),
        size: EatSize.thumbLg,
      ),
      title: Text(shop.name, maxLines: 1),
      lines: [
        if (where.isNotEmpty) Text(where),
        if (shop.address case final address?) Text(address),
        if (extra ?? dishLine case final line?)
          Text(line, style: TextStyle(color: eat.colors.inkSoft)),
      ],
      trailing: rate == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${rate.percent}%',
                  style: eat.text.priceInline.copyWith(color: eat.colors.ink),
                ),
                Text(
                  rate.scene == RatingScene.delivery ? '外卖推荐' : '推荐',
                  style: eat.text.caption.copyWith(color: eat.colors.inkMuted),
                ),
              ],
            ),
      onTap: onTap,
    );
  }
}
