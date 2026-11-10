import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/idempotency.dart';
import 'package:eat/data/feedback/feedback_repository.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/code_point_limit.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_radio_row.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 举报面板: 选一个原因, 补充说明选填. 提交成功后关闭面板并提示 "已提交, 我们会尽快处理".
///
/// [target] 决定标题和可选的原因. 从其他面板进入时, 关闭该面板后调用.
Future<void> showReportPanel(
  BuildContext context,
  WidgetRef ref,
  ReportTarget target,
) async {
  if (!await guardAction(context, ref, Capability.report) || !context.mounted) {
    return;
  }
  final repository = ref.read(feedbackRepositoryProvider);
  final sent = await showPanel<bool>(
    context,
    builder: (panel) => ReasonPanel<ReportReason>(
      title: '举报${target.kind.noun}',
      subtitle: '处理结果会通过消息通知你',
      options: target.reasons,
      label: (reason) => reason.label,
      capability: Capability.report,
      submit: (reason, note, key) => repository.report(
        target,
        reason: reason,
        note: note,
        idempotencyKey: key,
      ),
    ),
  );
  if (sent == true && context.mounted) {
    showToast(context, '已提交，处理结果会通过消息通知你');
  }
}

/// 选一个原因并填写选填补充说明的面板, 用于举报和店铺 "信息有误".
///
/// 提交成功后以 true 关闭面板, 由调用方显示提示. 失败时面板保留, 显示失败提示.
///
/// 不预选原因, 选好后 "提交" 才可用, 避免误提交第一项.
/// 同一份内容重试时沿用同一个 `Idempotency-Key`. 内容变化后换用新值, 因为服务端拒绝同一个键提交不同内容.
class ReasonPanel<T> extends ConsumerStatefulWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.label,
    required this.capability,
    required this.submit,
  });

  final String title;
  final String? subtitle;
  final List<T> options;
  final String Function(T option) label;

  /// 服务端拒绝时按该操作弹拦截对话框.
  final Capability capability;

  /// 提交. [key] 是本次请求的 `Idempotency-Key`. 失败时抛出 [AppFailure].
  final Future<void> Function(T option, String note, String key) submit;

  @override
  ConsumerState<ReasonPanel<T>> createState() => _ReasonPanelState<T>();
}

class _ReasonPanelState<T> extends ConsumerState<ReasonPanel<T>> {
  /// 补充说明的字数上限, 与服务端一致, 按 code point 计.
  static const _maxNote = 200;

  final _note = TextEditingController();
  T? _selected;
  var _sending = false;

  /// 最近一次提交的内容及对应的 `Idempotency-Key`.
  ({T option, String note, String key})? _last;

  @override
  void initState() {
    super.initState();
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit(T option) async {
    final note = _note.text.trim();
    final last = _last;
    final key = last != null && last.option == option && last.note == note
        ? last.key
        : newIdempotencyKey();
    _last = (option: option, note: note, key: key);
    setState(() => _sending = true);
    try {
      await widget.submit(option, note, key);
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      await reportActionFailure(
        context,
        ref,
        e,
        capability: widget.capability,
        fallback: '提交失败，请重试',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final counter = eat.text.count.copyWith(color: c.inkMuted);
    final selected = _selected;
    return EatPanel(
      title: widget.title,
      subtitle: widget.subtitle,
      actions: EatButton.solid(
        selected == null ? '选一个原因' : '提交',
        loading: _sending,
        onPressed: selected == null ? null : () => _submit(selected),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          for (final option in widget.options)
            EatRadioRow(
              title: widget.label(option),
              selected: option == selected,
              onSelected: _sending
                  ? null
                  : () => setState(() => _selected = option),
            ),
          const SizedBox(height: EatSpace.s10),
          EatFormField.multiline(
            label: '补充说明，选填',
            controller: _note,
            inputFormatters: const [CodePointLengthLimitingFormatter(_maxNote)],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${codePointLength(_note.text)} / $_maxNote',
                style: counter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
