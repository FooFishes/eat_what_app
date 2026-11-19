import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 浏览历史页 ("历史"), 按浏览时间倒序展示最近看过的菜品和店铺, 仅自己可见.
///
/// 点击右上角 "清空" 可清除当前分栏的记录.
class HistoryPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  var _kind = FootprintKind.dish;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final provider = footprintsProvider(_kind);
    final value = ref.watch(provider);
    final empty = value.value?.pages.items.isEmpty ?? true;
    return PlainScaffold(
      title: '历史',
      titleNote: '仅自己可见',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [provider],
        wait: () => ref.read(provider.future),
      ),
      actions: [
        EatTappable(
          onTap: empty ? null : _clear,
          label: '清空',
          builder: (context, _) => SizedBox(
            height: EatSize.touch,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                widthFactor: 1,
                child: Text(
                  '清空',
                  style: eat.text.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: empty ? eat.colors.disabledFg : eat.colors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: EatTabs(
            tabs: const [EatTabItem('菜'), EatTabItem('店')],
            selected: _kind.index,
            onSelected: (i) => setState(() => _kind = FootprintKind.values[i]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        _FootprintList(kind: _kind),
      ],
    );
  }

  Future<void> _clear() async {
    final kind = _kind;
    final label = switch (kind) {
      FootprintKind.dish => '菜',
      FootprintKind.shop => '店',
    };
    final confirmed = await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        title: '清空看过的$label？',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '取消',
                onPressed: () => Navigator.of(dialog).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '清空',
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(footprintsProvider(kind).notifier).clear();
    } on AppFailure catch (e) {
      if (mounted) {
        showToast(
          context,
          e.kind == FailureKind.unknown ? '清空失败，请重试' : e.message,
        );
      }
    }
  }
}

class _FootprintList extends ConsumerWidget {
  const new({required this.kind});

  final FootprintKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final provider = footprintsProvider(kind);
    final value = ref.watch(provider);
    final data = value.value;
    if (data == null) {
      return SliverToBoxAdapter(
        child: value.hasError && !value.isLoading
            ? FailureState(
                error: value.error,
                onRetry: () => ref.invalidate(provider),
              )
            : const RowListPlaceholder(count: 6),
      );
    }
    final items = data.pages.items;
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: EmptyState(
            icon: EatIcons.history,
            title: switch (kind) {
              FootprintKind.dish => '还没看过菜',
              FootprintKind.shop => '还没看过店',
            },
            message: '看过的菜和店会按时间记录在这里。',
          ),
        ),
      );
    }
    final now = clock.now();
    return SliverMainAxisGroup(
      slivers: [
        SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: EatSpace.s16),
          itemBuilder: (context, i) {
            final item = items[i];
            return EatListRow(
              leading: ListThumb(
                image: networkImage(item.image, width: EatSize.thumb),
              ),
              title: Text(item.name),
              lines: [
                if (item.likes case final likes? when likes > 0)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$likes', style: eat.text.count),
                        const TextSpan(text: ' 个赞'),
                      ],
                    ),
                  ),
              ],
              trailing: Text(
                TimeFormat.relative(item.viewedAt, now),
                style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
              ),
              onTap: () => context.push(switch (item.kind) {
                FootprintKind.dish => Paths.dish(item.id),
                FootprintKind.shop => Paths.shop(item.id),
              }),
            );
          },
        ),
        if (data.pages.hasNext)
          SliverToBoxAdapter(
            child: LoadMoreTrigger(
              generation: items.length,
              failed: data.moreError != null,
              onVisible: () => ref.read(provider.notifier).loadMore(),
            ),
          ),
      ],
    );
  }
}
