import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
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
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/photo_viewer.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/design/widgets/taste_cloud.dart';
import 'package:eat/data/comment/comment_repository.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/dish/dish_providers.dart';
import 'package:eat/features/dish/dish_topic.dart';
import 'package:eat/features/dish/tag_panel.dart';
import 'package:eat/features/system/comment_card.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_actions.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/comments.dart';
import 'package:eat/state/dish_interactions.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// TODO: 编辑自己的菜品未实现, 页面缺少编辑入口. 实现编辑流程后为上传者本人显示编辑入口.
/// 菜品详情页.
///
/// - 舞台: 封面, 分类, 菜名, 价格.
/// - 抽屉: 依次为店卡, 专题提示, 赞和导航, "大家怎么说", 上传者, "吃过的人说".
///
/// 从列表进入时先用 [initial] 绘制舞台, 抽屉内容等待接口返回.
class DishPage extends ConsumerWidget {
  const new({super.key, required this.dishId, this.initial, this.focusComment});

  final int dishId;
  final Dish? initial;

  /// 打开后滚动到的评论 id, 来自消息和 "我的评论".
  final int? focusComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(dishDetailProvider(dishId));
    if (_isNotFound(detail)) return const _NotFound();
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
      onRefresh: () => _refresh(context, ref, dish),
      stageContent: _StageContent(dish: dish),
      sheetSlivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: SliverList.list(
            children: [
              _ShopCard(dish: dish),
              DishTopicHint(dishId: dishId),
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
              _Comments(dishId: dishId, focus: focusComment),
            ],
          ),
        ),
      ],
    );
  }
}

/// 下拉刷新: 重新请求详情, 评论和店铺. 详情失败时保留页面上的旧内容并提示原因.
Future<void> _refresh(BuildContext context, WidgetRef ref, Dish dish) async {
  ref.invalidate(dishCommentsProvider(dish.id, CommentSort.mostUseful));
  ref.invalidate(shopProvider(dish.shopId));
  ref.invalidate(dishDetailProvider(dish.id));
  try {
    await ref.read(dishDetailProvider(dish.id).future);
  } on AppFailure catch (e) {
    if (context.mounted) showToast(context, e.message);
  }
}

/// 详情请求返回菜品不存在. 此时从列表传入的 [DishPage.initial] 已过时, 不再显示.
bool _isNotFound(AsyncValue<Dish> detail) =>
    !detail.isLoading &&
    detail.error is AppFailure &&
    (detail.error! as AppFailure).code == BizCodes.foodNotFound;

