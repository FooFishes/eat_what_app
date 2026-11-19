import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/eat_segment_slider.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/stage_bar_action.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/profile/my_comments.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/profile/widgets/profile_stage.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/features/system/shop_entry.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/comments.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/social.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "我的" 页面.
///
/// - 舞台: 我获赞最多的菜, 头像, 昵称和等级, 签名和四项统计.
/// - 抽屉: 上传, 收藏, 赞过, 评论四个分栏.
/// - 右上角: 历史 (浏览历史), 编辑资料和设置.
///
/// 后端 v2 不提供我的标签接口, 不放 "我的标签" 入口.
///
/// 游客看到的是 [_GuestMe].
class MePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

/// 吸顶后顶栏里头像的边长.
const _barAvatar = 28.0;

class _MePageState extends ConsumerState<MePage> {
  int _tab = 0;

  /// 抽屉里的分栏, 滚到顶栏下方时吸顶.
  final _tabsKey = GlobalKey();

  /// 收藏分栏当前展示店铺还是菜品, 默认为 false (展示菜品), 由顶部 "菜" 和 "店" 标签切换.
  bool _favoriteShops = false;

  /// 下拉刷新: 重新请求资料, 统计和三个分栏. 失败时保留页面上的旧内容并提示原因.
  ///
  /// 未显示的分栏只标记为过期, 切换到该分栏时才重新请求.
  Future<void> _refresh(int? userId) async {
    ref.invalidate(myFavoritesProvider);
    ref.invalidate(myLikesProvider);
    ref.invalidate(myFavoriteShopsProvider);
    ref.invalidate(myCommentsProvider);
    ref.invalidate(myUploadsProvider);
    if (userId != null) ref.invalidate(userProfileProvider(userId));
    try {
      await Future.wait([
        ref.read(sessionProvider.notifier).refreshUser(),
        ref.read(myUploadsProvider.future),
      ]);
    } on AppFailure catch (e) {
      // 资料和上传失败时 toastStaleFailure 已经提示过, 不再重复播报.
      if (mounted && !isToastShowing(e.message)) showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    // 游客不请求上传和收藏等要求登录的接口, 因此在读取这些 Provider 之前返回.
    if (session is! SignedIn) return const _GuestMe();
    final user = session.user;
    if (user != null) {
      toastStaleFailure(context, ref, userProfileProvider(user.id));
    }
    toastStaleFailure(context, ref, myUploadsProvider);
    final profile = user == null
        ? null
        : ref.watch(userProfileProvider(user.id)).value;
    final uploads = ref.watch(myUploadsProvider);
    final banned = ref.watch(accountStatusProvider) is BannedStatus;
    final top = DishRules.mostLiked(
      uploads.value?.pages.items ?? const <Dish>[],
      count: 1,
    ).firstOrNull;
    final tabs = EatTabs(
      tabs: [
        EatTabItem(
          '上传',
          icon: EatIcons.upload,
          count: uploads.value?.pages.total,
        ),
        const EatTabItem('收藏', icon: EatIcons.bookmark),
        const EatTabItem('赞过', icon: EatIcons.heart),
        const EatTabItem('评论', icon: EatIcons.comment),
      ],
      selected: _tab,
      onSelected: (tab) => setState(() => _tab = tab),
      padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
    );
    return StageScaffold(
      stage: top?.stage ?? StageColor.mango,
      onRefresh: () => _refresh(user?.id),
      // 和首页一样: 舞台固定在底层, 上滑时抽屉盖上来; 分栏滚到顶栏下方后吸顶.
      fixedStage: true,
      pinnedBottom: tabs,
      pinnedAnchor: _tabsKey,
      topBar: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: StageBarTitle(
              user?.nickname ?? '我的',
              leading: user == null
                  ? null
                  : EatAvatar(
                      name: user.nickname,
                      color: avatarColorOf(user.id),
                      image: networkImage(user.avatarUrl, width: _barAvatar),
                      size: _barAvatar,
                    ),
            ),
          ),
          StageBarActions(
            children: [
              StageBarAction(
                icon: EatIcons.history,
                text: '历史',
                label: '浏览历史',
                onTap: () async {
                  if (await guardAction(context, ref, Capability.viewHistory) &&
                      context.mounted) {
                    await context.push(Paths.history);
                  }
                },
              ),
              StageBarAction(
                icon: EatIcons.edit,
                text: '编辑',
                label: '编辑资料',
                onTap: () async {
                  if (await guardAction(context, ref, Capability.editProfile) &&
                      context.mounted) {
                    await context.push(Paths.meEdit);
                  }
                },
              ),
              StageBarAction(
                icon: EatIcons.settings,
                text: '设置',
                onTap: () => context.push(Paths.settings),
              ),
            ],
          ),
        ],
      ),
      stageHeight: ProfileStage.heightOf(
        context,
        known: true,
        username: user?.username,
        signature: user?.signature,
      ),
      stageContent: ProfileStage(
        userId: user?.id ?? 0,
        name: user?.nickname ?? '同学',
        avatarUrl: user?.avatarUrl,
        username: user?.username,
        signature: user?.signature,
        profile: profile,
        uploads: uploads.value?.pages.total,
        top: top,
        loading: uploads.isLoading,
        onLevelTap: () async {
          if (await guardAction(context, ref, Capability.viewGrowth) &&
              context.mounted) {
            await context.push(Paths.growth);
          }
        },
      ),
      sheetSlivers: [
        const SliverToBoxAdapter(child: _StatusNotice()),
        SliverToBoxAdapter(
          child: KeyedSubtree(key: _tabsKey, child: tabs),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: switch (_tab) {
            0 => DishGridSliver(
              value: uploads,
              onRetry: () => ref.invalidate(myUploadsProvider),
              onLoadMore: () => ref.read(myUploadsProvider.notifier).loadMore(),
              empty: EmptyState(
                icon: EatIcons.bowl,
                title: '还没发布过菜',
                message: '吃到好吃的，发一道让同学们知道。',
                action: EatButton.outline(
                  '加一道菜',
                  icon: EatIcons.add,
                  height: 48,
                  onPressed: () async {
                    if (await guardAction(
                          context,
                          ref,
                          Capability.publishDish,
                        ) &&
                        context.mounted) {
                      await context.push(Paths.publish);
                    }
                  },
                ),
              ),
            ),
            1 => SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: EatSegmentSlider(
                    semanticsLabel: '收藏的类型',
                    labels: const ['菜', '店'],
                    selected: _favoriteShops ? 1 : 0,
                    compact: true,
                    onChanged: (i) => setState(() => _favoriteShops = i == 1),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s10)),
                // 换类型时新列表淡入, 不是一下子跳过去.
                _FadeIn(
                  key: ValueKey(_favoriteShops),
                  sliver: _favoriteShops
                      ? const _FavoriteShops()
                      // 受限会话不能调用 `/foods/favorites`, 封禁中不请求.
                      : banned
                      ? const SliverToBoxAdapter(
                          child: EmptyState(
                            icon: EatIcons.block,
                            title: '账号封禁中',
                            message: '封禁期间暂时不能查看收藏的菜。',
                          ),
                        )
                      : DishGridSliver(
                          value: ref.watch(myFavoritesProvider),
                          showShop: true,
                          onRetry: () => ref.invalidate(myFavoritesProvider),
                          onLoadMore: () =>
                              ref.read(myFavoritesProvider.notifier).loadMore(),
                          empty: const EmptyState(
                            icon: EatIcons.bookmark,
                            title: '还没收藏过菜',
                            message: '在菜品右上角点收藏，想吃的菜都在这里。',
                          ),
                        ),
                ),
              ],
            ),
            // 受限会话不能调用 `/foods/likes`, 封禁中不请求.
            2 when banned => const SliverToBoxAdapter(
              child: EmptyState(
                icon: EatIcons.block,
                title: '账号封禁中',
                message: '封禁期间暂时不能查看赞过的菜。',
              ),
            ),
            2 => DishGridSliver(
              value: ref.watch(myLikesProvider),
              showShop: true,
              onRetry: () => ref.invalidate(myLikesProvider),
              onLoadMore: () => ref.read(myLikesProvider.notifier).loadMore(),
              empty: const EmptyState(
                icon: EatIcons.heart,
                title: '还没赞过菜',
                message: '在菜品详情点心形，赞过的菜都在这里。',
              ),
            ),
            _ => const MyCommentsSliver(),
          },
        ),
      ],
    );
  }
}

