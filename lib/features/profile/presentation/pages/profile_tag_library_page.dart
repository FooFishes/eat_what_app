import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/features/profile/presentation/view_models/profile_tag_library_view_model.dart';
import 'package:eat_what_app/shared/food/data/models/food_tag_summary_vo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileTagLibraryPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileTagLibraryViewModelProvider);
    final hasData = state.systemTags.isNotEmpty || state.customTags.isNotEmpty;

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
        child: state.isLoading && !hasData
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && !hasData
            ? _ProfileActionErrorState(
                title: '标签库加载失败',
                subtitle: '请稍后重试',
                onRetry: () => ref
                    .read(profileTagLibraryViewModelProvider.notifier)
                    .loadTags(),
              )
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(profileTagLibraryViewModelProvider.notifier)
                    .loadTags(),
                color: AppColors.primaryStrong,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const .fromLTRB(20, 16, 20, 28),
                  children: [
                    _ProfileActionIntroCard(
                      title: '标签分区',
                      subtitle: '系统预设标签和你自己写过的备注型标签会分开显示',
                      valueText:
                          '${state.systemTags.length + state.customTags.length}',
                      helperText: '个标签',
                    ),
                    const SizedBox(height: 16),
                    _TagSectionCard(
                      title: '我的自定义标签',
                      subtitle: '聚合自你上传、收藏和浏览过的菜品中的备注型标签',
                      tags: state.customTags,
                      emptyTitle: '还没有自定义标签',
                      emptySubtitle: '例如"有点辣""小贵"这类标签会出现在这里',
                      chipColor: const Color(0xFFFFE6D8),
                      textColor: AppColors.primaryStrong,
                    ),
                    const SizedBox(height: 14),
                    _TagSectionCard(
                      title: '系统预设标签',
                      subtitle: '后端统一维护的可选标签',
                      tags: state.systemTags,
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
  const new({
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
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(20),
        border: Border.all(color: const Color(0xFFEADDB2)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: .w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
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
      padding: const .symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: .circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: textColor, fontWeight: .w700),
      ),
    );
  }
}

class _ProfileActionIntroCard extends StatelessWidget {
  const new({
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
      padding: const .all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DF),
        borderRadius: .circular(20),
        border: Border.all(color: const Color(0xFFF0E2B6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: .w800),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
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
                    fontWeight: .w800,
                  ),
                ),
                TextSpan(
                  text: helperText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: .w600,
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
  const new({
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
      padding: .symmetric(horizontal: 18, vertical: compact ? 20 : 28),
      decoration: BoxDecoration(
        color: compact ? const Color(0xFFFFFBF1) : Colors.white,
        borderRadius: .circular(20),
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

class _ProfileActionErrorState extends StatelessWidget {
  const new({
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
        padding: const .symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: .min,
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
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
