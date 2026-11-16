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
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 计算默认头像的舞台底色, 当用户无头像时依据用户 id 确定, 以保证同一用户在各处颜色一致.
StageColor avatarColorOf(int userId) =>
    StageColor.values[userId % StageColor.values.length];

/// 渲染 "我的" 页面与他人主页共用的顶部舞台内容.
///
/// - 右侧展示获赞最多的菜品; 若尚未上传过菜品则显示插画空盘, 上传列表加载中则留空.
/// - 左下展示头像, 昵称与等级, 用户名, 签名及四项统计, 点击粉丝和关注可进入对应列表.
/// - 等级取自 [profile], 在加载中或接口未返回时不显示; 当 [onLevelTap] 为 null 时等级不可点击.
class ProfileStage extends ConsumerWidget {
  const new({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.username,
    this.signature,
    required this.profile,
    this.uploads,
    required this.top,
    required this.loading,
    this.onLevelTap,
  });

  final int userId;
  final String name;
  final String? avatarUrl;
  final String? username;
  final String? signature;

  /// 包含等级, 获赞, 粉丝与关注数的用户资料; 加载中时为 null, 对应数字显示为 "–".
  final UserProfile? profile;

  /// 上传菜品的总数, 取自上传列表, 加载中时为 null.
  final int? uploads;
  final Dish? top;
  final bool loading;
  final VoidCallback? onLevelTap;

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

    // 资料已加载完毕而数值仍为 null, 说明对方未公开该项.
    final missing = profile == null ? '加载中' : '未公开';
    final stats = <(String, int?, String, VoidCallback?)>[
      ('获赞', profile?.earnedLikes, '加载中', null),
      ('上传的菜', uploads, '加载中', null),
      ('粉丝', profile?.fans, missing, () => openList(FollowListKind.fans)),
      (
        '关注',
        profile?.followings,
        missing,
        () => openList(FollowListKind.followings),
      ),
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
              Row(
                spacing: EatSpace.s8,
                children: [
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.noScaling,
                        style: eat.text.title.copyWith(
                          color: palette.foreground,
                        ),
                      ),
                    ),
                  ),
                  if (profile?.level case final level?)
                    LevelBadge(
                      level: level,
                      title: profile?.title,
                      onTap: onLevelTap,
                    ),
                ],
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
                  for (final (label, value, missing, onTap) in stats)
                    Expanded(
                      child: _Stat(
                        label: label,
                        value: value,
                        missing: missing,
                        onTap: onTap,
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

/// 展示在舞台昵称旁的等级胶囊 (如 "Lv.3", 有称号时为 "Lv.10 老吃家"); 可点击时确保触控区域不小于 44px, 而胶囊视觉尺寸保持小号.
class LevelBadge extends StatelessWidget {
  const new({super.key, required this.level, this.title, this.onTap});

  final int level;
  final String? title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final pill = DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.ghost,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text.rich(
          TextSpan(
            text: 'Lv.$level',
            style: eat.text.count,
            children: [
              if (title case final title?)
                TextSpan(
                  text: ' $title',
                  style: eat.text.meta.copyWith(fontWeight: FontWeight.w600),
                ),
            ],
          ),
          textScaler: TextScaler.noScaling,
          style: TextStyle(color: palette.foreground),
        ),
      ),
    );
    final label = switch (title) {
      final title? => '等级 $level，$title',
      null => '等级 $level',
    };
    if (onTap == null) {
      return Semantics(
        label: label,
        child: ExcludeSemantics(child: pill),
      );
    }
    return EatTappable(
      onTap: onTap,
      label: label,
      focusShape: const StadiumBorder(),
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: EatSize.touch,
          minHeight: EatSize.touch,
        ),
        child: Center(widthFactor: 1, child: ExcludeSemantics(child: pill)),
      ),
    );
  }
}

/// 舞台上的单项统计展示组件, 采用数字在上, 名称在下的布局; 可点击时高度不小于 44px.
class _Stat extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.missing,
    this.onTap,
  });

  final String label;
  final int? value;

  /// 当 [value] 为 null 时供读屏播报的状态文案, 如 "加载中" 或 "未公开".
  final String missing;
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
    final semantics = '$label ${value ?? missing}';
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

/// 以两列方块展示上传或收藏菜品的列表组件, 滚动到底部时自动加载下一页.
///
/// - 当 [showShop] 为 true 时在菜名下方显示店名 (用于收藏和标签下的菜), 否则在菜名右侧显示获赞数 (用于上传列表).
/// - [empty] 指定列表为空时展示的占位内容.
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
            price: DishRules.priceText(dishes[i].price),
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

/// 舞台下方的提示条组件, 包含图标, 一句说明文本及可选的操作按钮.
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