/// 游客的 "我的": 芒果黄舞台加插画空盘, 下面一句说明和 "登录".
///
/// 不显示统计, 分栏和快捷入口, 右上角只留设置. 登录后回到 "我的".
class _GuestMe extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return StageScaffold(
      stage: StageColor.mango,
      topBar: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          StageBarActions(
            children: [
              StageBarAction(
                icon: EatIcons.settings,
                text: '设置',
                onTap: () => context.push(Paths.settings),
              ),
            ],
          ),
        ],
      ),
      stageHeight: ProfileStage.heightOf(context),
      stageContent: const _GuestPlate(),
      sheetSlivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: EatSpace.s16,
              children: [
                Text(
                  '登录后看你的收藏、评论和发布',
                  style: eat.text.subhead.copyWith(color: eat.colors.ink),
                ),
                EatButton.solid(
                  '登录',
                  onPressed: () => context.go(Paths.loginFrom(Paths.me)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 游客舞台右侧的插画空盘, 位置和 [ProfileStage] 没有上传过菜时一致.
class _GuestPlate extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    const plate = ProfileStage.plateSize;
    return Stack(
      children: [
        Positioned(
          right: -plate * ProfileStage.plateBleed,
          top: ProfileStage.plateTop(context),
          child: DishPlate.illustration(
            IllustrationImage(Illustration.niunan, size: plate),
            size: plate,
          ),
        ),
      ],
    );
  }
}

/// 收藏分栏的 "店": 和附近页一样的榜单条目, 店名一栏加门头小图. 收藏接口不带招牌菜, 所以不排菜. 点击进入餐厅详情.
///
/// 封禁中仍然请求, 因为受限会话可以调用 `/restaurant/favorites`.
class _FavoriteShops extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(myFavoriteShopsProvider);
    final data = value.value;
    if (data == null) {
      if (value.hasError && !value.isLoading) {
        return SliverToBoxAdapter(
          child: FailureState(
            error: value.error,
            onRetry: () => ref.invalidate(myFavoriteShopsProvider),
          ),
        );
      }
      return const SliverToBoxAdapter(
        child: ShopEntryPlaceholder(dishes: false),
      );
    }
    final shops = data.pages.items;
    if (shops.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: EatSpace.s24),
          child: EmptyState(
            icon: EatIcons.bookmark,
            title: '还没收藏过店',
            message: '在店铺右上角点收藏，常去的店都在这里。',
          ),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverList.separated(
          itemCount: shops.length,
          separatorBuilder: (_, _) => const ShopEntryDivider(),
          itemBuilder: (context, i) => ShopEntry(
            shop: shops[i],
            index: i,
            dishes: false,
            onTap: () => context.push(Paths.shop(shops[i].id)),
          ),
        ),
        if (data.pages.hasNext)
          SliverToBoxAdapter(
            child: LoadMoreTrigger(
              generation: shops.length,
              failed: data.moreError != null,
              onVisible: () =>
                  ref.read(myFavoriteShopsProvider.notifier).loadMore(),
            ),
          ),
      ],
    );
  }
}

/// 第一次出现时淡入的 sliver. 换 [key] 就重新淡入一次; 系统开启减少动态效果时直接显示.
class _FadeIn extends StatelessWidget {
  const new({super.key, required this.sliver});

  final Widget sliver;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: context.motion(EatMotion.select),
    curve: EatMotion.select.curve,
    builder: (context, value, child) =>
        SliverOpacity(opacity: value, sliver: child),
    child: sliver,
  );
}

/// 账号状态提示. 未认证时提示认证并提供 "去认证", 封禁中时显示封禁原因.
class _StatusNotice extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(accountStatusProvider);
    return switch (status) {
      UnverifiedStatus() => StageNotice(
        icon: EatIcons.verify,
        text: '认证后可以发布和互动',
        action: EatButton.solid(
          '去认证',
          height: 36,
          onPressed: () => context.push(Paths.verify),
        ),
      ),
      final BannedStatus banned => StageNotice(
        icon: EatIcons.block,
        text: [
          '账号封禁中',
          banTerm(banned.until, DateTime.now()),
          if (banned.reason case final reason?) '原因：$reason',
        ].join('，'),
      ),
      _ => const SizedBox(),
    };
  }
}
