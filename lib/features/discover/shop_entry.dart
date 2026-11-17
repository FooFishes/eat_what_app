import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 发现页抽屉里的一家推荐店, 排成精选榜单的一项. 一家店压在约 230 高, 展开抽屉时一屏能看到两家多.
///
/// - 店名前面一个浅色的大号序号 (01, 02), 对应转盘上 "这一批的第几家", 让列表读起来是挑过的, 不是搜出来的. 抽屉保持白底, 不用颜色.
/// - 店名下面一行: 推荐率的比例条和 "86% 推荐", 后面跟距离, 商圈和品类, 一层比一层弱.
/// - 只有店名跟在序号后面; 下面一行, 照片和照片下的说明都从页面左边距开始, 共用一条左边线.
/// - 菜排成同高的一行, 第一道是 "店的脸", 宽度是其他菜的两倍. 只有一道时图在左, 菜名和价格在右.
/// - 菜用圆角方图直接放原图, 不套盘沿, 带盘沿的盘子只给舞台上的主角.
/// - 第一次出现时淡入上移, 相邻条目依次错开; 照片按下时轻微缩小. 系统开启减少动态效果时都直接到终点.
class ShopEntry extends ConsumerWidget {
  const new({
    super.key,
    required this.shop,
    required this.index,
    required this.onTap,
    required this.onDishTap,
  });

  final Shop shop;

  /// 在列表中的位置, 从 0 开始. 用于序号和入场的错开.
  final int index;
  final VoidCallback onTap;
  final ValueChanged<ShopDish> onDishTap;

  /// 最多排几道菜, 与推荐卡片返回的代表菜上限一致.
  static const dishesMax = 3;

  /// 两家店之间的间距. 比一家店内部的间距大得多, 不需要分隔线.
  static const gap = 32.0;

  /// 菜照片的高度. 三道菜时主图约 8:5, 另外两道约 4:5.
  static const photoHeight = 104.0;

  /// 菜与菜之间的间距.
  static const _dishGap = EatSpace.s8;

  /// 第一道菜占的宽度份数, 其他菜各占一份.
  static const _heroFlex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dishes = shop.signatures.take(dishesMax).toList();
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
              onTap: onTap,
            ),
            switch (dishes) {
              [] => const SizedBox.shrink(),
              [final dish] => _SoloDish(
                dish: dish,
                width: (content - EatSpace.s14) / 2,
                onTap: () => onDishTap(dish),
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
                        onTap: () => onDishTap(dish),
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

/// 店名一栏: 序号和店名, 下面一行推荐理由, 距离和要点.
class _Header extends StatelessWidget {
  const new({
    required this.shop,
    required this.index,
    required this.distance,
    required this.onTap,
  });

  final Shop shop;
  final int index;
  final String? distance;
  final VoidCallback onTap;

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
        Text(distance, style: eat.text.count.copyWith(color: c.inkMuted)),
      for (final fact in [?shop.hubName, ?shop.categories.firstOrNull?.label])
        Flexible(
          child: Text(
            fact,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: meta,
          ),
        ),
    ];
    return EatTappable(
      onTap: onTap,
      button: false,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
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
              Flexible(
                child: Text(
                  shop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.heading.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
          if (line.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(spacing: EatSpace.s10, children: line),
          ],
        ],
      ),
    );
  }
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

/// [ShopEntry] 列表的加载占位: 序号和店名两行, 下面一行主图和两张小图的形状.
class ShopEntryPlaceholder extends StatelessWidget {
  const new({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => LoadingArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
      child: Column(
        spacing: ShopEntry.gap,
        children: [
          for (var i = 0; i < count; i++)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: EatSpace.s10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: EatSpace.s8,
                  children: [
                    Skeleton.line(width: 140, fontSize: 20),
                    Skeleton.line(width: 200, fontSize: 13),
                  ],
                ),
                Row(
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
        ],
      ),
    ),
  );
}
