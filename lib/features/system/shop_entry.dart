import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 一家店, 排成精选榜单的一项. 发现页的推荐带菜, 一家店压在约 230 高, 展开抽屉时一屏能看到两家多;
/// 附近页的列表只要店名一栏 ([dishes] 为 false), 菜在店铺页里看, 店名一栏右边放一张门头小图.
///
/// - 店名前面一个浅色的大号序号 (01, 02), 对应转盘上 "这一批的第几家", 让列表读起来是挑过的, 不是搜出来的. 抽屉保持白底, 不用颜色.
/// - 店名下面一行: 推荐率的比例条和 "86% 推荐", 后面跟距离, 品类和商圈, 各带一个和舞台信息相同的图标, 一层比一层弱.
/// - 店名和下面一行信息都跟在序号后面, 共用店名的起点; 照片和照片下的说明从页面左边距开始, 和序号共用一条左边线.
/// - 菜排成同高的一行, 第一道是 "店的脸", 宽度是其他菜的两倍. 只有一道时图在左, 菜名和价格在右.
/// - 菜用圆角方图直接放原图, 不套盘沿, 带盘沿的盘子只给舞台上的主角.
/// - 第一次出现时淡入上移, 相邻条目依次错开; 照片按下时轻微缩小. 系统开启减少动态效果时都直接到终点.
class ShopEntry extends ConsumerWidget {
  const new({
    super.key,
    required this.shop,
    required this.index,
    required this.onTap,
    this.onDishTap,
    this.dishes = true,
  });

  final Shop shop;

  /// 在列表中的位置, 从 0 开始. 用于序号和入场的错开.
  final int index;
  final VoidCallback onTap;
  final ValueChanged<ShopDish>? onDishTap;

  /// 是否在店名下面排一行菜.
  final bool dishes;

  /// 最多排几道菜, 与推荐卡片返回的代表菜上限一致.
  static const dishesMax = 3;

  /// 菜照片的高度. 三道菜时主图约 8:5, 另外两道约 4:5.
  static const photoHeight = 104.0;

  /// 菜与菜之间的间距.
  static const _dishGap = EatSpace.s8;

  /// 第一道菜占的宽度份数, 其他菜各占一份.
  static const _heroFlex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dishes = this.dishes
        ? shop.signatures.take(dishesMax).toList()
        : const <ShopDish>[];
    final content = MediaQuery.sizeOf(context).width - EatSpace.s20 * 2;
    final unit =
        (content - _dishGap * (dishes.length - 1)) /
        (dishes.length - 1 + _heroFlex);
    return _Reveal(
      order: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: EatSpace.s10,
          children: [
            _Header(
              shop: shop,
              index: index,
              distance: ref.watch(distanceToProvider(shop.point)),
              storefront: !this.dishes,
              onTap: onTap,
            ),
            if (dishes.isNotEmpty)
              switch (dishes) {
                [final dish] => _SoloDish(
                  dish: dish,
                  width: (content - EatSpace.s14) / 2,
                  onTap: () => onDishTap?.call(dish),
                ),
                _ => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: _dishGap,
                  children: [
                    for (final (i, dish) in dishes.indexed)
                      Expanded(
                        flex: i == 0 ? _heroFlex : 1,
                        child: _DishTile(
                          dish: dish,
                          width: unit * (i == 0 ? _heroFlex : 1),
                          onTap: () => onDishTap?.call(dish),
                        ),
                      ),
                  ],
                ),
              },
          ],
        ),
      ),
    );
  }
}

/// 两家店之间的分隔: 一条 `hairline` 细线, 上下留白.
///
/// 上一家以菜名和价格的小字结尾, 下一家以店名开头, 只靠留白时两段文字连在一起读. 细线只画在左右边距之内, 和照片共用左边线, 读起来还是同一张榜单.
class ShopEntryDivider extends StatelessWidget {
  const new({super.key});

  /// 细线上下各自的留白.
  static const space = EatSpace.s16;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: EatSpace.s20,
      vertical: space,
    ),
    child: SizedBox(
      height: 1,
      child: ColoredBox(color: context.eat.colors.hairline),
    ),
  );
}

/// 店名一栏: 序号和店名, 下面一行推荐理由, 距离和要点; [storefront] 时右边加门头小图.
class _Header extends StatelessWidget {
  const new({
    required this.shop,
    required this.index,
    required this.distance,
    required this.storefront,
    required this.onTap,
  });

  final Shop shop;
  final int index;
  final String? distance;
  final bool storefront;
  final VoidCallback onTap;

