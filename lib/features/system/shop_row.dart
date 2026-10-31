import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 店铺行：缩略图、店名、距离和商圈、地址。附近的抽屉、搜索的「店」栏都用它（产品 6.7、6.8）。
///
/// 缩略图该用招牌菜的封面，店铺列表接口还没有这个字段（现状差距 2.1），有门头照片用门头照片，
/// 没有时是 `mist` 底。[extra] 是行里额外的一句，如搜菜名时「有 酸辣粉 ¥12」。
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

  /// 不传时用门头照片。
  final String? image;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = ref.watch(distanceToProvider(shop.point));
    final hub = ref.watch(hubNameProvider(shop.hubId));
    final where = [?distance, ?hub].join(' · ');
    return EatListRow(
      leading: ListThumb(
        image: networkImage(
          image ?? shop.photos.firstOrNull,
          width: EatSize.thumbLg,
        ),
        size: EatSize.thumbLg,
      ),
      title: Text(shop.name),
      lines: [
        if (where.isNotEmpty) Text(where),
        if (extra ?? shop.address case final line?) Text(line),
      ],
      onTap: onTap,
    );
  }
}
