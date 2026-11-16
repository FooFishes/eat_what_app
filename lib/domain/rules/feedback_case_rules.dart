import 'package:eat/domain/models/feedback_case.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/report.dart';

/// "我的反馈" 列表和详情中的展示文案.
abstract final class FeedbackCaseRules {
  static String kindLabel(CaseKind kind) => switch (kind) {
    CaseKind.feedback => '意见反馈',
    CaseKind.catalogError => '店铺信息有误',
    CaseKind.report => '举报',
  };

  /// 信息有误的错误类型或举报原因. 意见反馈或取值无法识别时返回 null.
  static String? reasonLabel(FeedbackCase c) => switch (c.kind) {
    CaseKind.feedback => null,
    CaseKind.catalogError =>
      ShopErrorType.values
          .where((t) => t.api == c.reasonCode)
          .firstOrNull
          ?.label,
    CaseKind.report =>
      ReportReason.values
          .where((r) => r.api == c.reasonCode)
          .firstOrNull
          ?.label,
  };

  /// 列表行标题: 意见反馈取正文, 信息有误和举报写类型和原因, 如 "举报评论：广告".
  static String title(FeedbackCase c) {
    if (c.kind == CaseKind.feedback) {
      final text = c.text.trim();
      return text.isEmpty ? kindLabel(c.kind) : text;
    }
    final kind = c.kind == CaseKind.report
        ? '举报${subjectNoun(c.subject) ?? ''}'
        : kindLabel(c.kind);
    final reason = reasonLabel(c);
    return reason == null ? kind : '$kind：$reason';
  }

  /// 处理状态的短标签, 未处理时为 "待处理".
  static String statusLabel(FeedbackCase c) {
    if (!c.closed) return '待处理';
    return switch ((c.kind, c.outcome)) {
      (CaseKind.feedback, CaseOutcome.accepted) => '已采纳',
      (CaseKind.feedback, CaseOutcome.rejected) => '未采纳',
      (CaseKind.catalogError, CaseOutcome.accepted) => '已修正',
      (CaseKind.catalogError, CaseOutcome.rejected) => '经核实无误',
      (CaseKind.report, CaseOutcome.rejected) => '经核实未违规',
      _ => '已处理',
    };
  }

  /// 详情页对处理结果的一句话说明.
  static String outcomeSentence(FeedbackCase c) {
    if (!c.closed) return '还在处理中，处理后会通过消息通知你。';
    return switch ((c.kind, c.outcome)) {
      (CaseKind.feedback, CaseOutcome.accepted) => '你的反馈已被采纳。',
      (CaseKind.feedback, CaseOutcome.rejected) => '你的反馈未被采纳。',
      (CaseKind.catalogError, CaseOutcome.accepted) => '店铺信息已修正。',
      (CaseKind.catalogError, CaseOutcome.rejected) => '店铺信息经核实无误。',
      (CaseKind.report, CaseOutcome.accepted) => '你举报的内容已处理。',
      (CaseKind.report, CaseOutcome.rejected) => '你举报的内容经核实未违规。',
      _ => '已处理。',
    };
  }

  /// 关联对象的名词, 如 "菜品" "评论". 没有关联对象时返回 null.
  static String? subjectNoun(CaseSubject? subject) => switch (subject?.kind) {
    CaseSubjectKind.dish => '菜品',
    CaseSubjectKind.shop => '店铺',
    CaseSubjectKind.comment => '评论',
    CaseSubjectKind.user => '用户',
    null => null,
  };
}