  /// 门头小图的边长, 和店名加信息行差不多高.
  static const storefrontSize = EatSize.thumb;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final meta = eat.text.meta.copyWith(color: c.inkMuted);
    final rate = ShopRules.rateOf(shop);
    final line = <Widget>[
      if (shop.closed) Text('已关门', style: meta.copyWith(color: c.warn)),
      if (rate != null) _Reason(rate: rate),
      if (distance case final distance?)
        _Fact(
          EatIcons.pin,
          distance,
          style: eat.text.count.copyWith(color: c.inkMuted),
        ),
      if (shop.categories.firstOrNull?.label case final category?)
        Flexible(child: _Fact(EatIcons.utensils, category, style: meta)),
      if (shop.hubName case final hub?)
        Flexible(child: _Fact(EatIcons.district, hub, style: meta)),
    ];
    return EatTappable(
      onTap: onTap,
      button: false,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: EatSpace.s10,
        children: [
          ExcludeSemantics(
            child: Text(
              '${index + 1}'.padLeft(2, '0'),
              // 等宽数字, 各家店名的起点一致.
              style: eat.text.stat.copyWith(
                color: c.handle,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // 店名和下面的信息行放在同一列, 共用店名的起点; 序号对着这一列上下居中.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.heading.copyWith(color: c.ink),
                ),
                if (line.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(spacing: EatSpace.s14, children: line),
                ],
              ],
            ),
          ),
          if (storefront)
            ListThumb(
              image: networkImage(shop.photo, width: storefrontSize),
              size: storefrontSize,
            ),
        ],
      ),
    );
  }
}

/// 店名下的一项信息: 前置图标和单行文字, 图标尺寸与颜色跟随文字, 写法与舞台上的信息条目一致.
class _Fact extends StatelessWidget {
  const new(this.icon, this.text, {required this.style});

  final EatIcons icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: EatSpace.s4,
    children: [
      EatIcon(
        icon,
        size: MediaQuery.textScalerOf(context).scale(style.fontSize ?? 13),
        color: style.color,
      ),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    ],
  );
}

/// 推荐理由: 推荐率的比例条和百分比.
class _Reason extends StatelessWidget {
  const new({required this.rate});

  final ShopRateView rate;

  static const _barWidth = 44.0;
  static const _barHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(EatRadius.pill),
            child: SizedBox(
              width: _barWidth,
              height: _barHeight,
              child: ColoredBox(
                color: c.mist,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: rate.percent / 100,
                  child: ColoredBox(color: c.ink),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: EatSpace.s8),
        Text(
          '${rate.percent}%',
          style: eat.text.count.copyWith(
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
        ),
        const SizedBox(width: EatSpace.s4),
        Text(
          rate.scene == RatingScene.delivery ? '外卖推荐' : '推荐',
          style: eat.text.meta.copyWith(
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
        ),
      ],
    );
  }
}

/// 一行里的一道菜: 定高的照片, 下面菜名和价格各占一行. 窄图上菜名和价格挤在一行时菜名只剩两三个字, 所以分开.
class _DishTile extends StatelessWidget {
  const new({required this.dish, required this.width, required this.onTap});

  final ShopDish dish;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final price = DishRules.priceText(dish.price);
    return _Pressable(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: ShopEntry.photoHeight,
            child: _Photo(dish: dish, width: width),
          ),
          const SizedBox(height: EatSpace.s4 + 2),
          _DishName(dish: dish, style: eat.text.meta),
          if (price != null)
            Text(
              price,
              style: eat.text.count.copyWith(
                fontWeight: FontWeight.w700,
                color: eat.colors.ink,
              ),
            ),
        ],
      ),
    );
  }
}

/// 只有一道菜时: 照片在左, 菜名, 价格和平均分在右, 高度和一行菜相同.
class _SoloDish extends StatelessWidget {
  const new({required this.dish, required this.width, required this.onTap});

