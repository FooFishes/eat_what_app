import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/foot_links.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/like_heart.dart';
import 'package:eat/design/widgets/joined_group.dart';
import 'package:eat/design/widgets/keyboard_inset.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/photo_viewer.dart';
import 'package:eat/design/widgets/stage_bar_action.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/design/widgets/star_rating.dart';
import 'package:eat/design/widgets/stat_strip.dart';
import 'package:eat/data/comment/comment_repository.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/dish/dish_providers.dart';
import 'package:eat/features/dish/rating_card.dart';
import 'package:eat/features/system/comment_card.dart';
import 'package:eat/features/system/comment_composer.dart';
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
/// - 舞台: 封面, 招牌和分类的小胶囊, 菜名, 价格.
/// - 顶栏右边: 编辑, 收藏, 分享.
/// - 抽屉: 数字条 (评分, 赞, 口味), 上传者卡片, 店三张卡片连成一组 ([JoinedGroup]), 然后 "吃过的人说", 页底的 "修改记录".
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
        stageHeight: _stageHeightOf(context),
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
    // 抽屉里有写评论的输入框. 页面自己不避让键盘, 滚动区域会伸到键盘下面, 输入框被盖住时不会自动滚上来;
    // 这里按键盘高度收短页面, 键盘后面铺白底 (iOS 26 半透明的圆角键盘后面会透出黑色).
    return KeyboardInset(
      color: context.eat.colors.paper,
      child: StageScaffold(
        stage: dish.stage,
        stageHeight: _stageHeightOf(context),
        topBar: _TopBar(dish: dish),
        onRefresh: () => _refresh(context, ref, dish),
        stageContent: _StageContent(dish: dish),
        sheetSlivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              EatSpace.s20,
              EatSpace.s8,
              EatSpace.s20,
              0,
            ),
            sliver: SliverList.list(
              children: [
                JoinedGroup([
                  _Stats(dish: dish, loaded: loaded),
                  _Uploader(dish: dish),
                  _ShopRow(dish: dish),
                ]),
                if (!loaded && detail.hasError) ...[
                  const SizedBox(height: EatSpace.s16),
                  FailureState(
                    error: detail.error,
                    onRetry: () => ref.invalidate(dishDetailProvider(dishId)),
                  ),
                ],
                const SizedBox(height: _groupGap),
                _Comments(dishId: dishId, focus: focusComment),
                const SizedBox(height: EatSpace.s16),
                FootLinks([
                  (
                    label: '修改记录',
                    onTap: () => context.push(Paths.dishHistory(dish.id)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 抽屉里卡片组和评论之间的留白.
const _groupGap = 32.0;

/// 舞台只占半屏, 抽屉一打开就看得到数字条和店, 评论也露出开头.
double _stageHeightOf(BuildContext context) =>
    (MediaQuery.sizeOf(context).height * 0.5).clamp(360.0, 460.0);

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
        if (dish != null && interaction != null)
          StageBarActions(
            children: [
              StageBarAction(
                icon: EatIcons.edit,
                text: '编辑',
                onTap: () async {
                  if (await guardAction(context, ref, Capability.editDish) &&
                      context.mounted) {
                    await context.push(Paths.dishEdit(dish.id), extra: dish);
                  }
                },
              ),
              StageBarAction(
                icon: interaction.favorite
                    ? EatIcons.bookmarkOn
                    : EatIcons.bookmark,
                text: interaction.favorite ? '已收藏' : '收藏',
                label: interaction.favorite ? '取消收藏' : '收藏',
                onTap: () => _toggleFavorite(context, ref, dish),
              ),
              StageBarAction(
                icon: EatIcons.share,
                text: '分享',
                onTap: () => showSharePanel(
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
          ),
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
/// - 左下: 招牌和分类的小胶囊, 菜名, 价格.
class _StageContent extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final layout = EatLayout.of(context);
    final textScale = layout.stageTextScale;
    final barBottom = StageScaffold.barBottomOf(context);
    final lines = DishRules.stageLines(dish.name);
    final nameSize = layout.stageNameSize(lines);
    final price = DishRules.priceText(dish.price);
    final kicker = [if (dish.signature) '招牌', ?dish.category?.label];
    return LayoutBuilder(
      builder: (context, constraints) {
        // 手机上舞台只有半屏: 盘子按舞台高度定大小, 圆心在顶栏和抽屉之间, 右边探出屏幕一点.
        final height = constraints.maxHeight;
        final plate = layout.isWide
            ? (height * 440 / 800).clamp(260.0, 520.0)
            : (height * 0.56).clamp(200.0, 280.0);
        final center = layout.isWide
            ? Offset(constraints.maxWidth - plate * 0.3, height / 2)
            : Offset(
                constraints.maxWidth - plate * 0.26,
                barBottom + (height - EatSize.sheetOverlap - barBottom) / 2 + 6,
              );
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
              bottom: EatSize.sheetOverlap + (layout.isWide ? 40 : 20),
              child: IgnorePointer(
                child: SizedBox(
                  width: layout.isWide ? 260 : 200 * textScale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kicker.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: EatSpace.s8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final label in kicker)
                                DecoratedBox(
                                  decoration: ShapeDecoration(
                                    color: palette.ghost,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      label,
                                      style: eat.text.meta.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: palette.foreground,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
                              fontSize: (layout.isWide ? 56 : 48) * textScale,
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

/// 抽屉顶部的数字条: 评分, 赞, 口味.
///
/// - 评分: 有人评过就写平均分, 没人评过写 "—"; 上面写人数, 下面一排小星是自己打的分, 没打过是空星.
///   点了从这一格展开评分卡.
/// - 赞: 心形加赞数, 点了赞或取消, 赞上时心形弹一下, 数字往上翻一格.
/// - 口味: 这道菜的口味, 最多 3 个, 只读. 口味投票没有接口, 不放入口.
class _Stats extends ConsumerStatefulWidget {
  const new({required this.dish, required this.loaded});

  final Dish dish;

  /// 详情是否已加载. 列表带来的菜没有口味, 加载完之前口味先空着.
  final bool loaded;

  @override
  ConsumerState<_Stats> createState() => _StatsState();
}

class _StatsState extends ConsumerState<_Stats> {
  /// 评分格, 评分卡从这里展开.
  final _ratingCell = GlobalKey();

  Dish get dish => widget.dish;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final interaction =
        ref.watch(dishInteractionsProvider.select((m) => m[dish.id])) ??
        DishInteraction.of(dish);
    final rating = interaction.rating;
    final mine = interaction.myRating;
    final tastes = dish.tags.take(3).map((t) => t.label).toList();
    late final StatCell ratingCell;
    ratingCell = StatCell(
      key: _ratingCell,
      label: rating.count == 0 ? '评分' : '${rating.count} 人评分',
      value: DishRules.scoreText(rating) == null
          ? '—'
          : rating.score!.toStringAsFixed(1),
      footer: Align(
        alignment: Alignment.centerLeft,
        child: StarRating(value: mine, size: 15),
      ),
      semanticsLabel: [
        '评分',
        DishRules.ratingSummary(rating),
        if (mine != null) '你打了 $mine 分' else '点了打分',
      ].join('，'),
      onTap: () => showDishRatingCard(
        context,
        ref,
        dish,
        origin: _ratingCell,
        face: (_) => StatStrip.face(ratingCell),
      ),
    );
    return StatStrip([
      ratingCell,
      StatCell(
        label: '赞',
        value: '${interaction.likes}',
        valueWidget: Row(
          spacing: EatSpace.s8,
          children: [
            LikeHeart(liked: interaction.liked, size: 22, color: c.ink),
            _RollingCount(interaction.likes),
          ],
        ),
        note: interaction.liked ? '你赞过' : '点一下赞',
        semanticsLabel: '赞，${interaction.likes}',
        toggled: interaction.liked,
        onTap: _toggleLike,
      ),
      StatCell(
        label: '口味',
        value: !widget.loaded || tastes.isEmpty ? '—' : tastes.join('、'),
        note: widget.loaded && tastes.isEmpty ? '还没标口味' : null,
      ),
    ]);
  }

  Future<void> _toggleLike() async {
    if (!await guardAction(context, ref, Capability.like)) return;
    EatHaptics.light();
    final failure = await ref
        .read(dishInteractionsProvider.notifier)
        .toggleLike(dish);
    if (failure != null && mounted) {
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

/// 赞数: 变多时新数字从下面翻上来, 变少时从上面翻下来.
class _RollingCount extends StatefulWidget {
  const new(this.count);

  final int count;

  @override
  State<_RollingCount> createState() => _RollingCountState();
}

class _RollingCountState extends State<_RollingCount> {
  var _up = true;

  @override
  void didUpdateWidget(_RollingCount old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) _up = widget.count > old.count;
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final style = eat.text.stat.copyWith(
      fontSize: 24,
      height: 30 / 24,
      color: eat.colors.ink,
    );
    return ClipRect(
      child: AnimatedSwitcher(
        duration: context.motion(EatMotion.select),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(widget.count);
          final from = Offset(0, (_up == incoming) ? 0.6 : -0.6);
          return SlideTransition(
            position: Tween(begin: from, end: Offset.zero).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(
          '${widget.count}',
          key: ValueKey(widget.count),
          style: style,
        ),
      ),
    );
  }
}

/// 这道菜在哪家店, 放在上传者卡片下面, 和上传者卡片一样带 `mist` 底: 小圆角的门头照, 店名, 距离, 商圈和地址, 点了进餐厅详情. 导航只放在餐厅详情里.
class _ShopRow extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.eat.colors;
    final shop = ref.watch(shopProvider(dish.shopId)).value;
    final distance = ref.watch(distanceToProvider(shop?.point));
    final hub = ref.watch(hubNameProvider(shop?.hubId));
    final meta = [?distance, ?hub, ?shop?.address].join('  ');
    final photo = shop?.photo;
    final row = EatListRow(
      leading: photo == null
          ? Container(
              width: EatSize.thumb,
              height: EatSize.thumb,
              decoration: BoxDecoration(
                color: c.mist,
                borderRadius: const BorderRadius.all(EatRadius.photo),
              ),
              child: Center(
                child: EatIcon(EatIcons.store, size: 24, color: c.ink),
              ),
            )
          : ListThumb(
              image: networkImage(photo, width: EatSize.thumb),
              radius: EatRadius.photo,
            ),
      title: Text(dish.shopName ?? '这家店'),
      lines: [if (meta.isNotEmpty) Text(meta)],
      trailing: EatIcon(EatIcons.chevronRight, size: 20, color: c.inkMuted),
    );
    return EatTappable(
      onTap: () => context.push(Paths.shop(dish.shopId)),
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.tile),
      ),
      builder: (context, pressed) => JoinedSurface(
        pressed: pressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            EatSpace.s10,
            EatSpace.s10,
            EatSpace.s14,
            EatSpace.s10,
          ),
          child: row,
        ),
      ),
    );
  }
}

// TODO: 菜品响应没有上传者昵称, `/user/userInfo` 需要登录, 游客看到的上传者是 "同学". 后端在菜品响应中提供上传者摘要后改为读取接口字段.
/// 上传者卡片: 上面是这道菜的说明, 下面一行头像, 昵称和上传日期, 点击进上传者主页.
///
/// 登录用户按 [Dish.uploaderId] 请求上传者资料, 游客不发起请求; 资料未就绪时显示 "同学", 若账号已注销则显示 "已注销用户" 且不可点击.
class _Uploader extends ConsumerWidget {
  const new({required this.dish});

  final Dish dish;

  /// 卡片里头像的直径.
  static const _avatar = 28.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final id = dish.uploaderId;
    final signedIn = ref.watch(sessionProvider.select((s) => s is SignedIn));
    final profile = id != null && signedIn
        ? ref.watch(userProfileProvider(id)).value
        : null;
    final name = id == null ? '已注销用户' : profile?.nickname ?? '同学';
    final created = dish.createdAt;
    Widget card(bool pressed) => JoinedSurface(
      pressed: pressed,
      child: Padding(
        padding: const EdgeInsets.all(EatSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: EatSpace.s14,
          children: [
            if (dish.description case final description?)
              Text(description, style: eat.text.body.copyWith(color: c.ink)),
            Row(
              spacing: EatSpace.s8,
              children: [
                EatAvatar(
                  name: name,
                  color:
                      StageColor.values[(id ?? 0) % StageColor.values.length],
                  image: networkImage(profile?.avatarUrl, width: _avatar),
                  size: _avatar,
                ),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: eat.text.meta.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
                if (created != null)
                  Text(
                    '${TimeFormat.date(created, clock.now())}上传',
                    style: eat.text.meta.copyWith(color: c.inkMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return switch (id) {
      final id? => EatTappable(
        onTap: () async {
          if (await guardAction(context, ref, Capability.viewProfile) &&
              context.mounted) {
            await context.push(Paths.user(id));
          }
        },
        focusShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(EatRadius.tile),
        ),
        builder: (context, pressed) => card(pressed),
      ),
      null => card(false),
    };
  }
}

/// "吃过的人说" 评论区: 标题后跟评论条数, 下面就是写评论的输入框 ([CommentComposer]), 再下面是最有用的 3 条, 最后 "看全部 N 条".
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
      children: [
        Row(
          key: _header,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: EatSpace.s8,
          children: [
            Semantics(
              header: true,
              child: Text('吃过的人说', style: eat.text.heading),
            ),
            if (total > 0)
              Text(
                '$total',
                style: eat.text.count.copyWith(color: eat.colors.inkMuted),
              ),
          ],
        ),
        const SizedBox(height: EatSpace.s14),
        CommentComposer(dishId: widget.dishId),
        const SizedBox(height: EatSpace.s20),
        if (list == null)
          comments.hasError && !comments.isLoading
              ? FailureState(
                  error: comments.error,
                  onRetry: () => ref.invalidate(provider),
                )
              : const RowListPlaceholder(count: 2, thumbSize: 36)
        else if (shown.isEmpty)
          Text(
            '还没有人说过，来写第一条',
            style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
          )
        else ...[
          for (final (i, comment) in shown.indexed) ...[
            if (i > 0) const CommentGap(),
            CommentCard(
              key: comment.id == focus ? _focused : null,
              comment: comment,
              highlighted: comment.id == focus,
            ),
          ],
          const SizedBox(height: EatSpace.s8),
          EatButton.mist(
            '看全部 $total 条',
            height: 48,
            onPressed: () => context.push(Paths.comments(widget.dishId)),
          ),
        ],
      ],
    );
  }
}
