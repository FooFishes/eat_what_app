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

/// 店铺列表行组件, 用于附近页抽屉, 搜索页店铺分栏及我的收藏列表.
///
/// - 缩略图优先取 [image], 其次取门头照片, 均无时显示 `mist` 占位底色.
/// - 元信息首行依次展示 "已关门" 标识, 距离与商圈名, 次行展示地址.
/// - 第三行依次取 [extra], 搜店命中的菜品 (如 "有 \"鲜虾蟹籽云吞\" ¥ 18") 或首道招牌菜 (如 "招牌: 鲜虾蟹籽云吞"). 常规店铺接口不返回招牌菜, 仅推荐流数据携带.
/// - 右侧推荐率依据 [ShopRules.rateOf] 展示, 未达评价门槛时隐藏, 外卖场景标注为 "外卖推荐".
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

  /// 自定义缩略图地址, 为 null 时回退至店铺门头照.
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
