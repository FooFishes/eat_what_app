import 'package:eat/core/failure/app_failure.dart';
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
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 头像的底色. 没有头像时按用户 id 确定舞台色, 同一用户在各处颜色一致.
StageColor avatarColorOf(int userId) =>
    StageColor.values[userId % StageColor.values.length];

/// "我的" 和他人主页的舞台内容.
///
/// - 右侧: 获赞最多的菜. 没有上传过菜时显示插画空盘, 上传列表加载中时留空.
/// - 左下: 头像, 昵称, 用户名, 签名和四项统计. 点击粉丝和关注进入对应列表.
class ProfileStage extends ConsumerWidget {
  const new({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.username,
    this.signature,
    required this.profile,
    required this.top,
    required this.loading,
  });

  final int userId;
  final String name;
  final String? avatarUrl;
  final String? username;
  final String? signature;

  /// 统计. 加载中为 null, 数字显示为 "–".
  final UserProfile? profile;
  final Dish? top;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final scale = EatLayout.of(context).stageScale;
    final plate = 220 * scale;
    final profile = this.profile;
    final top = this.top;
    Future<void> openList(FollowListKind kind) async {
      if (await guardAction(context, ref, Capability.viewFollows) &&
          context.mounted) {
        await context.push(
          Paths.follows(userId, fans: kind == FollowListKind.fans),
        );
      }
    }

    final stats = <(String, int?, VoidCallback?)>[
      ('获赞', profile?.earnedLikes, null),
      ('上传的菜', profile?.uploadedDishes, null),
      ('粉丝', profile?.fans, () => openList(FollowListKind.fans)),
      ('关注', profile?.followings, () => openList(FollowListKind.followings)),
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
                color: avatarColorOf(userId),
                image: networkImage(avatarUrl, width: 72),
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
                  style: eat.text.title.copyWith(color: palette.foreground),
                ),
              ),
              if (username case final username?)
                Text(
                  '@$username',
                  style: eat.text.meta.copyWith(
                    color: palette.secondaryForeground,
                  ),
                ),
              if (signature case final signature?)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    signature,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: eat.text.body.copyWith(
                      color: palette.secondaryForeground,
                    ),
                  ),
                ),
              const SizedBox(height: EatSpace.s10),
              Row(
                children: [
                  for (final (label, value, onTap) in stats)
                    Expanded(
                      child: _Stat(label: label, value: value, onTap: onTap),
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

/// 一项统计: 数字在上, 名称在下. 可点击的统计高度不小于 44px.
class _Stat extends StatelessWidget {
  const new({required this.label, required this.value, this.onTap});

  final String label;
  final int? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: EatSize.touch),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value == null ? '–' : '$value',
            textScaler: TextScaler.noScaling,
            style: eat.text.stat.copyWith(color: palette.foreground),
          ),
          Text(
            label,
            style: eat.text.caption.copyWith(
              color: palette.secondaryForeground,
            ),
          ),
        ],
      ),
    );
    final semantics = '$label ${value ?? '加载中'}';
    if (onTap == null) {
      return Semantics(
        label: semantics,
        child: ExcludeSemantics(child: content),
      );
    }
    return EatTappable(
      onTap: onTap,
      label: semantics,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => ExcludeSemantics(child: content),
    );
  }
}

/// 上传或收藏的菜. 两列方块, 滚动到底部时加载下一页.
///
/// - [showShop] 为 true 时菜名下显示店名 (收藏, 标签下的菜), 否则菜名右侧显示赞数 (上传).
/// - [empty] 是列表为空时显示的内容.
class DishGridSliver extends StatelessWidget {
  const new({
    super.key,
    required this.value,
    required this.onRetry,
    required this.onLoadMore,
    required this.empty,
    this.showShop = false,
  });

  final AsyncValue<DishPages> value;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final Widget empty;
  final bool showShop;

  @override
  Widget build(BuildContext context) {
    final data = value.value;
    if (data == null) {
      if (value.hasError && !value.isLoading) {
        return SliverToBoxAdapter(
          child: FailureState(
            message: (value.error as AppFailure?)?.message,
            onRetry: onRetry,
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
          child: empty,
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
            shop: showShop ? dishes[i].shopName : null,
            likes: showShop ? null : dishes[i].likes,
            onTap: () =>
                context.push(Paths.dish(dishes[i].id), extra: dishes[i]),
          ),
        ),
        if (data.pages.hasNext)
          SliverToBoxAdapter(
            child: LoadMoreTrigger(
              generation: dishes.length,
              failed: data.moreError != null,
              onVisible: onLoadMore,
            ),
          ),
      ],
    );
  }
}

/// 舞台下方的提示条: 图标, 一句说明, 可选的按钮.
class StageNotice extends StatelessWidget {
  const new({super.key, required this.icon, required this.text, this.action});

  final EatIcons icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
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
          EatIcon(icon, size: 20, color: eat.colors.ink),
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
