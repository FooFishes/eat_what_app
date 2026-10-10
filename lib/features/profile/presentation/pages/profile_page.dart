import 'package:eat_what_app/core/network/models/api_response.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/features/profile/data/models/user_info_response.dart';
import 'package:eat_what_app/features/profile/data/models/user_profile_stats_response.dart';
import 'package:eat_what_app/features/profile/presentation/view_models/profile_overview_view_model.dart';
import 'package:eat_what_app/shared/food/data/models/food_vo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmState = ref.watch(profileOverviewViewModelProvider);
    final userInfo = vmState.userInfo;
    final stats = vmState.stats;

    if (vmState.isLoading && userInfo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vmState.error != null && userInfo == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const .symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: .min,
                children: [
                  const Icon(
                    Icons.sentiment_dissatisfied_rounded,
                    size: 54,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '个人中心加载失败',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请检查网络后重试',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => ref
                        .read(profileOverviewViewModelProvider.notifier)
                        .reload(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryStrong,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Future<void> openProfileInfo() async {
      await context.push('/profile/info');
      if (!context.mounted) return;
      ref.read(profileOverviewViewModelProvider.notifier).reload();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Padding(
                          padding: const .fromLTRB(24, 8, 24, 0),
                          child: SizedBox(
                            width: double.infinity,
                            child: _ProfileHeaderSection(
                              userInfo: userInfo!,
                              stats: stats!,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 16,
                          child: IconButton(
                            onPressed: openProfileInfo,
                            tooltip: '编辑个人资料',
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const .fromLTRB(24, 18, 24, 0),
                      child: _ProfileQuickActions(
                        onTapTagLibrary: () => context.push('/profile/tags'),
                        onTapHistory: () => context.push('/profile/history'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const .symmetric(horizontal: 24),
                      child: Align(
                        alignment: .centerLeft,
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 2.5,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: const Color(0xFFFFD4BB),
                          labelStyle: const TextStyle(
                            fontWeight: .w700,
                            fontSize: 18,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: .w600,
                            fontSize: 18,
                          ),
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          splashBorderRadius: BorderRadius.circular(999),
                          tabs: const [
                            Tab(text: '上传'),
                            Tab(text: '收藏'),
                            Tab(text: '评论'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 1, color: Color(0xFFF4E8BF)),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _ProfileFoodDataTab(
                            fetchPage: (page, pageSize) => ref
                                .read(profileOverviewViewModelProvider.notifier)
                                .loadMyFoods(page, pageSize),
                            resolveNames: (ids) => ref
                                .read(profileOverviewViewModelProvider.notifier)
                                .resolveRestaurantNames(ids),
                            emptyTitle: '还没有上传菜品',
                            emptySubtitle: '去 Campus 上传页添加第一道菜吧',
                            thumbnailLabel: '上传',
                          ),
                          _ProfileFoodDataTab(
                            fetchPage: (page, pageSize) => ref
                                .read(profileOverviewViewModelProvider.notifier)
                                .loadMyFavorites(page, pageSize),
                            resolveNames: (ids) => ref
                                .read(profileOverviewViewModelProvider.notifier)
                                .resolveRestaurantNames(ids),
                            emptyTitle: '还没有收藏菜品',
                            emptySubtitle: '在餐厅详情页给喜欢的菜点个收藏吧',
                            thumbnailLabel: '收藏',
                          ),
                          _ProfileTabList(
                            onRefresh: () => ref
                                .read(profileOverviewViewModelProvider.notifier)
                                .reload(),
                            children: const [
                              _ProfileCommentCard(
                                author: '天凉被破王',
                                title: '袁记云饺',
                                content: '份量稳定，微辣就已经很够味，适合两个人一起拼菜。',
                                source: '来自店铺评价',
                                likeCount: '99',
                              ),
                              _ProfileCommentCard(
                                author: '天凉被破王',
                                title: '一点点',
                                content: '少糖更合适，椰果很多，适合做评论流样式占位。',
                                source: '来自店铺评价',
                                likeCount: '3',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderSection extends StatelessWidget {
  const new({required this.userInfo, required this.stats});

  final UserInfoResponse userInfo;
  final UserProfileStatsResponse stats;

  @override
  Widget build(BuildContext context) {
    final tags = _buildTags(userInfo);

    return Padding(
      padding: const .symmetric(vertical: 4),
      child: Column(
        children: [
          _ProfileAvatar(
            avatar: userInfo.avatar,
            name: userInfo.userName,
            size: 86,
          ),
          const SizedBox(height: 14),
          Text(
            userInfo.userName,
            textAlign: .center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.black, fontWeight: .w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => _TagChip(
                    label: tag.label,
                    backgroundColor: tag.backgroundColor,
                    textColor: tag.textColor,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InlineStat(value: '${stats.earnedLikes}', label: '获赞'),
              ),
              Expanded(
                child: _InlineStat(
                  value: '${stats.uploadedFoodsCount}',
                  label: '菜品',
                  helper: '上传',
                ),
              ),
              Expanded(
                child: _InlineStat(value: '${stats.fansCount}', label: '粉丝'),
              ),
              Expanded(
                child: _InlineStat(
                  value: '${stats.followingsCount}',
                  label: '关注',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_TagData> _buildTags(UserInfoResponse userInfo) {
    final tags = <_TagData>[
      _TagData(
        label: userInfo.verified ? '已认证' : '待认证',
        backgroundColor: const Color(0xFFFFE1D1),
        textColor: AppColors.primaryStrong,
      ),
    ];

    final gender = switch (userInfo.gender) {
      'male' => '男生',
      'female' => '女生',
      'other' => '其他',
      _ => null,
    };
    if (gender != null) {
      tags.add(
        _TagData(
          label: gender,
          backgroundColor: const Color(0xFFDDF1DA),
          textColor: AppColors.accentGreen,
        ),
      );
    }

    final hometown = [
      userInfo.hometownProvinceName,
      userInfo.hometownCityName,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join('');
    if (hometown.isNotEmpty) {
      tags.add(
        _TagData(
          label: hometown,
          backgroundColor: const Color(0xFFE8F1D4),
          textColor: const Color(0xFF758B22),
        ),
      );
    }

    // if (tags.length < 3) {
    //   tags.add(
    //     _TagData(
    //       label: '个人资料',
    //       backgroundColor: const Color(0xFFFDEEC7),
    //       textColor: AppColors.accentBrown,
    //     ),
    //   );
    // }

    return tags.take(3).toList(growable: false);
  }
}

class _ProfileQuickActions extends StatelessWidget {
  const new({required this.onTapTagLibrary, required this.onTapHistory});

  final VoidCallback onTapTagLibrary;
  final VoidCallback onTapHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickEntryCard(
            title: '自定义标签库',
            subtitle: '方便查找分类',
            icon: Icons.bookmarks_outlined,
            onTap: onTapTagLibrary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickEntryCard(
            title: '足迹',
            subtitle: '看过的店铺',
            icon: Icons.watch_later_outlined,
            onTap: onTapHistory,
          ),
        ),
      ],
    );
  }
}

class _ProfileTabList extends StatelessWidget {
  const new({required this.onRefresh, required this.children});

  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryStrong,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const .fromLTRB(18, 16, 18, 128),
        children: children,
      ),
    );
  }
}

class _ProfileFoodDataTab extends StatefulWidget {
  const new({
    required this.fetchPage,
    required this.resolveNames,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.thumbnailLabel,
  });

  final Future<PaginatedData<FoodVO>> Function(int page, int pageSize)
  fetchPage;
  final Future<Map<int, String>> Function(List<int> ids) resolveNames;
  final String emptyTitle;
  final String emptySubtitle;
  final String thumbnailLabel;

  @override
  State<_ProfileFoodDataTab> createState() => _ProfileFoodDataTabState();
}

class _ProfileFoodDataTabState extends State<_ProfileFoodDataTab> {
  final Map<int, String> _restaurantNames = <int, String>{};
  List<FoodVO> _items = const [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNext = false;
  int _currentPage = 1;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitial);
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await widget.fetchPage(1, 20);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _currentPage = 1;
        _hasNext = page.hasNext;
        _isLoading = false;
      });
      await _ensureRestaurantNames(page.items);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNext) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final page = await widget.fetchPage(nextPage, 20);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _currentPage = nextPage;
        _hasNext = page.hasNext;
        _isLoadingMore = false;
      });
      await _ensureRestaurantNames(page.items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      AppErrorPresenter.showErrorToast(context, error);
    }
  }

  Future<void> _ensureRestaurantNames(List<FoodVO> foods) async {
    final missingIds = foods
        .map((food) => food.restaurantId)
        .where((id) => !_restaurantNames.containsKey(id))
        .toSet()
        .toList(growable: false);
    if (missingIds.isEmpty) return;

    final entries = await widget.resolveNames(missingIds);
    if (!mounted) return;
    setState(() => _restaurantNames.addAll(entries));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: _ProfileEmptyStateCard(title: '列表加载失败', subtitle: '下拉或点击重试'),
      );
    }

    final restaurantCount = _items
        .map((item) => item.restaurantId)
        .toSet()
        .length;

    return RefreshIndicator(
      onRefresh: _loadInitial,
      color: AppColors.primaryStrong,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const .fromLTRB(18, 16, 18, 128),
        children: [
          if (_items.isNotEmpty)
            _ProfileCountCaption(
              leading: '店铺 $restaurantCount',
              trailing: '菜品 ${_items.length}',
            ),
          if (_items.isEmpty)
            _ProfileEmptyStateCard(
              title: widget.emptyTitle,
              subtitle: widget.emptySubtitle,
            ),
          for (final item in _items)
            _ProfileFoodCard(
              title: item.name,
              subtitle: _buildSubtitle(item),
              thumbnailLabel: widget.thumbnailLabel,
              imageUrl: item.pictureUrl.isEmpty
                  ? null
                  : Urls.resolvePublicAssetUrl(item.pictureUrl.first),
            ),
          if (_hasNext)
            Padding(
              padding: const .only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: _isLoadingMore ? null : _loadMore,
                  child: _isLoadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('加载更多'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildSubtitle(FoodVO item) {
    final restaurantName =
        _restaurantNames[item.restaurantId] ?? '餐厅 #${item.restaurantId}';
    final description = item.description.trim();
    final priceText = item.price == null ? '' : ' · ¥${item.price}';
    if (description.isNotEmpty) {
      return '$restaurantName$priceText\n$description';
    }
    return '$restaurantName$priceText';
  }
}

class _ProfileFoodCard extends StatelessWidget {
  const new({
    required this.title,
    required this.subtitle,
    required this.thumbnailLabel,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String thumbnailLabel;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const .only(bottom: 14),
      padding: const .all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(18),
        border: Border.all(color: const Color(0xFFAEB0B6)),
      ),
      child: Row(
        children: [
          _buildThumbnail(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: .w700),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: .circular(12),
        child: Image.network(
          imageUrl!,
          width: 62,
          height: 62,
          fit: .cover,
          errorBuilder: (_, _, _) => _buildFallbackThumbnail(context),
        ),
      );
    }
    return _buildFallbackThumbnail(context);
  }

  Widget _buildFallbackThumbnail(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFCB73), Color(0xFFFF8F45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: .circular(12),
      ),
      child: Column(
        mainAxisAlignment: .center,
        children: [
          const Icon(
            Icons.restaurant_menu_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            thumbnailLabel,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.white, fontWeight: .w700),
          ),
        ],
      ),
    );
  }
}

class _ProfileEmptyStateCard extends StatelessWidget {
  const new({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const .only(bottom: 14),
      padding: const .symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(18),
        border: Border.all(color: const Color(0xFFE6D9AF)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 30,
            color: AppColors.primaryStrong,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: .center,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: .w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: .center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProfileCountCaption extends StatelessWidget {
  const new({required this.leading, required this.trailing});

  final String leading;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(bottom: 12),
      child: Row(
        children: [
          Text(
            leading,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: .w700),
          ),
          const SizedBox(width: 18),
          Text(
            trailing,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProfileCommentCard extends StatelessWidget {
  const new({
    required this.author,
    required this.title,
    required this.content,
    required this.source,
    required this.likeCount,
  });

  final String author;
  final String title;
  final String content;
  final String source;
  final String likeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const .only(bottom: 14),
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(18),
        border: Border.all(color: const Color(0xFFE6D9AF)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: .center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE9BC),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  author.characters.first,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: .w800,
                    color: AppColors.accentBrown,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      author,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: .w700),
                    ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                source,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textHint),
              ),
              const Spacer(),
              const Icon(
                Icons.thumb_up_alt_outlined,
                size: 15,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                likeCount,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickEntryCard extends StatelessWidget {
  const new({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(16),
      onTap: onTap,
      child: Ink(
        padding: const .symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D8),
          borderRadius: .circular(16),
          border: Border.all(color: const Color(0xFFF7E7B3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: .w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const new({required this.value, required this.label, this.helper});

  final String value;
  final String label;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final actualLabel = helper == null ? label : '$helper$label';

    return RichText(
      textAlign: .center,
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.textPrimary, fontWeight: .w800),
          ),
          TextSpan(
            text: ' $actualLabel',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary, fontWeight: .w600),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const new({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: .circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: textColor, fontWeight: .w700),
      ),
    );
  }
}

class const _TagData({
  required final String label,
  required final Color backgroundColor,
  required final Color textColor,
});

class _ProfileAvatar extends StatelessWidget {
  const new({required this.avatar, required this.name, required this.size});

  final String? avatar;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = Urls.resolvePublicAssetUrl(avatar);

    if (avatarUrl == null) {
      return _AvatarPlaceholder(name: name, size: size);
    }

    return ClipRRect(
      borderRadius: .circular(size / 2),
      child: Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: .cover,
        errorBuilder: (_, _, _) => _AvatarPlaceholder(name: name, size: size),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const new({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '我' : name.trim().characters.first;

    return Container(
      width: size,
      height: size,
      alignment: .center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE9BC), Color(0xFFFFC56F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: .circular(size / 2),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: .w800, color: AppColors.accentBrown),
      ),
    );
  }
}