  final ShopDish dish;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Pressable(
    onTap: onTap,
    child: Row(
      spacing: EatSpace.s14,
      children: [
        SizedBox(
          width: width,
          height: ShopEntry.photoHeight,
          child: _Photo(dish: dish, width: width),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              _DishName(
                dish: dish,
                style: context.eat.text.subhead,
                maxLines: 2,
              ),
              _PriceLine(dish: dish),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 可点的照片块: 按下时轻微缩小, 松开复原, 不变暗.
class _Pressable extends StatelessWidget {
  const new({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => EatTappable(
    onTap: onTap,
    button: false,
    dimOnPress: false,
    focusShape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(EatRadius.thumbLg),
    ),
    builder: (context, pressed) => AnimatedScale(
      scale: pressed ? EatMotion.tilePressScale : 1,
      duration: context.motion(EatMotion.press),
      curve: EatMotion.press.curve,
      child: child,
    ),
  );
}

/// 圆角照片, 直接放原图. 没有照片或加载失败时由 [CoverImage] 显示 `mist` 底, 加载完成后淡入.
///
/// [width] 是照片的显示宽度, 用于按显示尺寸解码.
class _Photo extends StatelessWidget {
  const new({required this.dish, required this.width});

  final ShopDish dish;
  final double width;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.all(EatRadius.thumbLg),
    child: SizedBox.expand(
      child: CoverImage(image: networkImage(dish.photo, width: width)),
    ),
  );
}

/// 菜名; 编辑者标过的招牌菜在菜名前加一个 `ink` 实心的 "招牌" 小签, 不压在照片上.
class _DishName extends StatelessWidget {
  const new({required this.dish, required this.style, this.maxLines = 1});

  final ShopDish dish;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Text.rich(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: [
          if (dish.signature) ...[
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: eat.colors.ink,
                  borderRadius: const BorderRadius.all(EatRadius.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '招牌',
                    style: eat.text.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: eat.colors.paper,
                    ),
                  ),
                ),
              ),
            ),
            const WidgetSpan(child: SizedBox(width: EatSpace.s4)),
          ],
          TextSpan(text: dish.name),
        ],
      ),
      style: style.copyWith(fontWeight: FontWeight.w600, color: eat.colors.ink),
    );
  }
}

/// 价格和平均分. 都没有时不占位置; 一行放不下 (如系统字号调大) 时平均分换到下一行.
class _PriceLine extends StatelessWidget {
  const new({required this.dish});

  final ShopDish dish;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final price = DishRules.priceText(dish.price);
    final score = DishRules.scoreText(dish.rating);
    if (price == null && score == null) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: [
          if (price != null)
            TextSpan(
              text: price,
              style: eat.text.priceInline.copyWith(color: eat.colors.ink),
            ),
          if (price != null && score != null)
            const WidgetSpan(child: SizedBox(width: EatSpace.s8)),
          if (score != null)
            TextSpan(
              text: score,
              semanticsLabel: '评分 $score',
              style: eat.text.count.copyWith(color: eat.colors.inkMuted),
            ),
        ],
      ),
    );
  }
}

/// 第一次出现时从下方淡入上移. [order] 决定错开的先后, 一屏之外的条目不再额外等待.
class _Reveal extends StatefulWidget {
  const new({required this.order, required this.child});

  final int order;
  final Widget child;

  /// 参与错开的条目数. 首屏大约能放下这么多家, 再往后的条目滚动出现时立即开始.
  static const _staggered = 4;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: EatMotion.reveal.curve,
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final duration = context.motion(EatMotion.reveal);
    if (duration == Duration.zero) {
      _controller.value = 1;
      return;
    }
    _controller.duration = duration;
    final delay =
        EatMotion.revealStagger *
        (widget.order < _Reveal._staggered ? widget.order : 0);
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _curve.value) * EatMotion.revealOffset),
        child: child,
      ),
    ),
    child: widget.child,
  );
}

/// [ShopEntry] 列表的加载占位: 序号和店名两行, 带菜时下面一行主图和两张小图的形状.
class ShopEntryPlaceholder extends StatelessWidget {
  const new({super.key, this.count = 3, this.dishes = true});

  final int count;
  final bool dishes;

  @override
  Widget build(BuildContext context) => LoadingArea(
    child: Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const ShopEntryDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: EatSpace.s10,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: EatSpace.s8,
                        children: [
                          Skeleton.line(width: 140, fontSize: 20),
                          Skeleton.line(width: 200, fontSize: 13),
                        ],
                      ),
                    ),
                    if (!dishes)
                      const Skeleton(
                        width: _Header.storefrontSize,
                        height: _Header.storefrontSize,
                        radius: EatRadius.thumb,
                      ),
                  ],
                ),
                if (dishes)
                  const Row(
                    spacing: ShopEntry._dishGap,
                    children: [
                      Expanded(
                        flex: ShopEntry._heroFlex,
                        child: Skeleton(
                          height: ShopEntry.photoHeight,
                          radius: EatRadius.thumbLg,
                        ),
                      ),
                      Expanded(
                        child: Skeleton(
                          height: ShopEntry.photoHeight,
                          radius: EatRadius.thumbLg,
                        ),
                      ),
                      Expanded(
                        child: Skeleton(
                          height: ShopEntry.photoHeight,
                          radius: EatRadius.thumbLg,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
