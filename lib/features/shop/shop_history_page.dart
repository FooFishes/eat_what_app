import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/dish_revision.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/shop/shop_providers.dart';
import 'package:eat/features/system/comment_card.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 店铺的修改记录: 白底列表, 最新的在前.
///
/// - 每行写编辑者, 时间, 动作和改了哪些字段.
/// - 最新一条就是店铺现在的样子, 标 "当前版本". 其余每条都能恢复, 恢复前二次确认.
/// - 恢复要求已认证, 点击时检查权限. 修改记录谁都能看.
class ShopHistoryPage extends ConsumerWidget {
  const new({super.key, required this.shopId});

  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = shopHistoryProvider(shopId);
    final history = ref.watch(provider);
    final name = ref.watch(shopProvider(shopId).select((s) => s.value?.name));
    final data = history.value;
    final revisions = data?.pages.items ?? const <ShopRevision>[];
    return PlainScaffold(
      title: '修改记录',
      titleNote: name,
      onRefresh: () async {
        ref.invalidate(provider);
        try {
          await ref.read(provider.future);
        } on AppFailure catch (e) {
          if (context.mounted) showToast(context, e.message);
        }
      },
      slivers: [
        switch (data) {
          null when history.hasError && !history.isLoading =>
            SliverToBoxAdapter(
              child: switch (history.error) {
                AppFailure(code: BizCodes.restaurantNotFound) =>
                  const EmptyState(icon: EatIcons.store, title: '这家店已删除'),
                final error => FailureState(
                  message: (error as AppFailure?)?.message,
                  onRetry: () => ref.invalidate(provider),
                ),
              },
            ),
          null => const SliverToBoxAdapter(child: RowListPlaceholder(count: 4)),
          _ when revisions.isEmpty => const SliverToBoxAdapter(
            child: EmptyState(icon: EatIcons.history, title: '还没有修改记录'),
          ),
          final data => SliverMainAxisGroup(
            slivers: [
              SliverList.separated(
                itemCount: revisions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, i) => _RevisionRow(
                  shopId: shopId,
                  revision: revisions[i],
                  current: i == 0,
                ),
              ),
              if (data.pages.hasNext)
                SliverToBoxAdapter(
                  child: LoadMoreTrigger(
                    generation: revisions.length,
                    failed: data.moreError != null,
                    onVisible: () => ref.read(provider.notifier).loadMore(),
                  ),
                ),
            ],
          ),
        },
      ],
    );
  }
}

/// 修改记录的一行. [current] 为 true 时是最新一条, 不能恢复.
class _RevisionRow extends ConsumerWidget {
  const new({
    required this.shopId,
    required this.revision,
    required this.current,
  });

  final int shopId;
  final ShopRevision revision;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final name = revision.editorName ?? '已注销的用户';
    final fields = [for (final f in revision.fields) f.label].join('、');
    final what = switch (revision.action) {
      RevisionAction.create => '新建了这家店',
      RevisionAction.edit when fields.isEmpty => '修改了店铺',
      RevisionAction.edit => '改了$fields',
      RevisionAction.restore when fields.isEmpty => '恢复到之前的版本',
      RevisionAction.restore => '恢复到之前的版本，改了$fields',
    };
    final time = revision.createdAt;
    return EatListRow(
      leading: EatAvatar(
        name: name,
        color: avatarColorOf(revision.editorId ?? 0),
        image: networkImage(revision.editorAvatar, width: EatSize.avatar),
      ),
      title: Text(name, maxLines: 1),
      lines: [
        Text(what, style: eat.text.body.copyWith(color: eat.colors.ink)),
        if (time != null) Text(TimeFormat.relative(time, clock.now())),
      ],
      trailing: current
          ? Text(
              '当前版本',
              style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
            )
          : null,
      action: current
          ? null
          : EatButton.mist(
              '恢复',
              height: 36,
              onPressed: () => _restore(context, ref),
            ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    if (!await guardAction(context, ref, Capability.editShop) ||
        !context.mounted) {
      return;
    }
    final confirmed = await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        title: '恢复到这个版本？',
        subtitle: '店铺资料会改回这次修改之后的样子，算作一次新的修改。',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '先不恢复',
                onPressed: () => Navigator.of(dialog).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '恢复',
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(placeRepositoryProvider).restore(shopId, revision.id);
      ref
        ..invalidate(shopProvider(shopId))
        ..invalidate(shopHistoryProvider(shopId));
      if (context.mounted) showToast(context, '已恢复');
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      if (e.code == BizCodes.stateNotAllowed) {
        showToast(context, '已经是这个版本');
        return;
      }
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.editShop,
        fallback: '恢复失败，请重试',
      );
    }
  }
}
