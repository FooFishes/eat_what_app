import 'package:eat/features/settings/my_feedback_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

Map<String, Object?> _case(int id) => {
  'id': id,
  'kind': 'CATALOG_ERROR',
  'status': 'CLOSED',
  'target': {'type': 'RESTAURANT', 'id': 7},
  'reason': 'WRONG_NAME',
  'text': '招牌换了',
  'screenshots': <Object>[],
  'outcome': 'ACCEPTED',
  'reply': '已改成新店名',
  'createdAt': 1700000000000,
  'closedAt': 1700100000000,
};

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  testWidgets('我的反馈列出提交记录，点进去看处理结果和回复，能跳到相关的店', (tester) async {
    env.adapter
      ..on('GET /feedback/mine', [
        FakeAdapter.ok({
          'currentPage': 1,
          'hasNext': false,
          'items': [
            _case(5),
            {
              'id': 6,
              'kind': 'FEEDBACK',
              'status': 'OPEN',
              'target': null,
              'text': '希望加个夜宵专题',
              'screenshots': <Object>[],
              'reply': '',
              'createdAt': 1700000000000,
            },
          ],
        }),
      ])
      ..on('GET /feedback/mine/5', [FakeAdapter.ok(_case(5))]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.myFeedback,
    );

    expect(find.text('店铺信息有误：店名不对'), findsOneWidget);
    expect(find.text('希望加个夜宵专题'), findsOneWidget);
    expect(find.textContaining('待处理'), findsOneWidget);
    expect(find.textContaining('已修正'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('店铺信息有误：店名不对'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackCasePage), findsOneWidget);
    expect(router.state.uri.toString(), Paths.myFeedbackCase(5));
    expect(find.text('店铺信息已修正。'), findsOneWidget);
    expect(find.text('已改成新店名'), findsOneWidget);
    expect(find.text('查看这家店'), findsOneWidget);
    await expectAccessible(tester);
    await unmountApp(tester, container);
  });

  testWidgets('意见反馈的详情写分类', (tester) async {
    env.adapter.on('GET /feedback/mine/6', [
      FakeAdapter.ok({
        'id': 6,
        'kind': 'FEEDBACK',
        'category': 'PROBLEM',
        'status': 'OPEN',
        'target': null,
        'text': '收藏后列表没刷新',
        'screenshots': <Object>[],
        'reply': '',
        'createdAt': 1700000000000,
      }),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.myFeedbackCase(6),
    );

    expect(find.text('分类'), findsOneWidget);
    expect(find.text('遇到问题'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('没有提交过时显示空状态，加载失败时可以重试', (tester) async {
    env.adapter.on('GET /feedback/mine', [
      const FakeResponse.offline(),
      FakeAdapter.ok({'currentPage': 1, 'hasNext': false, 'items': []}),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.myFeedback,
    );

    expect(find.text('加载失败'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('还没有提交过反馈'), findsOneWidget);
    await unmountApp(tester, container);
  });
}
