import 'package:eat/data/feedback/feedback_repository.dart';
import 'package:eat/domain/models/report.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  test('举报带上对象、原因和请求编号，补充说明去掉首尾空白', () async {
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
          idempotencyKey: 'key-1',
        );

    final sent = env.adapter.sent('POST /feedback/reports').single;
    expect(sent.body, {
      'targetType': 'COMMENT',
      'targetId': 5,
      'reason': 'NOT_REAL_PHOTO',
      'note': '图是网上的',
    });
    expect(sent.headers['Idempotency-Key'], 'key-1');
  });

  test('信息有误没写补充说明时不带 note', () async {
    final env = TestEnv();
    env.adapter.on('POST /feedback/catalog-errors', [
      FakeAdapter.ok({'id': 2, 'duplicate': true}),
    ]);
    final container = await env.container();

    await container
        .read(feedbackRepositoryProvider)
        .reportShopError(
          shopId: 7,
          type: ShopErrorType.duplicate,
          note: '   ',
          idempotencyKey: 'key-2',
        );

    final sent = env.adapter.sent('POST /feedback/catalog-errors').single;
    expect(sent.body, {'restaurantId': 7, 'errorType': 'DUPLICATE'});
    expect(sent.headers['Idempotency-Key'], 'key-2');
  });

  test('举报用户不能选「不是这道菜的实拍」', () {
    expect(
      const ReportTarget.user(9).reasons,
      isNot(contains(ReportReason.notRealPhoto)),
    );
    expect(const ReportTarget.dish(1).reasons, ReportReason.values);
  });
}
