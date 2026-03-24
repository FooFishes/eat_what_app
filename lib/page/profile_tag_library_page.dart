import 'package:eat_what_app/core/api/model/api_response.dart';
import 'package:eat_what_app/core/error/app_error_presenter.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/model/food/food_tag_summary_vo.dart';
import 'package:eat_what_app/model/food/food_vo.dart';
import 'package:eat_what_app/provider/repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileTagLibraryPage extends ConsumerStatefulWidget {
  const ProfileTagLibraryPage({super.key});

  @override
  ConsumerState<ProfileTagLibraryPage> createState() =>
      _ProfileTagLibraryPageState();
}

class _ProfileTagLibraryPageState extends ConsumerState<ProfileTagLibraryPage> {
  List<FoodTagSummaryVO>? _systemTags;
  List<FoodTagSummaryVO>? _customTags;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final hasCachedData = _systemTags != null || _customTags != null;
    if (!hasCachedData) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<List<FoodTagSummaryVO>>([
        ref.read(foodRepositoryProvider).getSystemTags(),
        _loadCustomTags(),
      ]);
      if (!mounted) {
        return;
      }

      setState(() {
        _systemTags = results[0];
        _customTags = results[1];
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (hasCachedData) {
        AppErrorPresenter.showErrorToast(context, error);
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<List<FoodTagSummaryVO>> _loadCustomTags() async {
    final mergedTags = <String, FoodTagSummaryVO>{};

    await _collectFoodTags(
      loader: ({required int page, required int pageSize}) => ref
          .read(foodRepositoryProvider)
          .getMyFoods(page: page, pageSize: pageSize),
      sink: mergedTags,
    );
    await _collectFoodTags(
      loader: ({required int page, required int pageSize}) => ref
          .read(foodRepositoryProvider)
          .getMyFavorites(page: page, pageSize: pageSize),
      sink: mergedTags,
    );
    await _collectHistoryTags(sink: mergedTags);

    final tags = mergedTags.values.toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    return tags;
  }

  Future<void> _collectFoodTags({
    required Future<PaginatedData<FoodVO>> Function({
      required int page,
      required int pageSize,
    })
    loader,
    required Map<String, FoodTagSummaryVO> sink,
  }) async {
    const pageSize = 100;
    var page = 1;
    var hasNext = true;

    while (hasNext) {
      final result = await loader(page: page, pageSize: pageSize);
      for (final food in result.items) {
        _mergeTags(food.myCustomTags, sink);
      }
      hasNext = result.hasNext;
      page++;
    }
  }

  Future<void> _collectHistoryTags({
    required Map<String, FoodTagSummaryVO> sink,
  }) async {
    const pageSize = 100;
    var page = 1;
    var hasNext = true;

    while (hasNext) {
      final result = await ref
          .read(userRepositoryProvider)
          .getBrowseHistory(targetType: 'food', page: page, pageSize: pageSize);
      for (final item in result.items) {
        final food = item.food;
        if (food != null) {
          _mergeTags(food.myCustomTags, sink);
        }
      }
      hasNext = result.hasNext;
      page++;
    }
  }

  void _mergeTags(
    List<FoodTagSummaryVO> tags,
    Map<String, FoodTagSummaryVO> sink,
  ) {
    for (final tag in tags) {
      final normalizedName = tag.name.trim();
      if (normalizedName.isEmpty) {
        continue;
      }
      sink.putIfAbsent(
        normalizedName,
        () => FoodTagSummaryVO(id: tag.id, name: normalizedName),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final systemTags = _systemTags;
    final customTags = _customTags;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('标签库'),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading && systemTags == null && customTags == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && systemTags == null && customTags == null
            ? _ProfileActionErrorState(
                title: '标签库加载失败',
                subtitle: '请稍后重试',
                onRetry: _loadTags,
              )
            : RefreshIndicator(
                onRefresh: _loadTags,
                color: AppColors.primaryStrong,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    _ProfileActionIntroCard(
                      title: '标签分区',
                      subtitle: '系统预设标签和你自己写过的备注型标签会分开显示',
                      valueText:
                          '${(systemTags?.length ?? 0) + (customTags?.length ?? 0)}',
                      helperText: '个标签',
                    ),
                    const SizedBox(height: 16),
                    _TagSectionCard(
                      title: '我的自定义标签',
                      subtitle: '聚合自你上传、收藏和浏览过的菜品中的备注型标签',
                      tags: customTags ?? const [],
                      emptyTitle: '还没有自定义标签',
                      emptySubtitle: '例如“有点辣”“小贵”这类标签会出现在这里',
                      chipColor: const Color(0xFFFFE6D8),
                      textColor: AppColors.primaryStrong,
                    ),
                    const SizedBox(height: 14),
                    _TagSectionCard(
                      title: '系统预设标签',
                      subtitle: '后端统一维护的可选标签',
                      tags: systemTags ?? const [],
                      emptyTitle: '还没有系统标签',
                      emptySubtitle: '接口还没有返回系统标签数据',
                      chipColor: const Color(0xFFE8F1D4),
                      textColor: const Color(0xFF758B22),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TagSectionCard extends StatelessWidget {
  const _TagSectionCard({
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.chipColor,
    required this.textColor,
  });

  final String title;
  final String subtitle;
  final List<FoodTagSummaryVO> tags;
  final String emptyTitle;
  final String emptySubtitle;
  final Color chipColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADDB2)),
      ),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          if (tags.isEmpty)
            _ProfileActionEmptyState(
              title: emptyTitle,
              subtitle: emptySubtitle,
              compact: true,
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: tags
                  .map(
                    (tag) => _TagLibraryChip(
                      label: tag.name,
                      backgroundColor: chipColor,
                      textColor: textColor,
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _TagLibraryChip extends StatelessWidget {
  const _TagLibraryChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileActionIntroCard extends StatelessWidget {
  const _ProfileActionIntroCard({
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.helperText,
  });

  final String title;
  final String subtitle;
  final String valueText;
  final String helperText;

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
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
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
                  text: valueText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: helperText,
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

class _ProfileActionEmptyState extends StatelessWidget {
  const _ProfileActionEmptyState({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: compact ? 20 : 28,
      ),
      decoration: BoxDecoration(
        color: compact ? const Color(0xFFFFFBF1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADDB2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 32,
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

class _ProfileActionErrorState extends StatelessWidget {
  const _ProfileActionErrorState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
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
              Icons.error_outline_rounded,
              size: 44,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
