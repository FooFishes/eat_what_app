import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 个人等级页, 展示当前等级和称号, 累计经验, 升级进度, 经验规则与经验明细, 仅自己可见.
class GrowthPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    return PlainScaffold(
      title: '等级',
      titleNote: '仅自己可见',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [experienceLedgerProvider, growthProgressProvider],
        wait: () => ref.read(growthProgressProvider.future),
      ),
      slivers: [
        const SliverToBoxAdapter(child: _Progress()),
        const SliverToBoxAdapter(child: _Rules()),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s24)),
        SliverToBoxAdapter(
          child: Semantics(
            header: true,
            child: Text('经验明细', style: eat.text.heading),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        const _Ledger(),
      ],
    );
  }
}

class _Progress extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final value = ref.watch(growthProgressProvider);
    final progress = value.value;
    if (progress == null) {
      if (value.hasError && !value.isLoading) {
        return FailureState(
          message: (value.error as AppFailure?)?.message,
          onRetry: () => ref.invalidate(growthProgressProvider),
        );
      }
      return const LoadingArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: EatSpace.s10,
          children: [
            Skeleton.line(width: 96, fontSize: 26),
            Skeleton.line(width: 120, fontSize: 13),
            Skeleton(height: 8, radius: EatRadius.pill),
          ],
        ),
      );
    }
    final muted = eat.text.meta.copyWith(color: eat.colors.inkMuted);
    final next = progress.isMaxLevel
        ? '已满级'
        : '距 Lv.${progress.level + 1} 还差 ${progress.toNextLevel} 经验';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: EatSpace.s10,
          children: [
            Text(
              'Lv.${progress.level}',
              textScaler: TextScaler.noScaling,
              style: eat.text.stat.copyWith(color: eat.colors.ink),
            ),
            if (progress.title case final title?)
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.heading.copyWith(color: eat.colors.ink),
                ),
              ),
          ],
        ),
        Text('累计 ${progress.totalExperience} 经验', style: muted),
        if (!progress.isMaxLevel) ...[
          const SizedBox(height: EatSpace.s14),
          _Bar(value: progress.levelProgress),
        ],
        const SizedBox(height: EatSpace.s10),
        Text(next, style: eat.text.body.copyWith(fontWeight: FontWeight.w600)),
        if (progress.rules.isEmpty && progress.dailyExperience > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '每天第一次使用得 ${progress.dailyExperience} 经验',
              style: muted,
            ),
          ),
      ],
    );
  }
}

/// 各经验来源每次得多少经验, 每天最多几次. 服务端没给规则时不显示, 由进度下方的一句话说明每日经验.
class _Rules extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final rules = ref.watch(growthProgressProvider).value?.rules ?? const [];
    if (rules.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: EatSpace.s24),
        Semantics(header: true, child: Text('经验规则', style: eat.text.heading)),
        const SizedBox(height: EatSpace.s14),
        for (final (i, rule) in rules.indexed) ...[
          if (i > 0) const SizedBox(height: EatSpace.s16),
          EatListRow(
            title: Text(rule.name),
            lines: [if (rule.dailyCap case final cap?) Text('每天最多 $cap 次')],
            trailing: Text(
              '+${rule.amount}',
              style: eat.text.count.copyWith(color: eat.colors.ink),
            ),
          ),
        ],
      ],
    );
  }
}

/// 本级进度条. 读屏只读出百分比, 文字说明在进度条下方.
class _Bar extends StatelessWidget {
  const new({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Semantics(
      label: '本级进度',
      value: '${(value * 100).round()}%',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(EatRadius.pill),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: c.mist),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: ColoredBox(color: c.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ledger extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final value = ref.watch(experienceLedgerProvider);
    final data = value.value;
    if (data == null) {
      return SliverToBoxAdapter(
        child: value.hasError && !value.isLoading
            ? FailureState(
                message: (value.error as AppFailure?)?.message,
                onRetry: () => ref.invalidate(experienceLedgerProvider),
              )
            : LoadingArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 18,
                  children: [
                    for (var i = 0; i < 4; i++)
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: EatSpace.s8,
                        children: [
                          Skeleton.line(width: 96, fontSize: 16),
                          Skeleton.line(width: 72, fontSize: 13),
                        ],
                      ),
                  ],
                ),
              ),
      );
    }
    final entries = data.pages.items;
    if (entries.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: EatSpace.s24),
          child: EmptyState(
            icon: EatIcons.calendar,
            title: '还没有经验',
            message: '每天第一次使用都能得到经验。',
          ),
        ),
      );
    }
    final now = clock.now();
    return SliverMainAxisGroup(
      slivers: [
        SliverList.separated(
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: EatSpace.s16),
          itemBuilder: (context, i) {
            final entry = entries[i];
            return EatListRow(
              title: Text(entry.label),
              lines: [Text(TimeFormat.date(entry.date, now))],
              trailing: Text(
                '+${entry.amount}',
                style: eat.text.count.copyWith(color: eat.colors.ink),
              ),
            );
          },
        ),
        if (data.pages.hasNext)
          SliverToBoxAdapter(
            child: LoadMoreTrigger(
              generation: entries.length,
              failed: data.moreError != null,
              onVisible: () =>
                  ref.read(experienceLedgerProvider.notifier).loadMore(),
            ),
          ),
      ],
    );
  }
}
