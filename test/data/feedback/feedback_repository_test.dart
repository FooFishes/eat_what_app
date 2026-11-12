import 'package:eat/data/feedback/feedback_repository.dart';
import 'package:eat/domain/models/report.dart';
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

  test('取提交记录关于的对象：菜和店认得出，没有对象时为空', () async {
    final env = TestEnv();
    env.adapter
      ..on('GET /feedback/mine/5', [
        FakeAdapter.ok({
          'id': 5,
          'kind': 'CATALOG_ERROR',
          'target': {'type': 'RESTAURANT', 'id': 7},
        }),
      ])
      ..on('GET /feedback/mine/6', [
        FakeAdapter.ok({'id': 6, 'kind': 'FEEDBACK', 'target': null}),
      ]);
    final container = await env.container();
    final repository = container.read(feedbackRepositoryProvider);

    final shop = await repository.caseSubject(5);
    expect((shop?.kind, shop?.id), (CaseSubjectKind.shop, 7));
    expect(await repository.caseSubject(6), isNull);
  });

  test('举报用户不能选「不是这道菜的实拍」', () {
    expect(
      const ReportTarget.user(9).reasons,
      isNot(contains(ReportReason.notRealPhoto)),
    );
    expect(const ReportTarget.dish(1).reasons, ReportReason.values);
  });
}
