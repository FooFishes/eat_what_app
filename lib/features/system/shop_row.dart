import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: 缩略图应为招牌菜封面, 店铺列表接口没有该字段, 目前用门头照片代替. 接口返回招牌菜封面后改用封面.
/// 店铺行: 缩略图, 店名, 距离和商圈, 地址. 用于附近页抽屉和搜索页的 "店" 分栏.
///
/// 没有门头照片时缩略图为 `mist` 底.
/// [extra] 是额外的一行说明, 如按菜名搜索时的 "有 酸辣粉 ¥12".
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

  /// 缩略图地址. 不传时使用门头照片.
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
