import 'package:eat/core/failure/app_failure.dart';
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
import 'package:eat/state/comments.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 弹出举报面板, 用户选择举报原因并填写可选补充说明后提交.
///
/// [target] 决定面板标题与可选原因列表. 若从其他面板跳转而来, 需在原面板关闭后调用.
/// 举报评论时若服务端返回该评论已删除, 则关闭面板并弹出提示, 随后触发 [onGone].
Future<void> showReportPanel(
  BuildContext context,
  WidgetRef ref,
  ReportTarget target, {
  VoidCallback? onGone,
}) async {
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
      gone: target.kind == ReportKind.comment ? isCommentGone : null,
      submit: (reason, note) =>
          repository.report(target, reason: reason, note: note),
    ),
  );
  if (!context.mounted) return;
  switch (sent) {
    case true:
      showToast(context, '已提交，处理结果会通过消息通知你');
    case false:
      onGone?.call();
      showToast(context, '${target.kind.noun}已删除');
    case null:
  }
}

/// 单选原因并填写可选补充说明的通用面板, 用于内容举报及店铺 "信息有误" 反馈.
///
/// 提交成功时以 true 关闭面板并交由调用方提示, 请求失败则保留面板并展示失败提示.
/// 若失败符合 [gone] 条件, 则以 false 关闭面板以便调用方提示对象已删除.
///
/// 默认不预选任何原因且选定后才启用提交按钮, 以避免误提交首项.
class ReasonPanel<T> extends ConsumerStatefulWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.label,
    required this.capability,
    this.gone,
    required this.submit,
  });

  final String title;
  final String? subtitle;
  final List<T> options;
  final String Function(T option) label;

  /// 服务端拒绝操作时用于触发权限拦截对话框的能力标识.
  final Capability capability;

  /// 判断失败异常是否表示目标对象已被删除.
  final bool Function(AppFailure failure)? gone;

  /// 提交表单的回调, 失败时应抛出 [AppFailure].
  final Future<void> Function(T option, String note) submit;

  @override
  ConsumerState<ReasonPanel<T>> createState() => _ReasonPanelState<T>();
}

class _ReasonPanelState<T> extends ConsumerState<ReasonPanel<T>> {
  /// 补充说明的字数上限, 与服务端一致, 按 code point 计.
  static const _maxNote = 200;

  final _note = TextEditingController();
  T? _selected;
  var _sending = false;

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
    setState(() => _sending = true);
    try {
      await widget.submit(option, _note.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      if (!mounted) return;
      if (widget.gone?.call(e) ?? false) {
        Navigator.of(context).pop(false);
        return;
      }
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
        '提交',
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
