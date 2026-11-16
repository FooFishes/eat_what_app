import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/report.dart';

/// 提交记录的处理结果. [resolved] 只用于意见反馈.
enum CaseOutcome {
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  resolved('RESOLVED');

  const new(this.api);

  final String api;

  static CaseOutcome? fromApi(String? value) =>
      values.where((o) => o.api == value).firstOrNull;
}

/// 本人提交过的一条意见反馈, 店铺信息有误或举报, 以及它的处理结果.
///
/// [reasonCode] 是信息有误的错误类型或举报原因的接口取值, 意见反馈为 null.
/// [text] 是意见反馈的正文, 或信息有误和举报的补充说明, 没写时为空串.
/// [reply] 是管理员的公开回复, 没有时为空串.
class const FeedbackCase({
  required final int id,
  required final CaseKind kind,
  required final bool closed,
  final CaseSubject? subject,
  final String? reasonCode,
  final String text = '',
  final List<String> screenshots = const [],
  final CaseOutcome? outcome,
  final String reply = '',
  required final DateTime createdAt,
  final DateTime? closedAt,
});
