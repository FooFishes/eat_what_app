import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
      ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())]);
  });

  Future<void> openReport(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('分享'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('举报'));
    await tester.pumpAndSettle();
  }

  testWidgets('从别人的菜的分享面板举报：选原因、补充说明，提交后提示', (tester) async {
    env.adapter.on('POST /feedback/reports', [
      FakeAdapter.ok({'id': 3, 'duplicate': false}),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    await openReport(tester);
    expect(find.text('分享给朋友'), findsNothing, reason: '先关闭分享面板');
    expect(find.text('举报这道菜'), findsOneWidget);
    expect(find.text('不是这道菜的实拍'), findsOneWidget);
    expect(find.text('选一个原因'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('广告'));
    await tester.enterText(find.byType(EditableText), '店家的二维码');
    await tester.pumpAndSettle();
    expect(find.text('6 / 200'), findsOneWidget);
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();

    final sent = env.adapter.sent('POST /feedback/reports').single;
    expect(sent.body, {
      'targetType': 'FOOD',
      'targetId': 1,
      'reason': 'ADVERTISING',
      'note': '店家的二维码',
    });
    expect(
      sent.headers['Idempotency-Key'],
      matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-')),
    );
    expect(find.text('举报这道菜'), findsNothing);
    expect(find.text('已提交，处理结果会通过消息通知你'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('换了原因再提交时用新的请求编号', (tester) async {
    env.adapter.on('POST /feedback/reports', [
      const FakeResponse.offline(),
      FakeAdapter.ok({'id': 3, 'duplicate': false}),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    await openReport(tester);
    await tester.tap(find.text('广告'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('其他'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();

    final sent = env.adapter.sent('POST /feedback/reports').toList();
    expect(sent.last.body, containsPair('reason', 'OTHER'));
    expect(
      sent.last.headers['Idempotency-Key'],
      isNot(sent.first.headers['Idempotency-Key']),
    );
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('自己的菜分享面板里没有举报', (tester) async {
    env.adapter.on('GET /foods/detail/1', [
      FakeAdapter.ok(foodJson(uploaderId: verifiedUser.id)),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    await tester.tap(find.bySemanticsLabel('分享'));
    await tester.pumpAndSettle();
    expect(find.text('复制链接'), findsOneWidget);
    expect(find.text('举报'), findsNothing);
    await unmountApp(tester, container);
  });
}
