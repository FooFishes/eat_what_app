import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /restaurant/browse', [FakeAdapter.ok(pageJson([]))]);
  });

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(find.byType(EditableText).at(1), '万达金街 1 层');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('建好了，去加菜'));
    await tester.pumpAndSettle();
  }

  testWidgets('新店进入审核：提示已提交审核并返回，不去加菜；重试用同一个 key', (tester) async {
    env.adapter.on('POST /restaurant/add', [
      const FakeResponse.offline(),
      FakeAdapter.ok({'id': 9, 'moderationStatus': 'PENDING'}),
    ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );
    router.push(Paths.publishShop(name: '麻辣烫'));
    await tester.pumpAndSettle();

    await fillAndSubmit(tester);
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('建好了，去加菜'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('已提交审核，通过后公开'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('新建一家店'), findsNothing);
    expect(env.adapter.sent('GET /restaurant/detail/9'), isEmpty);
    final keys = env.adapter
        .sent('POST /restaurant/add')
        .map((r) => r.headers['Idempotency-Key'])
        .toList();
    expect(keys, hasLength(2));
    expect(keys.first, isNotNull);
    expect(keys.last, keys.first);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('未启用审核时不返回审核状态：按已公开处理，去新店的加菜页', (tester) async {
    env.adapter.on('POST /restaurant/add', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );
    router.push(Paths.publishShop(name: '麻辣烫'));
    await tester.pumpAndSettle();

    await fillAndSubmit(tester);

    expect(find.text('新建一家店'), findsNothing);
    expect(env.adapter.sent('GET /restaurant/detail/9'), isNotEmpty);
    await unmountApp(tester, container);
  });
}