/// 菜品不存在时的页面. 重试不会改变结果, 因此只提供返回.
class _NotFound extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => StageScaffold(
    stage: StageColor.broth,
    topBar: const _TopBar(dish: null),
    stageContent: const SizedBox(),
    sheetSlivers: const [
      SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: EatSpace.s20,
          vertical: EatSpace.s24,
        ),
        sliver: SliverToBoxAdapter(
          child: EmptyState(
            icon: EatIcons.bowl,
            title: '这道菜已删除',
            message: '去看看店里的其他菜。',
          ),
        ),
      ),
    ],
  );
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
      SignedOut() || Guest() => null,
    };
    return Row(
      children: [
        const EatBackButton(),
        Expanded(
          child: dish == null ? const SizedBox() : StageBarTitle(dish.name),
        ),
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
              reportTarget: dish.uploaderId == me
                  ? null
                  : ReportTarget.dish(dish.id),
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
  final notifier = ref.read(dishInteractionsProvider.notifier);
  final was =
      (ref.read(dishInteractionsProvider)[dish.id] ?? DishInteraction.of(dish))
          .favorite;
  EatHaptics.light();
  final failure = await notifier.toggleFavorite(dish);
  if (!context.mounted) return;
  if (failure == null) {
    // 收藏成功后页面上只有右上角的图标变化, 因此用轻提示说明收藏的菜在哪里查看.
    showToast(context, was ? '已取消收藏' : '已收藏，可在「我的」查看');
  }
  if (failure != null) {
    await reportActionFailure(
      context,
      ref,
      failure,
      capability: Capability.favorite,
      fallback: '收藏失败，请重试',
    );
  }
}

/// 菜品详情的舞台内容.
///
/// - 右侧: 封面盘子, 点击查看大图.
/// - 左下: 分类, 菜名, 价格.
class _StageContent extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final layout = EatLayout.of(context);
    final scale = layout.stageScale;
    final textScale = layout.stageTextScale;
    final lines = DishRules.stageLines(dish.name);
    final nameSize = layout.stageNameSize(lines);
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
                onTap: () => _openPhotos(context, ref, dish),
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
                          style: eat.text.stage.copyWith(
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
                              fontSize: 56 * textScale,
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

// TODO: 图库接口不返回拍摄者, 评论照片的作者昵称只能从已加载的评论中查找, 查找不到时不标注. 接口返回作者昵称后改为读取接口字段.
/// 打开大图浏览: 上传者的照片在前, 评论中的照片在后.
///
/// 评论照片的地址 30 秒后失效, 因此每次打开时重新请求图库, 不复用打开详情时的结果.
/// 图库请求失败时只显示上传者的照片.
Future<void> _openPhotos(BuildContext context, WidgetRef ref, Dish dish) async {
  var gallery = const <GalleryPhoto>[];
  try {
    gallery = await ref.read(commentRepositoryProvider).gallery(dish.id);
  } on AppFailure {
    gallery = const [];
  }
  if (!context.mounted) return;
  final known = {
    for (final c
        in ref
                .read(dishCommentsProvider(dish.id, CommentSort.mostUseful))
                .value
                ?.items ??
            const <Comment>[])
      c.id: c.authorName,
  };
  final photos = [
    for (final url in dish.images)
      ViewerPhoto(url: url, credit: dish.uploaderName),
    for (final photo in gallery)
      ViewerPhoto(url: photo.url, credit: known[photo.commentId]),
  ];
  if (photos.isEmpty) return;
  await Navigator.of(context).push(PhotoViewer.route(photos: photos));
}

/// 店卡: 店名, 距离, 商圈和地址. 点击进入餐厅详情.
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
    final meta = [?distance, ?hub, ?address].join('  ');
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

/// 赞按钮和 "导航去店里" 按钮. 赞按钮显示心形和赞数, 已赞时显示为按下状态.
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
    EatHaptics.light();
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

/// "大家怎么说": 按人数排序的口味标签, 末尾是 "+ 加标签".
///
/// 点击未打过的标签即打上, 点击已打过的标签则撤回.
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
      '加标签',
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
        Semantics(header: true, child: Text('大家怎么说', style: eat.text.heading)),
        // 口味词的外观是文字, 没有可点击的提示. 这行说明点击的结果.
        if (taste.isNotEmpty)
          Text(
            '有同感就点选，再点一次取消',
            style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
          ),
        if (taste.isEmpty) ...[
          Text(
            '还没有口味词，来加第一个',
            style: eat.text.body.copyWith(color: eat.colors.inkMuted),
          ),
          add,
        ] else
          TasteCloud(
            words: [
              for (final t in taste)
                TasteWord(label: t.name, count: t.count, selected: t.mine),
            ],
            selectedLabel: '已选',
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

/// 上传者信息: 头像, 昵称, 上传日期, 以及上传者写的说明. 点击进入上传者主页.
class _Uploader extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onTap: switch (dish.authorId) {
            final id? => () async {
              if (await guardAction(context, ref, Capability.viewProfile) &&
                  context.mounted) {
                await context.push(Paths.user(id));
              }
            },
            null => null,
          },
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

/// "吃过的人说" 评论区: 标题后跟评论条数, 右侧 "写一条". 显示最有用的 3 条, 其下为 "看全部 N 条".
///
/// [focus] 是要滚动到的评论. 该评论在前 3 条中时滚动到该条并以底色标出, 否则滚动到评论区标题.
class _Comments extends ConsumerStatefulWidget {
  const new({required this.dishId, this.focus});

  final int dishId;
  final int? focus;

  @override
  ConsumerState<_Comments> createState() => _CommentsState();
}

class _CommentsState extends ConsumerState<_Comments> {
  final _header = GlobalKey();
  final _focused = GlobalKey();

  /// 是否已经滚动过. 只在首次获得评论时滚动, 之后列表刷新不改变滚动位置.
  var _scrolled = false;

  void _scrollToFocus(bool found) {
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = (found ? _focused : _header).currentContext;
      if (target == null || !target.mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          target,
          alignment: 0.2,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
        ),
      );
    });
  }

  Future<void> _write() async {
    if (!await guardAction(context, ref, Capability.comment) || !mounted) {
      return;
    }
    await context.push(Paths.writeComment(widget.dishId));
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final provider = dishCommentsProvider(
      widget.dishId,
      CommentSort.mostUseful,
    );
    final comments = ref.watch(provider);
    final list = comments.value;
    final total = list?.data.total ?? 0;
    final shown =
        list?.items.take(CommentRules.dishPreview).toList() ??
        const <Comment>[];
    final focus = widget.focus;
    if (focus != null && list != null && !_scrolled) {
      _scrollToFocus(shown.any((c) => c.id == focus));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EatSpace.s10,
      children: [
        Row(
          key: _header,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text('吃过的人说', style: eat.text.heading),
            ),
            if (total > 0) ...[
              const SizedBox(width: EatSpace.s8),
              Text(
                '$total',
                style: eat.text.count.copyWith(color: eat.colors.ink),
              ),
            ],
            const Spacer(),
            EatButton.outline(
              '写一条',
              icon: EatIcons.edit,
              height: 36,
              onPressed: _write,
            ),
          ],
        ),
        if (list == null)
          comments.hasError && !comments.isLoading
              ? FailureState(
                  message: (comments.error as AppFailure?)?.message,
                  onRetry: () => ref.invalidate(provider),
                )
              : const RowListPlaceholder(count: 2, thumbSize: 36)
        else if (shown.isEmpty)
          Text(
            '吃过的话，说两句',
            style: eat.text.body.copyWith(color: eat.colors.inkMuted),
          )
        else ...[
          for (final comment in shown)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CommentCard(
                key: comment.id == focus ? _focused : null,
                comment: comment,
                highlighted: comment.id == focus,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: EatButton.mist(
              '看全部 $total 条',
              height: 48,
              onPressed: () => context.push(Paths.comments(widget.dishId)),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
