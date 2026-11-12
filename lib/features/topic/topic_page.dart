import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/dish_tile.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/topic.dart';
import 'package:eat/domain/rules/topic_rules.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/features/system/shop_actions.dart';
import 'package:eat/features/topic/topic_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 专题页: 专题名, 介绍, 起止时间和菜数, 其下为专题里的菜 (两列方块).
///
/// 从发现页, 往期专题, 菜品详情的专题提示和消息进入. 右上角分享专题链接.
class TopicPage extends ConsumerWidget {
  const new({super.key, required this.topicId});

  final int topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(topicDetailProvider(topicId));
    if (!value.hasValue) {
      return PlainScaffold(
        title: '专题',
        slivers: [
          SliverToBoxAdapter(
            child: value.hasError && !value.isLoading
                ? FailureState(
                    message: (value.error as AppFailure?)?.message,
                    onRetry: () => ref.invalidate(topicDetailProvider(topicId)),
                  )
                : const TileGridPlaceholder(count: 4),
          ),
        ],
      );
    }
    final detail = value.value;
    if (detail == null) {
      return const PlainScaffold(
        title: '专题',
        slivers: [
          SliverToBoxAdapter(
            child: EmptyState(
              icon: EatIcons.topic,
              title: '找不到这期专题',
              message: '可能已撤下，去看看其他推荐的菜。',
            ),
          ),
        ],
      );
    }
    final topic = detail.topic;
    return PlainScaffold(
      title: topic.name,
      subtitle: topic.introduction.isEmpty ? null : topic.introduction,
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [topicDetailProvider(topicId)],
        wait: () => ref.read(topicDetailProvider(topicId).future),
      ),
      actions: [
        EatIconButton(
          EatIcons.share,
          label: '分享',
          onPressed: () => showSharePanel(
            context,
            ref,
            path: Paths.topic(topic.id),
            title: '「${topic.name}」',
          ),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(child: _TopicMeta(topic: topic)),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s24)),
        if (detail.dishes.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: EatIcons.bowl,
              title: '这期专题的菜都已删除',
              message: '去看看其他推荐的菜。',
            ),
          )
        else
          _TopicDishes(detail: detail),
      ],
    );
  }
}

/// 专题的称呼, 起止时间和菜数, 如 "本周专题 10 月 20 日–10 月 26 日 12 道菜".
class _TopicMeta extends StatelessWidget {
  const new({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final now = clock.now();
    final meta = eat.text.meta.copyWith(color: c.inkMuted);
    return Wrap(
      spacing: EatSpace.s14,
      runSpacing: EatSpace.s4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            EatIcon(EatIcons.topic, size: 16, color: c.ink),
            Text(
              TopicRules.kind(topic, now),
              style: meta.copyWith(fontWeight: FontWeight.w600, color: c.ink),
            ),
          ],
        ),
        Text(TopicRules.range(topic, now), style: meta),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${topic.dishCount}',
                style: eat.text.count.copyWith(color: c.ink),
              ),
              const TextSpan(text: ' 道菜'),
            ],
          ),
          style: meta,
        ),
      ],
    );
  }
}

class _TopicDishes extends StatelessWidget {
  const new({required this.detail});

  final TopicDetail detail;

  @override
  Widget build(BuildContext context) {
    final dishes = detail.dishes;
    final width = (MediaQuery.sizeOf(context).width - 54) / 2;
    return SliverTileGrid(
      count: dishes.length,
      builder: (context, i) => DishTile(
        image: networkImage(dishes[i].cover, width: width),
        name: dishes[i].name,
        price: DishRules.priceText(dishes[i].price),
        shop: dishes[i].shopName,
        onTap: () => context.push(Paths.dish(dishes[i].id), extra: dishes[i]),
      ),
    );
  }
}
