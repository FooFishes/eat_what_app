import 'package:eat/core/platform/share.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/features/dish/dish_history_page.dart';
import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/features/dish/tag_panel.dart';
import 'package:eat/features/profile/user_page.dart';
import 'package:eat/features/verify/verify_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/analytics.dart';
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
        FakeAdapter.ok(foodJson(likes: 12, tags: ['辣', '麻'], signature: true)),
      ])
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'id': 9, 'displayName': '小林'}),
      ])
      ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())]);
  });

  Finder scrollable() => find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );

  testWidgets('舞台上是招牌、分类、菜名和价格，抽屉里是数字条（评分、赞、口味）、店、评论和上传者', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    expect(find.text('招牌 · 主食'), findsOneWidget);
    expect(find.text('鲜虾蟹\n籽云吞'), findsOneWidget);
    expect(find.text('¥ 18'), findsOneWidget);
    expect(find.text('袁记云饺'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('辣 · 麻'), findsOneWidget);
    expect(find.bySemanticsLabel('评分，还没人评分，点了打分'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('小林'),
      200,
      scrollable: scrollable(),
    );
    expect(find.text('小林'), findsOneWidget);
    expect(find.text('汤很鲜，虾仁很多'), findsOneWidget);
    expect(
      env.adapter.sent('GET /user/userInfo').single.query['userId'],
      9,
      reason: '菜品响应只有上传者的 id，昵称要按 id 查',
    );
    expect(env.adapter.sent('GET /foods/1/tags'), isEmpty);
    expect(env.adapter.sent('GET /topics/by-food/1'), isEmpty);
    await expectAccessible(tester);
    await tester.scrollUntilVisible(
      find.text('吃过的人说'),
      200,
      scrollable: scrollable(),
    );
    expect(find.text('吃过的人说'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('上传者点了进主页；账号删了写「已注销用户」，点了没有反应', (tester) async {
    Future<bool> tapUploader(String name) async {
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.dish(1),
      );
      await tester.scrollUntilVisible(
        find.text(name),
        200,
        scrollable: scrollable(),
      );
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      final opened = find.byType(UserPage).evaluate().isNotEmpty;
      await unmountApp(tester, container);
      return opened;
    }

    expect(await tapUploader('小林'), isTrue);

    env.adapter.on('GET /foods/detail/1', [
      FakeAdapter.ok(foodJson(uploaderId: null)),
    ]);
    expect(await tapUploader('已注销用户'), isFalse);
  });

  testWidgets('游客看菜不查上传者资料，上传者写「同学」', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const Guest(),
      location: Paths.dish(1),
    );

    await tester.scrollUntilVisible(
      find.text('同学'),
      200,
      scrollable: scrollable(),
    );
    expect(find.text('同学'), findsOneWidget);
    expect(env.adapter.sent('GET /user/userInfo'), isEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点赞弹拦截对话框，不发请求；「去认证」进认证页', (tester) async {
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

  testWidgets('评分：写平均分和人数；打分立即提交，再点一次撤销', (tester) async {
    env.adapter
      ..on('GET /foods/detail/1', [
        FakeAdapter.ok({
          ...foodJson(),
          'rating': {'score': 4.3, 'count': 12},
        }),
      ])
      ..on('PUT /foods/1/rating', [
        FakeAdapter.ok({
          'myRating': 4,
          'rating': {'score': 4.3, 'count': 13},
        }),
      ])
      ..on('DELETE /foods/1/rating', [
        FakeAdapter.ok({
          'myRating': null,
          'rating': {'score': 4.3, 'count': 12},
        }),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    expect(find.text('4.3'), findsOneWidget);
    expect(find.text('评分 · 12 人'), findsOneWidget);
    await tester.tap(find.text('评分 · 12 人'));
    await tester.pumpAndSettle();
    expect(find.text('给这道菜打分'), findsOneWidget);
    expect(find.text('点选即提交，之后可修改'), findsOneWidget);
    expect(find.text('4.3 分 · 12 人评过'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.bySemanticsLabel('4 分'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('PUT /foods/1/rating').single.body, {'score': 4});
    expect(find.text('已选「4 分」，再点一次取消'), findsOneWidget);
    expect(find.text('好吃'), findsOneWidget, reason: '星星下面写这个分数的说法');
    expect(find.text('4.3 分 · 13 人评过'), findsOneWidget);
    expect(find.text('评分 · 13 人'), findsOneWidget, reason: '卡片下面的数字条跟着更新');

    await tester.tap(find.bySemanticsLabel('4 分'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE /foods/1/rating'), hasLength(1));
    expect(find.text('点选即提交，之后可修改'), findsOneWidget);
    expect(find.text('4.3 分 · 12 人评过'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('给这道菜打分'), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('评分不满 3 人不写平均分；打过分时写自己的分，面板里选中原来的分数', (tester) async {
    env.adapter.on('GET /foods/detail/1', [
      FakeAdapter.ok({
        ...foodJson(),
        'rating': {'score': 5.0, 'count': 2},
        'myRating': 5,
      }),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    expect(find.text('5.0'), findsNothing);
    expect(find.bySemanticsLabel('评分，2 人评过，你打了 5 分'), findsOneWidget);
    await tester.tap(find.text('评分 · 2 人'));
    await tester.pumpAndSettle();
    expect(find.text('已选「5 分」，再点一次取消'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点「评分」弹拦截，不打开面板', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.dish(1),
    );

    await tester.tap(find.text('评分'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能评分'), findsOneWidget);
    expect(find.text('给这道菜打分'), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('口味只读：点了没有反应，没有「加标签」和待接入', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    expect(find.text('辣 · 麻'), findsOneWidget);
    expect(find.text('加标签'), findsNothing);
    expect(find.text('待接入'), findsNothing);
    await tester.tap(find.text('辣 · 麻'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('该功能即将上线'), findsNothing);
    expect(
      env.adapter.requests.where((r) => r.path.contains('/tags')),
      isEmpty,
    );
    await unmountApp(tester, container);
  });

  testWidgets('没有口味时写「还没标口味」', (tester) async {
    env.adapter.on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    expect(find.text('还没标口味'), findsOneWidget);
    expect(find.text('主食'), findsOneWidget, reason: '不是招牌菜时只写分类');
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点顶栏的「编辑」弹拦截；页底的「修改记录」谁都能看', (tester) async {
    env.adapter.on('GET /foods/1/history', [FakeAdapter.ok(pageJson([]))]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.dish(1),
    );

    await tester.tap(find.bySemanticsLabel('编辑'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能编辑'), findsOneWidget);
    expect(locationOf(router), Paths.dish(1));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('修改记录'),
      200,
      scrollable: scrollable(),
    );
    await tester.tap(find.text('修改记录'));
    await tester.pumpAndSettle();
    expect(find.byType(DishHistoryPage), findsOneWidget);
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

  testWidgets('分享成功后记一次统计；菜品页不放「导航去店里」', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
      overrides: [
        recordAnalytics,
        linkSharerProvider.overrideWithValue(FakeLinkSharer()),
      ],
    );

    expect(find.text('导航去店里'), findsNothing, reason: '导航只在餐厅详情里');
    await tester.tap(find.bySemanticsLabel('分享'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分享给朋友'));
    await tester.pumpAndSettle();

    final recorded = recordedIn(container);
    expect(recorded.propertiesOf<ShareEvent>(), [
      {'event': 'share', 'targetType': 'FOOD', 'targetId': 1},
    ]);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('菜不存在时显示「找不到这道菜」，没有重试，能返回', (tester) async {
    env.adapter.on('GET /foods/detail/2', [FakeAdapter.fail(40008)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(2),
    );

    expect(find.text('这道菜已删除'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    expect(find.text('加载失败'), findsNothing);
    expect(find.bySemanticsLabel('返回'), findsOneWidget);
    expect(env.adapter.sent('GET /foods/detail/2'), hasLength(1));
    await expectAccessible(tester);
    await unmountApp(tester, container);
  });

  testWidgets('加标签面板一次最多写 20 个我的标签，超出时提示且不提交', (tester) async {
    env.adapter.on('POST /foods/1/tags/custom', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    // 详情页没有入口, 面板本身保留, 直接打开.
    showTagPanel(tester.element(find.byType(DishPage)), dishId: 1).ignore();
    await tester.pumpAndSettle();
    await tester.tap(find.text('自己写'));
    await tester.pumpAndSettle();
    for (var i = 1; i <= 21; i++) {
      await tester.enterText(find.byType(EditableText), '标签$i');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }
    expect(find.text('一次最多添加 20 个标签'), findsOneWidget);
    expect(find.text('标签20'), findsOneWidget);

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /foods/1/tags/custom'), isEmpty);
    expect(env.adapter.sent('GET /foods/tags/system'), isEmpty);
    await unmountApp(tester, container);
  });
}
