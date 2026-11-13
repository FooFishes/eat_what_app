import 'package:eat/domain/models/current_user.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  Map<String, Object?> detail({
    int? ratingCount = 32,
    int? rate = 86,
    String? myRating,
    bool isFavorite = false,
  }) => {
    ...restaurantJson(),
    'visibleFoodCount': 13,
    'ratingCount': ratingCount,
    'recommendationRate': rate,
    'ratingSummaryState': 'READY',
    'signatureFoods': [
      {'id': 1, 'name': '虾仁云吞', 'stageColor': 'chili', 'likesCount': 30},
      {'id': 2, 'name': '牛肉饺子', 'likesCount': 20},
      {'id': 4, 'name': '煎饺', 'likesCount': 9},
    ],
    'publicTastes': [
      {'tagId': 3, 'name': '皮薄', 'taggerCount': 5},
    ],
    'publicTastesState': 'READY',
    'personalState': 'READY',
    'myRating': myRating,
    'isFavorite': isFavorite,
  };

  final downward = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );

  TestEnv shopEnv({List<Object>? details}) {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /restaurant/detail/7', details ?? [FakeAdapter.ok(detail())])
      ..on('GET /foods/list', [
        FakeAdapter.ok(
          pageJson([
            foodJson(id: 1, name: '虾仁云吞', likes: 30),
            foodJson(id: 2, name: '牛肉饺子', likes: 20),
            foodJson(id: 3, name: '紫菜汤', likes: 2),
          ]),
        ),
        FakeAdapter.ok(pageJson([foodJson(id: 1, name: '虾仁云吞', likes: 30)])),
      ]);
    return env;
  }

  testWidgets('舞台写店名、菜数和推荐率；招牌和口味取自店铺详情，点口味词按标签请求菜单', (tester) async {
    final env = shopEnv();
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    expect(find.text('袁记云饺'), findsOneWidget);
    expect(find.text('13 道菜'), findsOneWidget);
    expect(find.text('86% 推荐'), findsOneWidget);
    expect(find.text('32 人评过'), findsOneWidget);
    expect(find.text('招牌'), findsOneWidget);
    expect(find.text('煎饺'), findsOneWidget);
    final sent = env.adapter.sent('GET /foods/list').single.query;
    expect(sent, containsPair('restaurantId', 7));
    expect(sent, containsPair('sort', 'POPULAR'));
    expect(sent.containsKey('systemTagIds'), isFalse);
    await expectAccessible(tester);

    await tester.scrollUntilVisible(find.text('皮薄'), 200, scrollable: downward);
    await tester.tap(find.text('皮薄'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('GET /foods/list').last.query,
      containsPair('systemTagIds', [3]),
    );
    expect(find.text('紫菜汤'), findsNothing, reason: '只看带「皮薄」的菜');
    await unmountApp(tester, container);
  });

  for (final (count, text) in [(3, '3 人评过'), (0, '还没人评价')]) {
    testWidgets('评价不满 5 人时舞台写「$text」，不写推荐率', (tester) async {
      final env = shopEnv(
        details: [FakeAdapter.ok(detail(ratingCount: count, rate: null))],
      );
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.shop(7),
      );

      expect(find.text(text), findsOneWidget);
      expect(find.textContaining('% 推荐'), findsNothing);
      await expectAccessible(tester);
      await unmountApp(tester, container);
    });
  }

  testWidgets('认证用户点一档就提交，再点同一档撤回', (tester) async {
    final env = shopEnv(
      details: [
        FakeAdapter.ok(detail()),
        FakeAdapter.ok(detail(myRating: 'RECOMMEND')),
        FakeAdapter.ok(detail()),
      ],
    );
    env.adapter
      ..on('PUT /restaurant/7/rating', [
        FakeAdapter.ok({'rating': 'RECOMMEND'}),
      ])
      ..on('DELETE /restaurant/7/rating', [
        FakeAdapter.ok({'rating': null}),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    await tester.scrollUntilVisible(
      find.text('不推荐'),
      200,
      scrollable: downward,
    );
    expect(find.text('点选即提交，之后可修改'), findsOneWidget);
    await tester.tap(find.text('推荐'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('PUT /restaurant/7/rating').single.body, {
      'rating': 'RECOMMEND',
    });
    expect(find.text('已选「推荐」，再点一次取消'), findsOneWidget);
    expect(
      env.adapter.sent('GET /restaurant/detail/7'),
      hasLength(2),
      reason: '评价后重新请求店铺详情，更新推荐率',
    );
    await expectAccessible(tester);

    await tester.tap(find.text('推荐'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE /restaurant/7/rating'), hasLength(1));
    expect(find.text('点选即提交，之后可修改'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('评价失败时退回原来的选择并提示', (tester) async {
    final env = shopEnv();
    env.adapter.on('PUT /restaurant/7/rating', [const FakeResponse.offline()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    await tester.scrollUntilVisible(
      find.text('不推荐'),
      200,
      scrollable: downward,
    );
    await tester.tap(find.text('一般'));
    await tester.pumpAndSettle();
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('点选即提交，之后可修改'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('收藏店铺：认证用户点了就收藏，再点取消', (tester) async {
    final env = shopEnv();
    env.adapter
      ..on('PUT /restaurant/7/favorite', [FakeAdapter.ok()])
      ..on('DELETE /restaurant/7/favorite', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    await tester.tap(find.bySemanticsLabel('收藏店铺'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('PUT /restaurant/7/favorite'), hasLength(1));
    expect(find.bySemanticsLabel('取消收藏店铺'), findsOneWidget);
    expect(find.text('已收藏，可在「我的」查看'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('取消收藏店铺'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE /restaurant/7/favorite'), hasLength(1));
    expect(find.bySemanticsLabel('收藏店铺'), findsOneWidget);
    expect(find.text('已取消收藏'), findsOneWidget);
    // 等轻提示消失, 它的定时器不留到测试结束.
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点收藏和评价都弹拦截对话框，不发请求', (tester) async {
    final env = shopEnv();
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.shop(7),
    );

    await tester.tap(find.bySemanticsLabel('收藏店铺'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能收藏'), findsOneWidget);
    await tester.tap(find.text('先逛逛'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('不推荐'),
      200,
      scrollable: downward,
    );
    await tester.tap(find.text('还不错'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能评价'), findsOneWidget);
    expect(env.adapter.sent('PUT /restaurant/7/favorite'), isEmpty);
    expect(env.adapter.sent('PUT /restaurant/7/rating'), isEmpty);
    await unmountApp(tester, container);
  });

  group('信息有误', () {
    Future<void> openPanel(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.text('信息有误'),
        200,
        scrollable: downward,
      );
      await tester.tap(find.text('信息有误'));
      await tester.pumpAndSettle();
    }

    testWidgets('选一项、写补充说明后提交，提示已提交；失败重试沿用同一个请求编号', (tester) async {
      final env = shopEnv();
      env.adapter.on('POST /feedback/catalog-errors', [
        const FakeResponse.offline(),
        FakeAdapter.ok({'id': 1, 'duplicate': false}),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.shop(7),
      );

      await openPanel(tester);
      expect(find.text('信息有误'), findsNWidgets(2));
      expect(find.text('袁记云饺  万达金街 1 层'), findsOneWidget);
      expect(find.text('提交'), findsOneWidget, reason: '没选原因时仍显示静态按钮文案');
      await expectAccessible(tester);

      await tester.tap(find.text('位置不对'));
      await tester.enterText(find.byType(EditableText), '  在二楼  ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('提交'));
      await tester.pumpAndSettle();
      expect(find.text('网络连接失败，请重试'), findsOneWidget);
      expect(find.text('信息有误'), findsNWidgets(2), reason: '失败时面板保留');

      await tester.tap(find.text('提交'));
      await tester.pumpAndSettle();
      final sent = env.adapter.sent('POST /feedback/catalog-errors').toList();
      expect(sent, hasLength(2));
      expect(sent.last.body, {
        'restaurantId': 7,
        'errorType': 'WRONG_LOCATION',
        'note': '在二楼',
      });
      expect(
        sent.last.headers['Idempotency-Key'],
        sent.first.headers['Idempotency-Key'],
      );
      expect(find.text('信息有误'), findsOneWidget);
      expect(find.text('已提交，核实后会通过消息通知你'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('封禁中也能提交', (tester) async {
      final env = shopEnv();
      env.adapter.on('POST /feedback/catalog-errors', [
        FakeAdapter.ok({'id': 1, 'duplicate': true}),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(
          user: CurrentUser(
            id: 42,
            nickname: '天凉被破王',
            hasPassword: false,
            verified: true,
            banned: true,
          ),
        ),
        location: Paths.shop(7),
      );

      await openPanel(tester);
      await tester.tap(find.text('已关门'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('提交'));
      await tester.pumpAndSettle();
      expect(env.adapter.sent('POST /feedback/catalog-errors').single.body, {
        'restaurantId': 7,
        'errorType': 'CLOSED',
      });
      expect(find.text('已提交，核实后会通过消息通知你'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });
  });

  testWidgets('已关门的店写「这家店已关门」，导航和加菜都不可用', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /restaurant/detail/7', [
        FakeAdapter.ok({
          ...restaurantJson(),
          'operatingStatus': 'CLOSED',
          'permanentlyClosed': true,
        }),
      ])
      ..on('GET /foods/list', [
        FakeAdapter.ok(pageJson([foodJson()])),
      ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    expect(find.text('这家店已关门'), findsOneWidget);
    await tester.tap(find.text('加一道菜'));
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.shop(7));
    await unmountApp(tester, container);
  });
}
