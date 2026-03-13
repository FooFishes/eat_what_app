import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat_what_app/controller/foodie_map_page_controller.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/model/activity/regional_food.dart';
import 'package:eat_what_app/model/location/province.dart';
import 'package:eat_what_app/model/location/province_response.dart';
import 'package:eat_what_app/widget/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FoodieMapPage extends ConsumerWidget {
  const FoodieMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<FoodieMapPageState>(foodieMapPageControllerProvider, (
      FoodieMapPageState? previous,
      FoodieMapPageState next,
    ) {
      final feedback = next.feedback;
      if (feedback == null || feedback.id == previous?.feedback?.id) {
        return;
      }

      _showFeedback(context, feedback);
      ref.read(foodieMapPageControllerProvider.notifier).clearFeedback();
    });

    final pageState = ref.watch(foodieMapPageControllerProvider);
    final controller = ref.read(foodieMapPageControllerProvider.notifier);

    if (pageState.isInitialLoading) {
      return Scaffold(
        body: SafeArea(
          child: FeatureTitle(
            '美食地图',
            child: Center(child: _buildLoadingIndicator(isLarge: true)),
          ),
        ),
      );
    }

    final Widget provincesBar;
    if (pageState.isLoadingProvinces) {
      provincesBar = SizedBox(
        height: 60,
        width: double.infinity,
        child: Center(child: _buildLoadingIndicator()),
      );
    } else if (pageState.hasProvincesError) {
      provincesBar = SizedBox(
        height: 60,
        width: double.infinity,
        child: Center(
          child: _buildRetryMessage(
            context,
            message: '省份加载失败',
            hint: '点击重试',
            onPressed: controller.retryLoadProvinces,
          ),
        ),
      );
    } else if (pageState.provinces.isEmpty) {
      provincesBar = SizedBox(
        height: 60,
        width: double.infinity,
        child: Center(
          child: _buildRetryMessage(
            context,
            message: '暂无省份发布过美食',
            hint: '点击刷新',
            onPressed: controller.retryLoadProvinces,
          ),
        ),
      );
    } else {
      provincesBar = _ProvincesBar(
        provinces: pageState.provinces,
        selectedProvinceId: pageState.selectedProvinceId,
        onChanged: controller.selectProvince,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: FeatureTitle(
          '美食地图',
          child: Column(
            children: [
              _FoodieMapHeader(pageState.localProvinceId),
              provincesBar,
              pageState.committedProvinceId == null
                  ? const Spacer()
                  : _FoodList(
                      key: ValueKey<int>(pageState.committedProvinceId!),
                      provinceId: pageState.committedProvinceId!,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedback(BuildContext context, FoodieMapFeedback feedback) {
    final toastType = switch (feedback.kind) {
      FoodieMapFeedbackKind.warning => AppToastType.warning,
      FoodieMapFeedbackKind.error => AppToastType.error,
    };

    AppErrorPresenter.showMessageToast(
      context,
      feedback.content,
      type: toastType,
    );
  }
}

class _FoodieMapHeader extends StatelessWidget {
  final int? provinceId;

  const _FoodieMapHeader(this.provinceId);

  @override
  Widget build(BuildContext context) {
    final Widget locationWidget;

    if (provinceId == null) {
      locationWidget = Positioned(
        left: 20,
        bottom: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(
              Icons.location_on,
              size: 30,
              color: AppColors.primaryStrong,
            ),
            Text(
              '未获取到当前位置',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    } else {
      final name = Province.fromId(provinceId!)?.shortName ?? '未知省份';
      final nameLeftPadding = switch (name.length) {
        <= 2 => 50.0,
        3 => 40.0,
        _ => 0.0,
      };
      locationWidget = Positioned(
        left: 20,
        right: 60,
        bottom: 15,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 30,
                  color: AppColors.primaryStrong,
                ),
                Text(
                  '当前所在地：',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: nameLeftPadding, top: 10),
              child: FittedBox(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.accentRed,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(right: 10, top: 10, child: _buildChinaMap(provinceId)),
          locationWidget,
        ],
      ),
    );
  }

  Widget _buildChinaMap(int? provinceId) {
    final province = provinceId == null ? null : Province.fromId(provinceId);
    final code = (province != null && province.isInChina) ? province.code : null;
    final path = code == null
        ? 'assets/images/china_map/base.png'
        : 'assets/images/china_map/$code.png';
    return Image.asset(path, height: 170);
  }
}

class FeatureTitle extends StatelessWidget {
  final String title;
  final Widget child;

  const FeatureTitle(this.title, {required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          child,
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            child: Image.asset('assets/images/firework.png', height: 50),
          ),
          Positioned(
            left: 30,
            top: 30,
            right: 10,
            child: Align(
              alignment: Alignment.topLeft,
              child: FittedBox(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvincesBar extends StatelessWidget {
  final int? selectedProvinceId;
  final List<ProvinceResponse> provinces;
  final ValueChanged<int> onChanged;

  const _ProvincesBar({
    required this.provinces,
    required this.selectedProvinceId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provinces.length,
        itemBuilder: (context, index) {
          final current = provinces[index];
          final isSelected = current.id == selectedProvinceId;
          return Container(
            margin: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isSelected
                      ? AppColors.accentRed
                      : AppColors.textPrimary,
                  width: 1,
                ),
              ),
              onPressed: isSelected ? null : () => onChanged(current.id),
              child: Text(
                current.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? AppColors.accentRed : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FoodList extends ConsumerStatefulWidget {
  final int provinceId;

  const _FoodList({required this.provinceId, super.key});

  @override
  ConsumerState<_FoodList> createState() => _FoodListState();
}

class _FoodListState extends ConsumerState<_FoodList> {
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = foodieMapFoodListControllerProvider(widget.provinceId);

    ref.listen<FoodieMapFoodListState>(provider, (
      FoodieMapFoodListState? previous,
      FoodieMapFoodListState next,
    ) {
      final feedback = next.feedback;
      if (feedback == null || feedback.id == previous?.feedback?.id) {
        return;
      }

      final toastType = switch (feedback.kind) {
        FoodieMapFeedbackKind.warning => AppToastType.warning,
        FoodieMapFeedbackKind.error => AppToastType.error,
      };
      AppErrorPresenter.showMessageToast(
        context,
        feedback.content,
        type: toastType,
      );
      ref.read(provider.notifier).clearFeedback();
    });

    final listState = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (listState.foods.isEmpty) {
      if (listState.isLoading) {
        return Expanded(
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: _buildLoadingIndicator(isLarge: true),
          ),
        );
      }
      if (listState.hasError) {
        return Expanded(
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: _buildRetryMessage(
              context,
              message: '加载失败',
              hint: '点击重试',
              onPressed: controller.refresh,
            ),
          ),
        );
      }
      return Expanded(
        child: Align(
          alignment: const Alignment(0, -0.3),
          child: _buildRetryMessage(
            context,
            message: '还没有人上传该地区的美食哦',
            hint: '点击刷新',
            onPressed: controller.refresh,
          ),
        ),
      );
    }

    final itemCount =
        listState.foods.length +
        (listState.isLoading && listState.foods.isNotEmpty ? 1 : 0);

    return Expanded(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < listState.foods.length) {
            final food = listState.foods[index];
            return _FoodItem(
              food: food,
              isLiking: listState.pendingLikeIds.contains(food.id),
              onPressed: () => controller.toggleLike(food.id),
            );
          }
          return Center(child: _buildLoadingIndicator());
        },
      ),
    );
  }

  void _onScroll() {
    final currentScrollPosition = _scrollController.position.pixels;
    if (currentScrollPosition > _lastScrollPosition &&
        currentScrollPosition >=
            _scrollController.position.maxScrollExtent - 150) {
      _debounce(() {
        ref
            .read(foodieMapFoodListControllerProvider(widget.provinceId).notifier)
            .loadNextPage();
      }, _debounceDuration);
    }
    _lastScrollPosition = currentScrollPosition;
  }

  void _debounce(VoidCallback callback, Duration duration) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }
}

class _FoodItem extends StatelessWidget {
  final RegionalFood food;
  final bool isLiking;
  final VoidCallback? onPressed;

  const _FoodItem({
    required this.food,
    required this.isLiking,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDD1),
        borderRadius: BorderRadius.circular(23),
      ),
      height: 135,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;
          return Row(
            children: [
              Container(
                constraints: BoxConstraints(
                  minHeight: maxHeight * 0.8,
                  maxHeight: maxHeight * 0.8,
                  minWidth: maxHeight * 0.8,
                  maxWidth: maxHeight * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: food.url == null
                      ? Center(
                          child: Text(
                            '暂无图片',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: food.url!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              '图片加载失败',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              child: Text(
                                food.foodName,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            onPressed: isLiking ? null : onPressed,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              size: 25,
                              food.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: food.isLiked
                                  ? AppColors.accentRed
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      food.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    FittedBox(
                      child: Text(
                        food.accountName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _buildLoadingIndicator({bool isLarge = false}) {
  final side = isLarge ? 50.0 : 20.0;
  final strokeWidth = isLarge ? 5.0 : 3.0;
  return Padding(
    padding: const EdgeInsets.all(5),
    child: SizedBox(
      height: side,
      width: side,
      child: CircularProgressIndicator(strokeWidth: strokeWidth),
    ),
  );
}

Widget _buildRetryMessage(
  BuildContext context, {
  required String message,
  required String hint,
  required VoidCallback onPressed,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      TextButton(
        onPressed: onPressed,
        child: Text(
          hint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary,
          ),
        ),
      ),
    ],
  );
}
