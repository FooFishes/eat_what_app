import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat_what_app/core/api/model/api_response.dart';
import 'package:eat_what_app/core/constant/restaurant_mock.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/model/restaurant/restaurant.dart';
import 'package:eat_what_app/provider/repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantSearchPage extends ConsumerStatefulWidget {
  const RestaurantSearchPage({super.key});

  @override
  ConsumerState<RestaurantSearchPage> createState() =>
      _RestaurantSearchPageState();
}

class _RestaurantSearchPageState extends ConsumerState<RestaurantSearchPage> {
  static const String _howHintSeenKey = 'restaurant_search_how_hint_seen';

  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _items = const [];
  bool _isLoading = true;
  bool _hasSearched = false;
  bool _shouldShowIntroHint = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitialSearch);
    Future.microtask(_initHowHint);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initHowHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_howHintSeenKey) ?? false;
      if (seen) {
        return;
      }

      await prefs.setBool(_howHintSeenKey, true);
      if (!mounted) {
        return;
      }
      setState(() {
        _shouldShowIntroHint = true;
      });
    } catch (_) {
      // Ignore local persistence failures and keep the page usable.
    }
  }

  Future<void> _loadInitialSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = false;
    });

    try {
      final page = await ref
          .read(restaurantRepositoryProvider)
          .searchRestaurants(
            '',
            gcjLng: RestaurantMock.gcjLng,
            gcjLat: RestaurantMock.gcjLat,
            page: 1,
            pageSize: 20,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = page.items;
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

  Future<void> _search() async {
    if (_shouldShowIntroHint) {
      setState(() {
        _shouldShowIntroHint = false;
      });
    }

    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      await _loadInitialSearch();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final PaginatedData<Restaurant> page = await ref
          .read(restaurantRepositoryProvider)
          .searchRestaurants(
            keyword,
            gcjLng: RestaurantMock.gcjLng,
            gcjLat: RestaurantMock.gcjLat,
            page: 1,
            pageSize: 20,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = page.items;
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

  Future<void> _openAddRestaurant() async {
    await context.push('/upload/restaurant/add');
    if (!mounted) {
      return;
    }
    await _search();
  }

  Future<void> _openRestaurant(Restaurant restaurant) async {
    await context.push('/restaurant/${restaurant.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 14),
        if (_shouldShowIntroHint &&
            !_hasSearched &&
            _searchController.text.trim().isEmpty)
          _buildIntroCard(),
        const SizedBox(height: 12),
        _buildAddBar(),
        const SizedBox(height: 12),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                hintText: '搜索店铺名称',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: _search,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryStrong,
            foregroundColor: Colors.white,
            minimumSize: const Size(88, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Enter'),
        ),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryStrong,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryStrong,
            ),
          ),
          const SizedBox(height: 10),
          _StepCard(step: 'Step1', text: '先搜索店铺名称，确认这家店是否已经有人上传。'),
          const SizedBox(height: 10),
          _StepCard(step: 'Step2', text: '找到了就直接进店铺详情添加菜品；找不到再新建店铺。'),
        ],
      ),
    );
  }

  Widget _buildAddBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '没有找到你想的店铺？点击添加',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            onPressed: _openAddRestaurant,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryStrong,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_mall_directory_outlined, size: 42),
            const SizedBox(height: 12),
            const Text('餐厅列表加载失败'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _search,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryStrong,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _search,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            Center(
              child: Text(
                '没有匹配到店铺，试试换个关键词，或者直接添加新店铺。',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _search,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final restaurant = _items[index];
          return _RestaurantCard(
            restaurant: restaurant,
            onTap: () => _openRestaurant(restaurant),
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cover = restaurant.pictureUrl.isEmpty
        ? null
        : Urls.resolvePublicAssetUrl(restaurant.pictureUrl.first);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: cover == null
                  ? Container(
                      width: 72,
                      height: 72,
                      color: AppColors.primarySoft,
                      alignment: Alignment.center,
                      child: Text(
                        restaurant.name.isEmpty ? '餐厅' : restaurant.name[0],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.accentBrown,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: cover,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        width: 72,
                        height: 72,
                        color: AppColors.primarySoft,
                        alignment: Alignment.center,
                        child: const Icon(Icons.storefront_rounded),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    restaurant.address.isEmpty ? '暂无地址信息' : restaurant.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    restaurant.poi == null || restaurant.poi!.isEmpty
                        ? '校园餐厅'
                        : restaurant.poi!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String text;

  const _StepCard({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
