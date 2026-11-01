import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/dish_tile.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 「我的」（`G-Me`）：舞台上是我获赞最多的那道菜，头像、昵称、签名和四个统计；
/// 抽屉里是上传、收藏、评论三栏。右上角是设置。
///
/// 评论、收藏的店还没有接口，带「待接入」；编辑资料、我的标签、足迹、粉丝和关注列表在阶段六做。
class MePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  int _tab = 0;

  /// 收藏栏顶部的「菜」「店」。
  bool _favoriteShops = false;

  @override
  Widget build(BuildContext context) {
    final user = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user,
      SignedOut() => null,
    };
    final uploads = ref.watch(myUploadsProvider);
    final top = DishRules.signatures(
      uploads.value?.pages.items ?? const <Dish>[],
      count: 1,
    ).firstOrNull;
    return StageScaffold(
      stage: top?.stage ?? StageColor.mango,
      topBar: Align(
        alignment: Alignment.centerRight,
        child: EatIconButton(
          EatIcons.settings,
          label: '设置',
          onPressed: () => context.push(Paths.settings),
        ),
      ),
      stageContent: _StageContent(
        user: user,
        top: top,
        loading: uploads.isLoading,
      ),
      sheetSlivers: [
        const SliverToBoxAdapter(child: _StatusNotice()),
        SliverToBoxAdapter(
          child: EatTabs(
            tabs: [
              EatTabItem(
                '上传',
                count: ref.watch(myProfileProvider).value?.uploadedDishes,
              ),
              const EatTabItem('收藏'),
              const EatTabItem('评论', pending: true),
            ],
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: switch (_tab) {
            0 => const _DishGrid(favorites: false),
            1 => SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Wrap(
                    spacing: EatSpace.s8,
                    children: [
                      EatChip.choice(
                        '菜',
                        selected: !_favoriteShops,
                        onTap: () => setState(() => _favoriteShops = false),
                      ),
                      EatChip.choice(
                        '店',
                        selected: _favoriteShops,
                        onTap: () => setState(() => _favoriteShops = true),
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s10)),
                if (_favoriteShops)
                  const SliverToBoxAdapter(
                    child: _Pending(
                      title: '收藏的店',
                      feature: PendingFeature.shopFavorite,
                    ),
                  )
                else
                  const _DishGrid(favorites: true),
              ],
            ),
            _ => const SliverToBoxAdapter(
              child: _Pending(
                title: '我写过的评论',
                feature: PendingFeature.comments,
              ),
            ),
          },
        ),
      ],
    );
  }
}

/// 舞台：右边获赞最多的那道菜（还没发过菜时是插画空盘），左下头像、昵称、用户名、签名和统计。
class _StageContent extends ConsumerWidget {
  const new({required this.user, required this.top, required this.loading});

