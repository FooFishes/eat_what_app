import 'package:eat_what_app/core/api/model/api_response.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/model/history/browse_history_item_response.dart';
import 'package:eat_what_app/provider/repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileHistoryPage extends StatelessWidget {
  const ProfileHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('足迹'),
          bottom: TabBar(
            indicatorColor: AppColors.primaryStrong,
            labelColor: AppColors.primaryStrong,
            unselectedLabelColor: AppColors.textHint,
            tabs: const [
              Tab(text: '店铺'),
              Tab(text: '菜品'),
            ],
          ),
        ),
        body: const SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _BrowseHistoryTab(
                targetType: 'restaurant',
                emptyTitle: '还没有店铺足迹',
                emptySubtitle: '浏览过的店铺会出现在这里',
              ),
              _BrowseHistoryTab(
                targetType: 'food',
                emptyTitle: '还没有菜品足迹',
                emptySubtitle: '浏览过的菜品会出现在这里',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseHistoryTab extends ConsumerStatefulWidget {
  const _BrowseHistoryTab({
    required this.targetType,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String targetType;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  ConsumerState<_BrowseHistoryTab> createState() => _BrowseHistoryTabState();
}

class _BrowseHistoryTabState extends ConsumerState<_BrowseHistoryTab> {
  static const int _pageSize = 20;

  final List<BrowseHistoryItemResponse> _items = <BrowseHistoryItemResponse>[];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNext = false;
  Object? _error;
  int _currentPage = 0;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
      _hasNext = false;
      _totalItems = 0;
      _items.clear();
    });

    try {
      final result = await _fetchPage(1);
      if (!mounted) {
        return;
      }

      setState(() {
        _items.addAll(result.items);
        _currentPage = result.currentPage;
        _hasNext = result.hasNext;
        _totalItems = result.totalItems;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasNext) {
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      final result = await _fetchPage(_currentPage + 1);
      if (!mounted) {
        return;
      }

      setState(() {
        _items.addAll(result.items);
        _currentPage = result.currentPage;
        _hasNext = result.hasNext;
        _totalItems = result.totalItems;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMore = false);
      AppErrorPresenter.showErrorToast(context, error);
    }
  }

  Future<PaginatedData<BrowseHistoryItemResponse>> _fetchPage(int page) {
    return ref
        .read(userRepositoryProvider)
        .getBrowseHistory(
          targetType: widget.targetType,
          page: page,
          pageSize: _pageSize,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return _HistoryErrorState(onRetry: _loadInitial);
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      color: AppColors.primaryStrong,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _HistoryOverviewCard(totalItems: _totalItems),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            _HistoryEmptyState(
              title: widget.emptyTitle,
              subtitle: widget.emptySubtitle,
            )
          else ...[
            for (final item in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: widget.targetType == 'restaurant'
                    ? _RestaurantHistoryCard(item: item)
                    : _FoodHistoryCard(item: item),
              ),
            if (_hasNext)
              OutlinedButton(
                onPressed: _isLoadingMore ? null : _loadMore,
                child: _isLoadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('加载更多'),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryOverviewCard extends StatelessWidget {
  const _HistoryOverviewCard({required this.totalItems});

  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E2B6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最近浏览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '记录你看过的店铺和菜品',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$totalItems',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' 条',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantHistoryCard extends StatelessWidget {
  const _RestaurantHistoryCard({required this.item});

  final BrowseHistoryItemResponse item;

  @override
  Widget build(BuildContext context) {
    final restaurant = item.restaurant;
    if (restaurant == null) {
      return const SizedBox.shrink();
    }

    return _HistoryCardFrame(
      imageUrl: restaurant.pictureUrl.isNotEmpty
          ? restaurant.pictureUrl.first
          : null,
      title: restaurant.name,
      subtitle: restaurant.address.isEmpty ? '暂无地址信息' : restaurant.address,
      footer: '浏览于 ${_formatTimestamp(item.viewedAt)}',
      icon: Icons.storefront_outlined,
    );
  }
}

class _FoodHistoryCard extends StatelessWidget {
  const _FoodHistoryCard({required this.item});

  final BrowseHistoryItemResponse item;

  @override
  Widget build(BuildContext context) {
    final food = item.food;
    if (food == null) {
      return const SizedBox.shrink();
    }

    final customTags = food.myCustomTags.take(3).map((tag) => tag.name);
    final systemTags = food.systemTags.take(2).map((tag) => tag.name);
    final allTags = [
      ...systemTags,
      ...customTags,
    ].where((tag) => tag.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D9AF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HistoryThumb(
                imageUrl: food.pictureUrl.isNotEmpty
                    ? food.pictureUrl.first
                    : null,
                icon: Icons.fastfood_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      food.description.isEmpty ? '暂无菜品描述' : food.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HistoryMetaChip(
                label: food.uploaderName.isEmpty ? '匿名上传' : food.uploaderName,
              ),
              if (food.category != null)
                _HistoryMetaChip(label: _foodCategoryLabel(food.category!)),
              if (food.likesCount > 0)
                _HistoryMetaChip(label: '${food.likesCount} 赞'),
              ...allTags.map((tag) => _HistoryMetaChip(label: tag)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '浏览于 ${_formatTimestamp(item.viewedAt)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _HistoryCardFrame extends StatelessWidget {
  const _HistoryCardFrame({
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.icon,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String footer;
  final IconData icon;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D9AF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistoryThumb(imageUrl: imageUrl, icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  footer,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryThumb extends StatelessWidget {
  const _HistoryThumb({required this.imageUrl, required this.icon});

  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = Urls.resolvePublicAssetUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: resolvedUrl == null
          ? Container(
              width: 72,
              height: 72,
              color: const Color(0xFFFFF1D4),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.accentBrown),
            )
          : Image.network(
              resolvedUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 72,
                height: 72,
                color: const Color(0xFFFFF1D4),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.accentBrown),
              ),
            ),
    );
  }
}

class _HistoryMetaChip extends StatelessWidget {
  const _HistoryMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.accentBrown,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADDB2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 34,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_edu_outlined,
              size: 44,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text('足迹加载失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '请检查网络后重试',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(int raw) {
  final milliseconds = raw.abs() < 100000000000 ? raw * 1000 : raw;
  final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.year}-$month-$day $hour:$minute';
}

String _foodCategoryLabel(String category) {
  return switch (category) {
    'STAPLE' => '主食',
    'DRINK' => '饮品',
    'SNACK' => '小吃',
    'DESSERT' => '甜品',
    'SOUP' => '汤品',
    'HOT_POT' => '火锅',
    'GRILL' => '烧烤',
    'COLD_DISH' => '凉菜',
    'SIDE_DISH' => '配菜',
    'OTHER' => '其他',
    _ => category,
  };
}
