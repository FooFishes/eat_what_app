import 'package:eat/data/feedback/feedback_repository.dart';
import 'package:eat/domain/models/feedback_case.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/feedback_case_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  test('举报带上对象和原因，补充说明去掉首尾空白，不带幂等键', () async {
    final env = TestEnv();
    env.adapter.on('POST /feedback/reports', [
      FakeAdapter.ok({'id': 1, 'duplicate': false}),
    ]);
    final container = await env.container();

    await container
        .read(feedbackRepositoryProvider)
        .report(
          const ReportTarget.comment(5),
          reason: ReportReason.notRealPhoto,
          note: '  图是网上的 ',
        );

    final sent = env.adapter.sent('POST /feedback/reports').single;
    expect(sent.body, {
      'targetType': 'COMMENT',
      'targetId': 5,
      'reason': 'NOT_REAL_PHOTO',
      'note': '图是网上的',
    });
    expect(sent.headers.containsKey('Idempotency-Key'), isFalse);
  });

  test('信息有误没写补充说明时不带 note', () async {
    final env = TestEnv();
    env.adapter.on('POST /feedback/catalog-errors', [
      FakeAdapter.ok({'id': 2, 'duplicate': true}),
    ]);
    final container = await env.container();

    await container
        .read(feedbackRepositoryProvider)
        .reportShopError(shopId: 7, type: ShopErrorType.duplicate, note: '   ');

    final sent = env.adapter.sent('POST /feedback/catalog-errors').single;
    expect(sent.body, {'restaurantId': 7, 'errorType': 'DUPLICATE'});
  });

  test('举报用户不能选「不是这道菜的实拍」', () {
    expect(
      const ReportTarget.user(9).reasons,
      isNot(contains(ReportReason.notRealPhoto)),
    );
    expect(const ReportTarget.dish(1).reasons, ReportReason.values);
  });

  test('我的反馈分页列出记录，转成领域模型，认不出类型的去掉', () async {
    final env = TestEnv();
    env.adapter.on('GET /feedback/mine', [
      FakeAdapter.ok({
        'currentPage': 1,
        'hasNext': true,
        'totalItems': 30,
        'items': [
          {
            'id': 9,
            'kind': 'REPORT',
            'status': 'CLOSED',
            'target': {'type': 'COMMENT', 'id': 3},
            'reason': 'ADVERTISING',
            'text': ' 一直在发链接 ',
            'screenshots': [
              {'slot': 0, 'url': 'https://img/1.jpg'},
              {'slot': 1, 'url': ''},
            ],
            'outcome': 'REJECTED',
            'reply': '',
            'createdAt': 1700000000000,
            'closedAt': 1700100000000,
          },
          {'id': 10, 'kind': 'UNKNOWN', 'createdAt': 1700000000000},
        ],
      }),
    ]);
    final container = await env.container();

    final page = await container.read(feedbackRepositoryProvider).mine();

    final sent = env.adapter.sent('GET /feedback/mine').single;
    expect(sent.query, {'page': 1, 'pageSize': 20});
    expect(page.hasNext, isTrue);
    final item = page.items.single;
    expect(item.kind, CaseKind.report);
    expect(item.closed, isTrue);
    expect(item.outcome, CaseOutcome.rejected);
    expect(
      (item.subject?.kind, item.subject?.id),
      (CaseSubjectKind.comment, 3),
    );
    expect(item.text, '一直在发链接');
    expect(item.screenshots, ['https://img/1.jpg']);
    expect(item.closedAt, isNotNull);
    expect(FeedbackCaseRules.title(item), '举报评论：广告');
    expect(FeedbackCaseRules.statusLabel(item), '经核实未违规');
  });

  test('处理状态：未处理写待处理，意见反馈按结果区分采纳', () {
    FeedbackCase make(CaseKind kind, {bool closed = true, CaseOutcome? o}) =>
        FeedbackCase(
          id: 1,
          kind: kind,
          closed: closed,
          outcome: o,
          reasonCode: 'CLOSED',
          createdAt: DateTime(2026),
        );
    expect(
      FeedbackCaseRules.statusLabel(make(CaseKind.feedback, closed: false)),
      '待处理',
    );
    expect(
      FeedbackCaseRules.statusLabel(
        make(CaseKind.feedback, o: CaseOutcome.accepted),
      ),
      '已采纳',
    );
    expect(
      FeedbackCaseRules.statusLabel(
        make(CaseKind.catalogError, o: CaseOutcome.accepted),
      ),
      '已修正',
    );
    expect(FeedbackCaseRules.title(make(CaseKind.catalogError)), '店铺信息有误：已关门');
    expect(FeedbackCaseRules.title(make(CaseKind.feedback)), '意见反馈');
  });
}
