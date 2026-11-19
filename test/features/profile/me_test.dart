import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/features/shop/shop_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('舞台上是获赞最多的菜、昵称、等级和四项统计；没认证时提示去认证', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({
          'id': 42,
          'displayName': '天凉被破王',
          'avatar': null,
          'level': 2,
          'earnedLikes': 40,
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
    expect(find.bySemanticsLabel('获赞 40'), findsOneWidget);
    expect(find.bySemanticsLabel('等级 2'), findsOneWidget);
    expect(find.text('认证后可以发布和互动'), findsOneWidget);
    expect(find.text('虾仁云吞'), findsOneWidget);
    expect(
      env.adapter.sent('GET /user/userInfo').single.query,
      containsPair('userId', 42),
    );
    await expectAccessible(tester);
  });

  testWidgets('资料没有返回等级时不显示等级胶囊', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'id': 42, 'displayName': '天凉被破王'}),
      ])
      ..on('GET /foods/my', [FakeAdapter.ok(pageJson([]))]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.me,
    );

    expect(find.bySemanticsLabel(RegExp('^等级')), findsNothing);
    expect(find.textContaining('Lv.'), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('往上翻到分栏时分栏吸顶，顶栏左边出现头像和昵称', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'id': 42, 'displayName': '天凉被破王'}),
      ])
      ..on('GET /foods/my', [
        FakeAdapter.ok(
          pageJson([for (var i = 1; i <= 12; i++) foodJson(id: i)]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.me,
    );

    expect(find.byType(EatTabs), findsOneWidget);
    expect(find.byType(EatAvatar), findsOneWidget, reason: '只有舞台上的头像');
    await tester.drag(find.byType(EatTabs), const Offset(0, -900));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    // 抽屉里的分栏已经滚出屏幕, 屏幕上的是接在顶栏下面的吸顶副本.
    expect(find.byType(EatTabs), findsOneWidget);
    final barTabs = tester.getRect(find.byType(EatTabs));
    expect(barTabs.top, lessThan(150));
    final avatars = find
        .byType(EatAvatar)
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget)));
    expect(
      avatars.where((r) => r.bottom <= barTabs.top && r.left < 40),
      hasLength(1),
      reason: '顶栏左边的头像',
    );
    expect(find.text(verifiedUser.nickname), findsWidgets);
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
      // 切换后列表的请求要等下一帧才发出, 先多推一帧, 否则页面没有动画时 pumpAndSettle 会在请求发出前就返回.
      await tester.pump();
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

  Future<TestEnv> likesEnv(
    WidgetTester tester,
    List<Map<String, Object?>> dishes,
  ) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '天凉被破王'}),
      ])
      ..on('GET /foods/my', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /foods/likes', [FakeAdapter.ok(pageJson(dishes))]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.me,
    );
    expect(env.adapter.sent('GET /foods/likes'), isEmpty);
    await tester.tap(find.text('赞过'));
    // 切换后列表的请求要等下一帧才发出, 先多推一帧, 否则页面没有动画时 pumpAndSettle 会在请求发出前就返回.
    await tester.pump();
    await tester.pumpAndSettle();
    expect(env.adapter.sent('GET /foods/likes'), hasLength(1));
    return env;
  }

  testWidgets('「赞过」列出赞过的菜', (tester) async {
    await likesEnv(tester, [foodJson(id: 3, name: '酸汤肥牛')]);
    expect(find.text('酸汤肥牛'), findsOneWidget);
    await expectAccessible(tester);
  });

  testWidgets('没赞过菜时说明在哪里赞', (tester) async {
    await likesEnv(tester, []);
    expect(find.text('还没赞过菜'), findsOneWidget);
    await expectAccessible(tester);
  });
}
