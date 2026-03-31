import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/features/restaurant/data/models/restaurant.dart';
import 'package:eat_what_app/features/upload/presentation/view_models/restaurant_search_state.dart';
import 'package:eat_what_app/features/upload/presentation/view_models/restaurant_search_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RestaurantSearchPage extends ConsumerStatefulWidget {
  const RestaurantSearchPage({super.key});

  @override
  ConsumerState<RestaurantSearchPage> createState() =>
      _RestaurantSearchPageState();
}

class _RestaurantSearchPageState extends ConsumerState<RestaurantSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    await ref
        .read(restaurantSearchViewModelProvider.notifier)
        .search(_searchController.text);
  }

  Future<void> _openAddRestaurant() async {
    await context.push('/upload/restaurant/add');
    if (!mounted) return;
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantSearchViewModelProvider);
    final showHint = state.shouldShowIntroHint &&
        !state.hasSearched &&
        _searchController.text.trim().isEmpty;

    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 14),
        if (showHint) _buildIntroCard(),
        const SizedBox(height: 12),
        _buildAddBar(),
        const SizedBox(height: 12),
        Expanded(child: _buildBody(state)),
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildBody(RestaurantSearchState state) {
    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.results.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(restaurantSearchViewModelProvider.notifier).refresh(),
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
      onRefresh: () =>
          ref.read(restaurantSearchViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        itemCount: state.results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final restaurant = state.results[index];
          return _RestaurantCard(
            restaurant: restaurant,
            onTap: () => context.push('/restaurant/${restaurant.id}'),
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
          border:
              Border.all(color: AppColors.border.withValues(alpha: 0.2)),
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
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
