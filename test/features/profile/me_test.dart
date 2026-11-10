import 'package:eat/core/format/time_format.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/features/shop/shop_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('舞台上是获赞最多的菜、昵称和统计；没认证时提示去认证', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({
          'displayName': '天凉被破王',
          'avatar': null,
          'earnedLikes': 128,
          'fansCount': 3,
          'followingsCount': 5,
          'fansVisible': true,
          'followingsVisible': true,
          'isFollowingMe': false,
          'isFollowingHim': false,
          'uploadedRestaurantsCount': 1,
          'uploadedFoodsCount': 2,
        }),
      ])
      ..on('GET /foods/my', [
        FakeAdapter.ok(
          pageJson([
            foodJson(id: 1, name: '虾仁云吞', likes: 30, stageColor: 'chili'),
            foodJson(id: 2, name: '紫菜汤', likes: 2),
          ]),
        ),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.me,
    );

    expect(find.text('天凉被破王'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('认证后可以发布和互动'), findsOneWidget);
    expect(find.text('虾仁云吞'), findsOneWidget);
    expect(
      env.adapter.sent('GET /user/userInfo').single.query,
      containsPair('userId', 42),
    );
    await expectAccessible(tester);
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

  group('封禁中', () {
    final now = DateTime.now();
    final until = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 20));
    CurrentUser banned({DateTime? until}) => CurrentUser(
      id: 42,
      nickname: '天凉被破王',
      hasPassword: false,
      verified: true,
      banned: true,
      banReason: '刷赞',
      banUntil: until,
    );

    TestEnv bannedEnv() {
      final env = TestEnv();
      env.adapter
        ..on('GET /user/userInfo', [
          FakeAdapter.ok({'displayName': '天凉被破王'}),
        ])
        ..on('GET /foods/by-user/42', [
          FakeAdapter.ok(pageJson([foodJson(id: 1, name: '虾仁云吞')])),
        ]);
      return env;
    }

    testWidgets('提示封禁期限和原因；上传改走公开接口，收藏不请求', (tester) async {
      final env = bannedEnv();
      await pumpApp(
        tester,
        env,
        session: SignedIn(user: banned(until: until)),
        location: Paths.me,
      );

      expect(
        find.text('账号封禁中，封禁至 ${TimeFormat.date(until, now)}，原因：刷赞'),
        findsOneWidget,
      );
      expect(find.text('虾仁云吞'), findsOneWidget);
      expect(env.adapter.sent('GET /foods/my'), isEmpty);

      await tester.tap(find.text('收藏'));
      await tester.pumpAndSettle();
      expect(find.text('封禁期间暂时不能查看收藏的菜。'), findsOneWidget);
      expect(env.adapter.sent('GET /foods/favorites'), isEmpty);
    });

    testWidgets('没有截止时间时是永久封禁；点足迹弹拦截对话框，不进页面', (tester) async {
      final env = bannedEnv();
      final (_, router) = await pumpApp(
        tester,
        env,
        session: SignedIn(user: banned()),
        location: Paths.me,
      );

      expect(find.text('账号封禁中，永久封禁，原因：刷赞'), findsOneWidget);

      await tester.tap(find.text('足迹'));
      await tester.pumpAndSettle();
      expect(find.text('账号封禁中，暂时不能查看足迹'), findsOneWidget);
      expect(find.text('永久封禁'), findsOneWidget);
      expect(locationOf(router), Paths.me);
      expect(env.adapter.sent('GET /history/browse'), isEmpty);
    });
  });
}
