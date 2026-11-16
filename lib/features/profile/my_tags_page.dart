import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/profile_rules.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 我的标签页, 展示当前用户创建的自定义标签及其关联菜品数量, 点击标签可进入 "标签下的菜".
///
/// 点击右上角 "编辑" 可切换至编辑态以重命名或删除标签, 删除操作仅移除标签本身而不影响菜品.
class MyTagsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MyTagsPage> createState() => _MyTagsPageState();
}

class _MyTagsPageState extends ConsumerState<MyTagsPage> {
  var _editing = false;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final verified = ref.watch(accountStatusProvider) is VerifiedStatus;
    final value = ref.watch(myTagsProvider);
    final tags = value.value;
    return PlainScaffold(
      title: '我的标签',
      titleNote: '仅自己可见',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [myTagsProvider],
        wait: () => ref.read(myTagsProvider.future),
      ),
      actions: [
        if (tags != null && tags.isNotEmpty)
          EatTappable(
            onTap: () => setState(() => _editing = !_editing),
            label: _editing ? '完成' : '编辑',
            builder: (context, _) => SizedBox(
              height: EatSize.touch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    _editing ? '完成' : '编辑',
                    style: eat.text.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: eat.colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
      slivers: [
        if (!verified)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: EatIcons.tag,
                title: '认证后才能加标签',
                message: '完成学生认证后，就能为菜品添加专属标签。',
                action: EatButton.solid(
                  '去认证',
                  height: 48,
                  onPressed: () => context.push(Paths.verify),
                ),
              ),
            ),
          )
        else if (tags == null)
          SliverToBoxAdapter(
            child: value.hasError && !value.isLoading
                ? FailureState(
                    message: (value.error as AppFailure?)?.message,
                    onRetry: () => ref.invalidate(myTagsProvider),
                  )
                : const RowListPlaceholder(count: 6),
          )
        else if (tags.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: EatIcons.tag,
                title: '还没有标签',
                message: '在菜品详情点「加标签」，写下自己的分类，比如「考试周」「请客」。',
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: tags.length,
            separatorBuilder: (_, _) => const SizedBox(height: EatSpace.s8),
            itemBuilder: (context, i) => _TagRow(
              tag: tags[i],
              editing: _editing,
              onRename: () => _rename(tags[i], tags),
              onDelete: () => _delete(tags[i]),
            ),
          ),
      ],
    );
  }

  Future<void> _rename(MyTag tag, List<MyTag> all) => showPanel<void>(
    context,
    builder: (_) => _RenamePanel(
      tag: tag,
      others: [
        for (final t in all)
          if (t.id != tag.id) t.name,
      ],
    ),
  );

  Future<void> _delete(MyTag tag) async {
    final usage = tag.usage;
    final confirmed = await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        title: '删除「${tag.name}」？',
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
                '删除',
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
            ),
          ],
        ),
        subtitle: usage == null || usage == 0
            ? '仅删除标签，菜品不受影响。'
            : '仅删除标签，已标记的 $usage 道菜不受影响。',
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(myTagsProvider.notifier).delete(tag);
      if (mounted) showToast(context, '已删除');
    } on AppFailure catch (e) {
      if (mounted) {
        showToast(
          context,
          e.kind == FailureKind.unknown ? '删除失败，请重试' : e.message,
        );
      }
    }
  }
}

class _TagRow extends StatelessWidget {
  const new({
    required this.tag,
    required this.editing,
    required this.onRename,
    required this.onDelete,
  });

  final MyTag tag;
  final bool editing;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final usage = tag.usage;
    return SizedBox(
      height: 56,
      child: EatListRow(
        title: Text(tag.name),
        // 行尾的箭头表示点击后进入该标签下的菜. 只显示数量时, 这一行没有可点击的提示.
        trailing: editing
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                spacing: EatSpace.s4,
                children: [
                  if (usage != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$usage', style: eat.text.count),
                          const TextSpan(text: ' 道菜'),
                        ],
                      ),
                      style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
                    ),
                  EatIcon(
                    EatIcons.chevronRight,
                    size: 20,
                    color: eat.colors.inkMuted,
                  ),
                ],
              ),
        onTap: editing
            ? null
            : () => context.push(Paths.myTag(tag.id, tag.name)),
        action: editing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EatIconButton(
                    EatIcons.edit,
                    label: '改名',
                    onPressed: onRename,
                  ),
                  EatIconButton(
                    EatIcons.delete,
                    label: '删除',
                    onPressed: onDelete,
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

/// 标签重命名面板, 提交失败时在面板内部显示错误提示.
class _RenamePanel extends ConsumerStatefulWidget {
  const new({required this.tag, required this.others});

  final MyTag tag;

  /// 其他标签的名字. 新名字不能与其中任何一个重复.
  final List<String> others;

  @override
  ConsumerState<_RenamePanel> createState() => _RenamePanelState();
}

class _RenamePanelState extends ConsumerState<_RenamePanel> {
  late final _name = TextEditingController(text: widget.tag.name);
  String? _error;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final error = ProfileRules.myTagError(name, widget.others);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (name == widget.tag.name) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(myTagsProvider.notifier).rename(widget.tag, name);
      if (mounted) Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.kind == FailureKind.unknown ? '改名失败，请重试' : e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => EatPanel(
    title: '改标签名',
    actions: EatButton.solid('保存', loading: _saving, onPressed: _submit),
    child: EatFormField(
      label: '标签名',
      controller: _name,
      autofocus: true,
      hintText: '最多 ${ProfileRules.myTagMax} 个字',
      errorText: _error,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        LengthLimitingTextInputFormatter(ProfileRules.myTagMax),
      ],
      onSubmitted: (_) => _submit(),
    ),
  );
}
