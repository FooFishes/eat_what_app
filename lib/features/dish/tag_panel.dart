import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/features/dish/dish_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 加标签面板（`G-PanelTag`）：上面是口味词表，多选，打过的是选中态；下面「＋ 自己写」写进我的标签，
/// 旁边写明「只有你自己看得见」（产品 6.5、4.6）。
///
/// 「词表里没有想要的？告诉我们」要进反馈页，反馈在阶段六做，先不放。
Future<void> showTagPanel(BuildContext context, {required int dishId}) =>
    showPanel<void>(context, builder: (_) => _TagPanel(dishId: dishId));

class _TagPanel extends ConsumerStatefulWidget {
  const new({required this.dishId});

  final int dishId;

  @override
  ConsumerState<_TagPanel> createState() => _TagPanelState();
}

class _TagPanelState extends ConsumerState<_TagPanel> {
  Set<int>? _selected;
  final _mine = <String>[];
  final _input = TextEditingController();
  var _writing = false;
  var _busy = false;
  String? _error;

  /// 我的标签每个最多 10 个字（产品 9.1）。
  static const _maxLength = 10;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _addMine() {
    final name = _input.text.trim();
    if (name.isEmpty) return;
    if (_mine.contains(name)) {
      _input.clear();
      return;
    }
    setState(() {
      _mine.add(name);
      _input.clear();
    });
  }

  Future<void> _done() async {
    final selected = _selected;
    if (selected == null) return;
    _addMine();
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await ref
        .read(dishTagsOfProvider(widget.dishId).notifier)
        .apply(taste: selected, newMine: _mine);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      showToast(context, '标签已保存');
    } else {
      setState(() {
        _busy = false;
        _error = failure.kind == FailureKind.unknown
            ? '保存失败，请重试'
            : failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final vocabulary = ref.watch(tasteVocabularyProvider);
    final tags = ref.watch(dishTagsOfProvider(widget.dishId));
    final selected = _selected ??= {
      for (final t in tags?.taste ?? const [])
        if (t.mine) t.id,
    };
    return EatPanel(
      title: '加标签',
      subtitle: '口味标签大家都看得见',
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EatSpace.s8,
        children: [
          if (_error case final error?)
            Text(error, style: eat.text.meta.copyWith(color: c.warn)),
          EatButton.solid('完成', loading: _busy, onPressed: _done),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (vocabulary) {
            AsyncData(:final value) => Wrap(
              spacing: EatSpace.s8,
              children: [
                for (final tag in value)
                  EatChip.tag(
                    tag.name,
                    selected: selected.contains(tag.id),
                    onTap: () => setState(() {
                      if (!selected.remove(tag.id)) selected.add(tag.id);
                    }),
                  ),
              ],
            ),
            AsyncError() => FailureState(
              onRetry: () => ref.invalidate(tasteVocabularyProvider),
            ),
            _ => const RowListPlaceholder(count: 2, thumbSize: 36),
          },
          const SizedBox(height: EatSpace.s16),
          Text(
            '我的标签',
            style: eat.text.meta.copyWith(
              fontWeight: FontWeight.w600,
              color: c.inkMuted,
            ),
          ),
          Wrap(
            spacing: EatSpace.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tag in tags?.mine ?? const [])
                EatChip.tag(tag.name, selected: true, onTap: null),
              for (final name in _mine)
                EatChip.tag(
                  name,
                  selected: true,
                  onTap: () => setState(() => _mine.remove(name)),
                ),
              if (!_writing)
                EatChip.add(
                  '＋ 自己写',
                  onTap: () => setState(() => _writing = true),
                ),
            ],
          ),
          if (_writing)
            EatFormField(
              label: '自己写一个标签',
              controller: _input,
              autofocus: true,
              hintText: '比如 考试周',
              textInputAction: TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(_maxLength)],
              onSubmitted: (_) => _addMine(),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '我的标签只有你自己看得见',
              style: eat.text.caption.copyWith(color: c.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
