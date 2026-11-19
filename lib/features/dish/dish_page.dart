import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/eat_button.dart';
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
import 'package:eat/data/comment/comment_repository.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/dish/dish_providers.dart';
import 'package:eat/features/dish/rating_panel.dart';
import 'package:eat/features/system/comment_card.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_actions.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/comments.dart';
import 'package:eat/state/dish_interactions.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/shops.dart';
import 'package:eat/state/social.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 菜品详情页.
///
/// - 舞台: 封面, 招牌标记和分类, 菜名, 价格.
/// - 抽屉: 依次为店卡, 赞和导航, 评分, "大家怎么说", 上传者, 编辑和修改记录, "吃过的人说".
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
                        error: detail.error,
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
              const SizedBox(height: EatSpace.s16),
              _Actions(dish: dish),
              const SizedBox(height: 28),
              _Rating(dish: dish),
              const SizedBox(height: 28),
              if (loaded)
                _TasteSection(dish: dish)
              else if (detail.hasError)
                FailureState(
                  error: detail.error,
                  onRetry: () => ref.invalidate(dishDetailProvider(dishId)),
                )
              else
                const RowListPlaceholder(count: 2),
              const SizedBox(height: 28),
              _Uploader(dish: dish),
              const SizedBox(height: EatSpace.s16),
              _EditActions(dish: dish),
              const SizedBox(height: 28),
              _Comments(dishId: dishId, focus: focusComment),
            ],
          ),
        ),
      ],
    );
  }
}

/// 下拉刷新菜品详情, 评论与所属店铺信息; 若详情请求失败则保留现有内容并提示原因.
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

/// 判断菜品是否已不存在. 若服务端确认不存在, 则说明列表传入的 [DishPage.initial] 已过期, 不再展示.
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
              target: (type: AnalyticsTarget.food, id: dish.id),
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
/// - 左下: 招牌标记和分类, 菜名, 价格.
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
    final kicker = [
      if (dish.signature) '招牌',
      ?dish.category?.label,
    ].join(' · ');
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
                      if (kicker.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            kicker,
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

/// 打开大图浏览: 上传者的照片在前, 评论中的照片在后, 每张标注拍摄者.
///
/// 每次打开时请求图库, 以包含打开详情之后新发表的评论照片.
/// 图库请求失败时只显示上传者的照片.
Future<void> _openPhotos(BuildContext context, WidgetRef ref, Dish dish) async {
  var gallery = const <GalleryPhoto>[];
  try {
    gallery = await ref.read(commentRepositoryProvider).gallery(dish.id);
  } on AppFailure {
    gallery = const [];
  }
  if (!context.mounted) return;
  final uploaderId = dish.uploaderId;
  final uploader = uploaderId != null && ref.read(sessionProvider) is SignedIn
      ? ref.read(userProfileProvider(uploaderId)).value?.nickname
      : null;
  final photos = [
    for (final url in dish.images) ViewerPhoto(url: url, credit: uploader),
    for (final photo in gallery)
      ViewerPhoto(url: photo.url, credit: photo.authorName),
  ];
  if (photos.isEmpty) return;
  await Navigator.of(context).push(PhotoViewer.route(photos: photos));
}

/// 所属店铺卡片, 展示店名, 距离, 商圈和地址, 点击进入餐厅详情.
class _ShopCard extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.eat.colors;
    final shop = ref.watch(shopProvider(dish.shopId)).value;
    final distance = ref.watch(distanceToProvider(shop?.point));
    final hub = ref.watch(hubNameProvider(shop?.hubId));
    final meta = [?distance, ?hub, ?shop?.address].join('  ');
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
    final point = shop?.point;
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
                    shopId: dish.shopId,
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

/// 评分区: 平均分和评分人数, 当前用户打的分, 以及打开评分面板的按钮.
///
/// 平均分满 [DishRules.ratingMinCount] 人才显示, 不足时只写人数. 打分后的结果来自 [dishInteractionsProvider].
class _Rating extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final interaction =
        ref.watch(dishInteractionsProvider.select((m) => m[dish.id])) ??
        DishInteraction.of(dish);
    final mine = interaction.myRating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EatSpace.s8,
      children: [
        Semantics(
          header: true,
          child: Text('吃过觉得怎么样', style: eat.text.heading),
        ),
        Row(
          spacing: EatSpace.s14,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DishRules.ratingSummary(interaction.rating),
                    style: eat.text.body.copyWith(color: eat.colors.ink),
                  ),
                  Text(
                    mine == null ? '吃过的话，打个分' : '你打了 $mine 分',
                    style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
                  ),
                ],
              ),
            ),
            EatButton.outline(
              mine == null ? '评分' : '改评分',
              icon: EatIcons.edit,
              height: 36,
              onPressed: () => showDishRatingPanel(context, ref, dish),
            ),
          ],
        ),
      ],
    );
  }
}

