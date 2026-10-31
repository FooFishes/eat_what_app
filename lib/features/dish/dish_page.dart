import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/design/widgets/taste_cloud.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/dish/dish_providers.dart';
import 'package:eat/features/dish/photo_viewer.dart';
import 'package:eat/features/dish/tag_panel.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_actions.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/dish_interactions.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 菜品详情（`G-Dish`）：舞台上是封面、分类、菜名、价格；抽屉里依次是店卡、赞和导航、
/// 「大家怎么说」、上传者和「吃过的人说」。
///
/// 从列表进来时用手上的 [initial] 先把舞台画出来，抽屉里的内容等接口（技术架构 10.5）。
/// 评论、专题、举报还没有接口，带「待接入」；编辑自己的菜随发布流程在阶段四做。
class DishPage extends ConsumerWidget {
  const new({super.key, required this.dishId, this.initial});

  final int dishId;
  final Dish? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(dishDetailProvider(dishId));
    final dish = detail.value ?? initial;
    if (dish == null) {
      return StageScaffold(
        stage: StageColor.broth,
        topBar: const _TopBar(dish: null),
        stageContent: detail.hasError && !detail.isLoading
            ? const SizedBox()
            : const StagePlaceholder(),
        sheetSlivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
            sliver: SliverToBoxAdapter(
              child: detail.hasError && !detail.isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: FailureState(
                        message: (detail.error as AppFailure?)?.message,
                        onRetry: () =>
                            ref.invalidate(dishDetailProvider(dishId)),
                      ),
                    )
                  : const RowListPlaceholder(count: 3),
            ),
          ),
        ],
      );
    }
    final loaded = detail.value != null;
    return StageScaffold(
      stage: dish.stage,
      topBar: _TopBar(dish: dish),
      stageContent: _StageContent(dish: dish),
      sheetSlivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: SliverList.list(
            children: [
              _ShopCard(dish: dish),
              const SizedBox(height: EatSpace.s16),
              _Actions(dish: dish),
              const SizedBox(height: 28),
              if (loaded)
                _TasteSection(dish: dish)
              else if (detail.hasError)
                FailureState(
                  message: (detail.error as AppFailure?)?.message,
                  onRetry: () => ref.invalidate(dishDetailProvider(dishId)),
                )
              else
                const RowListPlaceholder(count: 2),
              const SizedBox(height: 28),
              _Uploader(dish: dish),
              const SizedBox(height: 28),
              const _Comments(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  const new({required this.dish});

  final Dish? dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dish = this.dish;
    final interaction = dish == null
        ? null
        : ref.watch(dishInteractionsProvider.select((m) => m[dish.id])) ??
              DishInteraction.of(dish);
    final me = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user?.id,
      SignedOut() => null,
    };
    return Row(
      children: [
        const EatBackButton(),
        const Spacer(),
        if (dish != null && interaction != null) ...[
          EatIconButton(
            interaction.favorite ? EatIcons.bookmarkOn : EatIcons.bookmark,
            label: interaction.favorite ? '取消收藏' : '收藏',
            onPressed: () => _toggleFavorite(context, ref, dish),
          ),
          EatIconButton(
            EatIcons.share,
            label: '分享',
            onPressed: () => showSharePanel(
              context,
              ref,
              path: Paths.dish(dish.id),
              title: dish.name,
              reportable: dish.uploaderId != me,
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  Dish dish,
) async {
  if (!await guardAction(context, ref, Capability.favorite)) return;
  final failure = await ref
      .read(dishInteractionsProvider.notifier)
      .toggleFavorite(dish);
  if (failure != null && context.mounted) {
    await reportActionFailure(
      context,
      ref,
      failure,
      capability: Capability.favorite,
      fallback: '收藏失败，请重试',
    );
  }
}

/// 舞台：右边是封面盘子，点开看大图；左下是分类、菜名、价格。
class _StageContent extends StatelessWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final layout = EatLayout.of(context);
    final scale = layout.stageScale;
    final textScale = layout.stageTextScale;
    final lines = DishRules.stageLines(dish.name);
    final nameSize = (lines.length >= 3 ? 38.0 : 46.0) * textScale;
    final price = DishRules.priceText(dish.price);
    return LayoutBuilder(
      builder: (context, constraints) {
        final plate = layout.isWide
            ? (constraints.maxHeight * 440 / 800).clamp(260.0, 520.0)
            : 296 * scale;
        final center = layout.isWide
            ? Offset(
                constraints.maxWidth - plate * 0.3,
                constraints.maxHeight / 2,
              )
            : Offset(constraints.maxWidth - 72 * scale, 260 * scale);
        return Stack(
          children: [
            Positioned(
              left: center.dx - plate / 2,
              top: center.dy - plate / 2,
              child: EatTappable(
                onTap: dish.images.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                        PhotoViewer.route(
                          images: dish.images,
                          uploader: dish.uploaderName,
                        ),
                      ),
                label: '看大图',
                focusShape: const CircleBorder(),
                builder: (context, _) => DishPlate(
                  image: networkImage(dish.cover, width: plate),
                  size: plate,
                  centerX: dish.crop.centerX,
                  centerY: dish.crop.centerY,
                  diameter: dish.crop.diameter,
                ),
              ),
            ),
            Positioned(
              left: EatSpace.s20,
              bottom: EatSize.sheetOverlap + (layout.isWide ? 40 : 28),
              child: IgnorePointer(
                child: SizedBox(
                  width: layout.isWide ? 260 : 200 * textScale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dish.category case final category?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            category.label,
                            style: eat.text.meta.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.secondaryForeground,
                            ),
                          ),
                        ),
                      Semantics(
                        header: true,
                        child: Text(
                          lines.join('\n'),
                          semanticsLabel: dish.name,
                          textScaler: TextScaler.noScaling,
                          style: eat.text.stageDish.copyWith(
                            fontSize: nameSize,
                            height: (nameSize + 4) / nameSize,
                            color: palette.foreground,
                          ),
                        ),
                      ),
                      if (price != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            price,
                            textScaler: TextScaler.noScaling,
                            style: eat.text.priceHero.copyWith(
                              fontSize: 52 * textScale,
                              color: palette.foreground,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 店卡：店名、距离、商圈和地址，点了进餐厅详情。
class _ShopCard extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.eat.colors;
    final shop = ref.watch(shopProvider(dish.shopId)).value;
    final distance = ref.watch(
      distanceToProvider(shop?.point ?? dish.shopPoint),
    );
    final hub =
        ref.watch(hubNameProvider(shop?.hubId ?? dish.hubId)) ?? dish.hubName;
    final address = shop?.address ?? dish.shopAddress;
    final meta = [?distance, ?hub, ?address].join(' · ');
    return EatListRow(
      leading: Container(
        width: EatSize.thumb,
        height: EatSize.thumb,
        decoration: BoxDecoration(
          color: c.mist,
          borderRadius: const BorderRadius.all(EatRadius.thumb),
        ),
        child: Center(child: EatIcon(EatIcons.store, size: 24, color: c.ink)),
      ),
      title: Text(dish.shopName ?? '这家店'),
      lines: [if (meta.isNotEmpty) Text(meta)],
      trailing: EatIcon(EatIcons.chevronRight, size: 20, color: c.inkMuted),
      onTap: () => context.push(Paths.shop(dish.shopId)),
    );
  }
}

/// 赞（心形加赞数，赞过是按下的样子）和「导航去店里」。
class _Actions extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interaction =
        ref.watch(dishInteractionsProvider.select((m) => m[dish.id])) ??
        DishInteraction.of(dish);
    final shop = ref.watch(shopProvider(dish.shopId)).value;
    final point = shop?.point ?? dish.shopPoint;
    return Row(
      spacing: EatSpace.s10,
      children: [
        Expanded(
          child: Semantics(
            toggled: interaction.liked,
            child: (interaction.liked ? EatButton.mist : EatButton.outline)(
              '${interaction.likes}',
              icon: interaction.liked ? EatIcons.heartOn : EatIcons.heart,
              onPressed: () => _toggleLike(context, ref),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: EatButton.solid(
            '导航去店里',
            icon: EatIcons.navigate,
            onPressed: point == null
                ? null
                : () => navigateToShop(
                    context,
                    ref,
                    name: shop?.name ?? dish.shopName ?? dish.name,
                    point: point,
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    if (!await guardAction(context, ref, Capability.like)) return;
    final failure = await ref
        .read(dishInteractionsProvider.notifier)
        .toggleLike(dish);
    if (failure != null && context.mounted) {
      await reportActionFailure(
        context,
        ref,
        failure,
        capability: Capability.like,
        fallback: '点赞失败，请重试',
      );
    }
  }
}

/// 「大家怎么说」：按人数排的口味标签，点一个就是打上，打过的再点撤回；最后是「＋ 加标签」。
class _TasteSection extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final tags = ref.watch(dishTagsOfProvider(dish.id));
    final taste = (tags?.taste ?? dish.tasteTags)
        .where((t) => t.count > 0)
        .toList();
    final add = EatChip.add(
      '＋ 加标签',
      onTap: () async {
        if (!await guardAction(context, ref, Capability.tasteTag) ||
            !context.mounted) {
          return;
        }
        await showTagPanel(context, dishId: dish.id);
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EatSpace.s8,
      children: [
        Semantics(
          header: true,
          child: Text('大家怎么说', style: eat.text.sectionTitle),
        ),
        if (taste.isEmpty) ...[
          Text(
            '还没人说过，来第一个',
            style: eat.text.body.copyWith(color: eat.colors.inkMuted),
          ),
          add,
        ] else
          TasteCloud(
            words: [
              for (final t in taste)
                TasteWord(label: t.name, count: t.count, selected: t.mine),
            ],
            selectedLabel: '我打过',
            onTap: (i) async {
              if (!await guardAction(context, ref, Capability.tasteTag)) return;
              final failure = await ref
                  .read(dishTagsOfProvider(dish.id).notifier)
                  .toggleTaste(taste[i]);
              if (failure != null && context.mounted) {
                await reportActionFailure(
                  context,
                  ref,
                  failure,
                  capability: Capability.tasteTag,
                  fallback: '加标签失败，请重试',
                );
              }
            },
            trailing: add,
          ),
        if (tags?.mine case final mine? when mine.isNotEmpty)
          Text(
            '我的标签：${mine.map((t) => t.name).join('、')}',
            style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
          ),
      ],
    );
  }
}

/// 上传者：头像、昵称、「10 月 18 日上传」，下面是说明。他人主页在阶段六做。
class _Uploader extends StatelessWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final name = dish.uploaderName ?? '同学';
    final created = dish.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EatSpace.s10,
      children: [
        EatListRow(
          leading: EatAvatar(
            name: name,
            color: StageColor
                .values[(dish.uploaderId ?? 0) % StageColor.values.length],
          ),
          title: Text(name),
          lines: [
            if (created != null)
              Text('${TimeFormat.date(created, clock.now())}上传'),
          ],
        ),
        if (dish.description case final description?)
          Text(
            description,
            style: eat.text.body.copyWith(color: eat.colors.ink),
          ),
      ],
    );
  }
}

/// 「吃过的人说」：评论还没有接口（现状差距 2.1），标题和「写一条」照样画出来。
class _Comments extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EatSpace.s10,
      children: [
        Row(
          children: [
            Semantics(
              header: true,
              child: Text('吃过的人说', style: eat.text.sectionTitle),
            ),
            const SizedBox(width: EatSpace.s8),
            const PendingTag(),
            const Spacer(),
            EatButton.outline(
              '写一条',
              icon: EatIcons.edit,
              height: 36,
              onPressed: () => showPending(context, PendingFeature.comments),
            ),
          ],
        ),
        Text(
          '吃过的话，说两句',
          style: eat.text.body.copyWith(color: eat.colors.inkMuted),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
