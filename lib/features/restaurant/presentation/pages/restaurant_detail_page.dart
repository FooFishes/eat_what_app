import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/features/restaurant/presentation/view_models/restaurant_detail_view_model.dart';
import 'package:eat_what_app/shared/food/data/models/food_vo.dart';
import 'package:eat_what_app/shared/presentation/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RestaurantDetailPage extends ConsumerStatefulWidget {
  final int restaurantId;

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailPage> createState() =>
      _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends ConsumerState<RestaurantDetailPage> {
  Future<void> _openAddFoodPage() async {
    await context.push('/upload/restaurant/${widget.restaurantId}/add-food');
    if (!mounted) {
      return;
    }
    await ref
        .read(restaurantDetailViewModelProvider(widget.restaurantId).notifier)
        .loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      restaurantDetailViewModelProvider(widget.restaurantId),
    );
    final controller = ref.read(
      restaurantDetailViewModelProvider(widget.restaurantId).notifier,
    );

    if (state.isLoading && state.restaurant == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.error != null && state.restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('餐厅详情')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('餐厅详情加载失败'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: controller.loadInitial,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryStrong,
                  foregroundColor: Colors.white,
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final restaurant = state.restaurant!;
    final cover = restaurant.pictureUrl.isEmpty
        ? null
        : Urls.resolvePublicAssetUrl(restaurant.pictureUrl.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(restaurant.name), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddFoodPage,
        backgroundColor: AppColors.primaryStrong,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加菜品'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadInitial,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: cover == null
                  ? Container(
                      height: 220,
                      color: AppColors.card,
                      alignment: Alignment.center,
                      child: const Icon(Icons.storefront_rounded, size: 72),
                    )
                  : CachedNetworkImage(
                      imageUrl: cover,
                      height: 220,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        height: 220,
                        color: AppColors.card,
                        alignment: Alignment.center,
                        child: const Icon(Icons.storefront_rounded, size: 72),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.address.isEmpty ? '暂无地址信息' : restaurant.address,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ActionPill(
                        icon: Icons.favorite_border_rounded,
                        label: 'Favorite Shop',
                        onTap: () {
                          AppErrorPresenter.showMessageToast(
                            context,
                            '收藏餐厅接口暂未开放',
                            type: AppToastType.info,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _ActionPill(
                        icon: Icons.label_outline_rounded,
                        label: 'Add Tag',
                        onTap: () {
                          AppErrorPresenter.showMessageToast(
                            context,
                            '餐厅标签本期先保留 UI',
                            type: AppToastType.info,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '菜品列表',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (state.foods.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('这家店还没有菜品，先来上传第一道吧。'),
              ),
            for (final food in state.foods) ...[
              _FoodCard(
                food: food,
                onToggleFavorite: () async {
                  try {
                    await controller.toggleFavorite(food);
                  } catch (error) {
                    if (!context.mounted) return;
                    AppErrorPresenter.showErrorToast(context, error);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            if (state.hasNext)
              Center(
                child: TextButton(
                  onPressed: state.isLoadingMore
                      ? null
                      : () async {
                          try {
                            await controller.loadMore();
                          } catch (error) {
                            if (!context.mounted) return;
                            AppErrorPresenter.showErrorToast(context, error);
                          }
                        },
                  child: state.isLoadingMore
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('加载更多'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final FoodVO food;
  final VoidCallback onToggleFavorite;

  const _FoodCard({required this.food, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final cover = food.pictureUrl.isEmpty
        ? null
        : Urls.resolvePublicAssetUrl(food.pictureUrl.first);
    final tags = [
      ...food.systemTags.map((tag) => tag.name),
      ...food.myCustomTags.map((tag) => tag.name),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: cover == null
                ? Container(
                    width: 92,
                    height: 92,
                    color: AppColors.card,
                    alignment: Alignment.center,
                    child: const Icon(Icons.fastfood_rounded),
                  )
                : CachedNetworkImage(
                    imageUrl: cover,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      width: 92,
                      height: 92,
                      color: AppColors.card,
                      alignment: Alignment.center,
                      child: const Icon(Icons.fastfood_rounded),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        food.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        food.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: food.isFavorite
                            ? AppColors.accentRed
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (food.price != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '¥${food.price!.toStringAsFixed(food.price! % 1 == 0 ? 0 : 1)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryStrong,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                if (food.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      food.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in tags.take(5)) _TagChip(label: tag),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${food.likesCount} 人收藏',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
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

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.35)),
        ),
      ),
    );
  }
}