  final CurrentUser? user;
  final Dish? top;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final layout = EatLayout.of(context);
    final scale = layout.stageScale;
    final profile = ref.watch(myProfileProvider).value;
    final user = this.user;
    final top = this.top;
    final plate = 220 * scale;
    final name = user?.nickname ?? '同学';
    final stats = [
      ('获赞', profile?.earnedLikes),
      ('上传的菜', profile?.uploadedDishes),
      ('粉丝', profile?.fans),
      ('关注', profile?.followings),
    ];
    return Stack(
      children: [
        Positioned(
          right: -plate * 0.22,
          top: 112 * scale,
          child: top != null
              ? DishPlate(
                  image: networkImage(top.cover, width: plate),
                  size: plate,
                  centerX: top.crop.centerX,
                  centerY: top.crop.centerY,
                  diameter: top.crop.diameter,
                )
              : loading
              ? const SizedBox()
              : DishPlate.illustration(
                  IllustrationImage(Illustration.niunan, size: plate),
                  size: plate,
                ),
        ),
        Positioned(
          left: EatSpace.s20,
          right: EatSpace.s20,
          bottom: EatSize.sheetOverlap + 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EatAvatar(
                name: name,
                color: StageColor
                    .values[(user?.id ?? 0) % StageColor.values.length],
                image: networkImage(user?.avatarUrl, width: 72),
                size: 72,
              ),
              const SizedBox(height: EatSpace.s14),
              Semantics(
                header: true,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling,
                  style: eat.text.profileName.copyWith(
                    color: palette.foreground,
                  ),
                ),
              ),
              if (user?.username case final username?)
                Text(
                  '@$username',
                  style: eat.text.meta.copyWith(
                    color: palette.secondaryForeground,
                  ),
                ),
              if (user?.signature case final signature?)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    signature,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: eat.text.body.copyWith(
                      fontSize: 14,
                      color: palette.secondaryForeground,
                    ),
                  ),
                ),
              const SizedBox(height: EatSpace.s16),
              Row(
                children: [
                  for (final (label, value) in stats)
                    Expanded(
                      child: Semantics(
                        label: '$label ${value ?? '加载中'}',
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                value == null ? '–' : '$value',
                                textScaler: TextScaler.noScaling,
                                style: eat.text.stat.copyWith(
                                  fontSize: 26,
                                  color: palette.foreground,
                                ),
                              ),
                              Text(
                                label,
                                style: eat.text.caption.copyWith(
                                  color: palette.secondaryForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 未认证时「认证后可以发布和互动」和「去认证」；封禁中写封禁的原因（产品 6.10）。
class _StatusNotice extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final status = ref.watch(accountStatusProvider);
    final (String text, Widget? action) = switch (status) {
      UnverifiedStatus() => (
        '认证后可以发布和互动',
        EatButton.solid(
          '去认证',
          height: 36,
          onPressed: () => context.push(Paths.verify),
        ),
      ),
      BannedStatus(:final reason, :final since) => (
        [
          '账号封禁中',
          if (since != null) '${TimeFormat.date(since, DateTime.now())}起',
          ?reason,
        ].join('，'),
        null,
      ),
      _ => ('', null),
    };
    if (text.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s20,
        0,
        EatSpace.s20,
        EatSpace.s14,
      ),
      child: Row(
        spacing: EatSpace.s10,
        children: [
          EatIcon(EatIcons.verify, size: 20, color: eat.colors.ink),
          Expanded(
            child: Text(
              text,
              style: eat.text.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// 上传、收藏的菜：两列方块，菜名右边是赞数，滑到底接着加载。
class _DishGrid extends ConsumerWidget {
  const new({required this.favorites});

  final bool favorites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = favorites
        ? ref.watch(myFavoritesProvider)
        : ref.watch(myUploadsProvider);
    final data = value.value;
    if (data == null) {
      if (value.hasError && !value.isLoading) {
        return SliverToBoxAdapter(
          child: FailureState(
            message: (value.error as AppFailure?)?.message,
            onRetry: () => favorites
                ? ref.invalidate(myFavoritesProvider)
                : ref.invalidate(myUploadsProvider),
          ),
        );
      }
      return const SliverToBoxAdapter(child: TileGridPlaceholder(count: 4));
    }
    final dishes = data.pages.items;
    if (dishes.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
          child: favorites
              ? const EmptyState(
                  icon: EatIcons.bookmark,
                  title: '还没收藏过菜',
                  message: '在菜品详情右上角点收藏，想吃的菜都在这里。',
                )
              : EmptyState(
                  icon: EatIcons.bowl,
                  title: '还没发布过菜',
                  message: '吃到好吃的，发一道让同学们知道。',
                  action: EatButton.outline(
                    '发布一道菜',
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
      );
    }
    final width = (MediaQuery.sizeOf(context).width - 54) / 2;
    return SliverMainAxisGroup(
      slivers: [
        SliverTileGrid(
          count: dishes.length,
          builder: (context, i) => DishTile(
            image: networkImage(dishes[i].cover, width: width),
            name: dishes[i].name,
            shop: favorites ? dishes[i].shopName : null,
            likes: favorites ? null : dishes[i].likes,
            onTap: () =>
                context.push(Paths.dish(dishes[i].id), extra: dishes[i]),
          ),
        ),
        if (data.pages.hasNext)
          SliverToBoxAdapter(
            child: LoadMoreTrigger(
              generation: dishes.length,
              failed: data.moreError != null,
              onVisible: () => favorites
                  ? ref.read(myFavoritesProvider.notifier).loadMore()
                  : ref.read(myUploadsProvider.notifier).loadMore(),
            ),
          ),
      ],
    );
  }
}

/// 还没有接口的分栏：照样画出来，标题旁边放「待接入」。
class _Pending extends StatelessWidget {
  const new({required this.title, required this.feature});

  final String title;
  final PendingFeature feature;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
      child: Column(
        spacing: EatSpace.s10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: EatSpace.s8,
            children: [
              Text(title, style: eat.text.sectionTitle),
              const PendingTag(),
            ],
          ),
          Text(
            '接口上线后显示在这里',
            style: eat.text.body.copyWith(color: eat.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