// TODO: 后端 v2 的口味是菜品自身的属性, 没有投票接口. 投票接口上线后恢复点词投票和加标签面板.
/// "大家怎么说": 菜品自身的口味, 由编辑者设置, 只读.
///
/// 口味投票和 "加标签" 没有接口, 不放入口.
class _TasteSection extends StatelessWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EatSpace.s8,
      children: [
        Semantics(header: true, child: Text('大家怎么说', style: eat.text.heading)),
        if (dish.tags.isEmpty)
          Text(
            '还没有标注口味，编辑菜品时可以添加',
            style: eat.text.body.copyWith(color: eat.colors.inkMuted),
          )
        else
          Wrap(
            spacing: EatSpace.s8,
            children: [
              for (final (i, taste) in dish.tags.indexed) ...[
                if (i > 0)
                  ExcludeSemantics(
                    child: Text(
                      '·',
                      style: eat.text.subhead.copyWith(
                        color: eat.colors.inkMuted,
                      ),
                    ),
                  ),
                Text(
                  taste.label,
                  style: eat.text.subhead.copyWith(color: eat.colors.ink),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

// TODO: 菜品响应没有上传者昵称, `/user/userInfo` 需要登录, 游客看到的上传者是 "同学". 后端在菜品响应中提供上传者摘要后改为读取接口字段.
/// 上传者信息区, 展示头像, 昵称, 上传日期及上传者说明, 点击可进入上传者主页.
///
/// 登录用户按 [Dish.uploaderId] 请求上传者资料, 游客不发起请求; 资料未就绪时显示 "同学", 若账号已注销则显示 "已注销用户" 且不可点击.
class _Uploader extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final id = dish.uploaderId;
    final signedIn = ref.watch(sessionProvider.select((s) => s is SignedIn));
    final profile = id != null && signedIn
        ? ref.watch(userProfileProvider(id)).value
        : null;
    final name = id == null ? '已注销用户' : profile?.nickname ?? '同学';
    final created = dish.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EatSpace.s10,
      children: [
        EatListRow(
          leading: EatAvatar(
            name: name,
            color: StageColor.values[(id ?? 0) % StageColor.values.length],
            image: networkImage(profile?.avatarUrl, width: EatSize.avatar),
          ),
          title: Text(name),
          lines: [
            if (created != null)
              Text('${TimeFormat.date(created, clock.now())}上传'),
          ],
          onTap: switch (id) {
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

/// "编辑" 和 "修改记录" 两个入口.
///
/// - 认证用户都能编辑任何一道菜, 未认证时点 "编辑" 弹拦截.
/// - 修改记录公开, 游客也能看.
class _EditActions extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    spacing: EatSpace.s10,
    children: [
      Expanded(
        child: EatButton.outline(
          '编辑',
          icon: EatIcons.edit,
          onPressed: () async {
            if (await guardAction(context, ref, Capability.editDish) &&
                context.mounted) {
              await context.push(Paths.dishEdit(dish.id), extra: dish);
            }
          },
        ),
      ),
      Expanded(
        child: EatButton.outline(
          '修改记录',
          icon: EatIcons.history,
          onPressed: () => context.push(Paths.dishHistory(dish.id)),
        ),
      ),
    ],
  );
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
                  error: comments.error,
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
