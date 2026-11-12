import 'package:eat/features/shop/shop_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('舞台上是获赞最多的菜、昵称和三项统计；没认证时提示去认证', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({
          'id': 42,
          'displayName': '天凉被破王',
          'avatar': null,
          'fansCount': 3,
          'followingsCount': 5,
          'fansVisible': true,
          'followingsVisible': true,
          'isFollowingMe': false,
          'isFollowingHim': false,
          'blocked': false,
        }),
      ])
      ..on('GET /foods/my', [
        FakeAdapter.ok({
          ...pageJson([
            foodJson(id: 1, name: '虾仁云吞', likes: 30, stageColor: 'chili'),
            foodJson(id: 2, name: '紫菜汤', likes: 2),
          ]),
          'totalItems': 26,
        }),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.me,
    );

    expect(find.text('天凉被破王'), findsOneWidget);
    expect(find.bySemanticsLabel('上传的菜 26'), findsOneWidget);
    expect(find.bySemanticsLabel('粉丝 3'), findsOneWidget);
    expect(find.bySemanticsLabel('关注 5'), findsOneWidget);
    expect(find.textContaining('获赞'), findsNothing);
    expect(find.text('认证后可以发布和互动'), findsOneWidget);
    expect(find.text('虾仁云吞'), findsOneWidget);
    expect(
      env.adapter.sent('GET /user/userInfo').single.query,
      containsPair('userId', 42),
    );
    await expectAccessible(tester);
  });

  testWidgets('等级胶囊标着待接入，点了只提示，不请求等级接口', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'id': 42, 'displayName': '天凉被破王'}),
      ])
      ..on('GET /foods/my', [FakeAdapter.ok(pageJson([]))]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.me,
    );

    final badge = find.bySemanticsLabel('等级，待接入');
    expect(badge, findsOneWidget);
    await tester.tap(badge);
    await tester.pumpAndSettle();
    expect(find.text('该功能即将上线'), findsOneWidget);
    expect(locationOf(router), Paths.me);
    expect(env.adapter.sent('GET /user/growth'), isEmpty);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  group('收藏的店', () {
    TestEnv favoritesEnv(List<Object?> shops) {
      final env = TestEnv();
      env.adapter
        ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
        ..on('GET /user/userInfo', [
          FakeAdapter.ok({'displayName': '天凉被破王'}),
        ])
        ..on('GET /foods/my', [FakeAdapter.ok(pageJson([]))])
        ..on('GET /foods/favorites', [FakeAdapter.ok(pageJson([]))])
        ..on('GET /restaurant/favorites', [FakeAdapter.ok(pageJson(shops))]);
      return env;
    }

    Future<void> openShops(WidgetTester tester) async {
      await tester.tap(find.text('收藏'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('店'));
      await tester.pumpAndSettle();
    }

    testWidgets('切到「店」列出收藏的店，已关门的标明，点击进餐厅详情', (tester) async {
      final env = favoritesEnv([
        {...restaurantJson(), 'coverUrl': 'https://img.test/foods/1.jpg'},
        {
          ...restaurantJson(id: 8, name: '老地方麻辣烫'),
          'operatingStatus': 'CLOSED',
          'permanentlyClosed': true,
        },
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.me,
      );

      expect(env.adapter.sent('GET /restaurant/favorites'), isEmpty);
      await openShops(tester);
      expect(find.text('袁记云饺'), findsOneWidget);
      expect(find.text('老地方麻辣烫'), findsOneWidget);
      expect(find.textContaining('已关门'), findsOneWidget);
      await expectAccessible(tester);

      await tester.ensureVisible(find.text('袁记云饺'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('袁记云饺'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopPage), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('没收藏过店时提示去餐厅详情收藏', (tester) async {
      final env = favoritesEnv([]);
      await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.me,
      );

      await openShops(tester);
      expect(find.text('还没收藏过店'), findsOneWidget);
      await expectAccessible(tester);
    });
  });
}
