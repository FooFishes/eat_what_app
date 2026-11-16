import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/dish_revision.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/dish/dish_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 菜品修改记录页, 以白底列表按时间倒序展示变更历史.
///
/// - 每条记录展示编辑者, 时间, 操作类型与变动字段.
/// - 首条标注为 "当前版本", 其余历史版本支持恢复操作 (需账号已认证并经二次确认).
class DishHistoryPage extends ConsumerWidget {
  const new({super.key, required this.dishId});

  final int dishId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = dishHistoryProvider(dishId);
    final value = ref.watch(provider);
    final data = value.value;
    return PlainScaffold(
      title: '修改记录',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [provider],
        wait: () => ref.read(provider.future),
      ),
      slivers: [
        if (data == null)
          SliverToBoxAdapter(
            child: value.hasError && !value.isLoading
                ? FailureState(
                    error: value.error,
                    onRetry: () => ref.invalidate(provider),
                  )
                : const RowListPlaceholder(count: 4, thumbSize: EatSize.avatar),
          )
        else if (data.pages.items.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: EmptyState(
                icon: EatIcons.history,
                title: '还没有修改记录',
                message: '编辑过这道菜后，每次修改都会记在这里',
              ),
            ),
          )
        else ...[
          SliverList.separated(
            itemCount: data.pages.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: EatSpace.s16),
            itemBuilder: (context, i) => _RevisionRow(
              dishId: dishId,
              revision: data.pages.items[i],
              current: i == 0,
            ),
          ),
          if (data.pages.hasNext)
            SliverToBoxAdapter(
              child: LoadMoreTrigger(
                generation: data.pages.items.length,
                failed: data.moreError != null,
                onVisible: () => ref.read(provider.notifier).loadMore(),
              ),
            ),
        ],
      ],
    );
  }
}

/// 修改记录的一行. [current] 为 true 时是当前内容, 不提供恢复.
class _RevisionRow extends ConsumerStatefulWidget {
  const new({
    required this.dishId,
    required this.revision,
    required this.current,
  });

  final int dishId;
  final DishRevision revision;
  final bool current;

  @override
  ConsumerState<_RevisionRow> createState() => _RevisionRowState();
}

class _RevisionRowState extends ConsumerState<_RevisionRow> {
  var _busy = false;

  Future<void> _restore() async {
    if (!await guardAction(context, ref, Capability.editDish) || !mounted) {
      return;
    }
    final confirmed = await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        title: '恢复到这个版本？',
        subtitle: '菜品会改回这次修改后的内容，恢复也会记入修改记录。',
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
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(dishHistoryProvider(widget.dishId).notifier)
          .restore(widget.revision);
      if (mounted) showToast(context, '已恢复');
    } on AppFailure catch (e) {
      if (!mounted) return;
      if (e.code == BizCodes.stateNotAllowed) {
        showToast(context, '已经是这个版本');
        return;
      }
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.editDish,
        fallback: '恢复失败，请重试',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final revision = widget.revision;
    final name = revision.editorId == null
        ? '已注销用户'
        : revision.editorName ?? '同学';
    final created = revision.createdAt;
    return EatListRow(
      leading: EatAvatar(
        name: name,
        color: StageColor
            .values[(revision.editorId ?? 0) % StageColor.values.length],
        image: networkImage(revision.editorAvatar, width: EatSize.avatar),
      ),
      title: Text(name),
      lines: [
        Text(_summary(revision)),
        if (created != null) Text(TimeFormat.relative(created, clock.now())),
      ],
      trailing: widget.current
          ? Text(
              '当前版本',
              style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
            )
          : null,
      action: widget.current
          ? null
          : EatButton.outline(
              '恢复',
              height: 36,
              loading: _busy,
              onPressed: _restore,
            ),
    );
  }
}

/// 生成单条修改记录的摘要文案, 如 "修改了价格、照片".
String _summary(DishRevision revision) {
  final fields = revision.fields.map((f) => f.label).join('、');
  return switch (revision.action) {
    RevisionAction.create => '新建了这道菜',
    RevisionAction.edit when fields.isEmpty => '修改了这道菜',
    RevisionAction.edit => '修改了$fields',
    RevisionAction.restore when fields.isEmpty => '恢复到之前的版本',
    RevisionAction.restore => '恢复到之前的版本，改回了$fields',
  };
}
