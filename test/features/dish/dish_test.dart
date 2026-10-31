import 'package:eat/features/verify/verify_page.dart';
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
      ..on('GET /foods/detail/1', [
        FakeAdapter.ok(
          foodJson(
            likes: 12,
            systemTags: [
              {'id': 3, 'name': '皮薄', 'count': 8, 'taggedByMe': false},
              {'id': 4, 'name': '量大', 'count': 2, 'taggedByMe': true},
            ],
          ),
        ),
      ])
      ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())]);
  });

  testWidgets('舞台上是分类、菜名和价格，抽屉里是店卡、赞、大家怎么说和上传者', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    expect(find.text('主食'), findsOneWidget);
    expect(find.text('鲜虾蟹\n籽云吞'), findsOneWidget);
    expect(find.text('¥18'), findsOneWidget);
    expect(find.text('袁记云饺'), findsOneWidget);
    expect(find.textContaining('万达金街 1 层'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('皮薄'), findsOneWidget);
    expect(find.text('小林'), findsOneWidget);
    expect(find.text('汤很鲜，虾仁很多'), findsOneWidget);
    await expectAccessible(tester);
    await tester.scrollUntilVisible(
      find.text('吃过的人说'),
      200,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    expect(find.text('吃过的人说'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点赞弹拦截面板，不发请求；「去认证」进认证页', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.dish(1),
    );

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能点赞'), findsOneWidget);
    expect(env.adapter.sent('POST /foods/1/like'), isEmpty);

    await tester.tap(find.text('去认证'));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyPage), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('认证后点赞：数字先加一，请求失败退回并提示', (tester) async {
    env.adapter.on('POST /foods/1/like', [
      FakeAdapter.ok(),
      const FakeResponse.offline(),
    ]);
    env.adapter.on('POST /foods/1/unlike', [const FakeResponse.offline()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
    expect(env.adapter.sent('POST /foods/1/like'), hasLength(1));

    await tester.tap(find.text('13'));
    await tester.pump();
    expect(find.text('12'), findsOneWidget, reason: '先按取消了赞显示');
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('点「大家怎么说」里没打过的词就打上，打过的再点撤回', (tester) async {
    env.adapter
      ..on('POST /foods/1/tags/system', [FakeAdapter.ok()])
      ..on('DELETE /foods/1/tags/4', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    await tester.tap(find.text('皮薄'));
    await tester.pumpAndSettle();
    final added = env.adapter.sent('POST /foods/1/tags/system').single;
    expect(added.body, {
      'tagIds': [3],
    });
    expect(find.text('9'), findsOneWidget);

    await tester.tap(find.text('量大'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE /foods/1/tags/4'), hasLength(1));
    expect(find.text('量大'), findsOneWidget, reason: '撤回后还有 1 个人打过');
    await unmountApp(tester, container);
  });

  testWidgets('分享面板：分享给朋友、复制链接；看别人的菜时有「举报」', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    await tester.tap(find.bySemanticsLabel('分享'));
    await tester.pumpAndSettle();
    expect(find.text('分享给朋友'), findsOneWidget);
    expect(find.text('复制链接'), findsOneWidget);
    expect(find.text('举报'), findsOneWidget);
    await unmountApp(tester, container);
  });
}
