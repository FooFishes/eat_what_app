import 'package:clock/clock.dart';
import 'package:eat/core/platform/external_maps.dart';
import 'package:eat/core/platform/share.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/features/shop/shop_edit_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/analytics.dart';
import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  Map<String, Object?> detail({
    int dineIn = 32,
    double? dineInRate = 0.856,
    int delivery = 0,
    double? deliveryRate,
    String? myDineIn,
    String? myDelivery,
    bool isFavorite = false,
  }) => {
    ...restaurantJson(),
    'categories': ['粉面'],
    'tags': ['辣', '酸'],
    'dineIn': {'rate': dineInRate, 'count': dineIn},
    'delivery': {'rate': deliveryRate, 'count': delivery},
    'myRatings': {'dineIn': myDineIn, 'delivery': myDelivery},
    'isFavorite': isFavorite,
  };

  final downward = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );

  /// 招牌菜和菜单都请求 `/foods/list`, 先后顺序不固定, 因此两者用同一份响应. 这家店共 13 道菜.
  TestEnv shopEnv({List<Object>? details}) {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /restaurant/detail/7', details ?? [FakeAdapter.ok(detail())])
      ..on('GET /foods/list', [
        FakeAdapter.ok({
          ...pageJson([
            foodJson(id: 1, name: '虾仁云吞', likes: 30),
            foodJson(id: 2, name: '牛肉饺子', likes: 20),
          ]),
          'totalItems': 13,
        }),
      ]);
    return env;
  }

  /// 滚到 [text] 能点到为止. 抽屉里的内容在屏幕外也会提前建好, 只等它出现会停在屏幕下沿外面.
  Future<void> scrollTo(WidgetTester tester, String text) =>
      tester.scrollUntilVisible(
        find.text(text).hitTestable(),
        200,
        scrollable: downward,
      );

  testWidgets('选了地图导航去店里、复制了链接后各记一次统计，关掉选择面板不记', (tester) async {
    final env = shopEnv();
    final maps = FakeExternalMaps(
      apps: [
        MapApp('高德地图', Uri.parse('amap://route')),
        MapApp('百度地图', Uri.parse('baidumap://route')),
      ],
    );
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
      overrides: [
        recordAnalytics,
        externalMapsProvider.overrideWithValue(maps),
        linkSharerProvider.overrideWithValue(FakeLinkSharer()),
      ],
    );
    final recorded = recordedIn(container);

    await tester.tap(find.text('导航去店里'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(recorded.propertiesOf<NavigateShopEvent>(), isEmpty);

    await tester.tap(find.text('导航去店里'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('百度地图'));
    await tester.pumpAndSettle();
    expect(maps.opened.single.name, '百度地图');
    expect(recorded.propertiesOf<NavigateShopEvent>(), [
      {'event': 'navigate_shop', 'restaurantId': 7},
    ]);

    await tester.tap(find.bySemanticsLabel('分享'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制链接'));
    await tester.pumpAndSettle();
    expect(recorded.propertiesOf<ShareEvent>(), [
      {'event': 'share', 'targetType': 'RESTAURANT', 'targetId': 7},
    ]);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('舞台写品类口味、店名和地址，盘子是招牌菜；数字条写堂食推荐率、菜数和商圈；菜单按分类分组', (tester) async {
    final env = shopEnv();
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    expect(find.text('袁记云饺'), findsOneWidget);
    expect(find.text('粉面  辣、酸'), findsOneWidget);
    expect(find.text('万达金街 1 层'), findsOneWidget);
    expect(find.text('万达金街'), findsOneWidget, reason: '商圈写在距离下面');
    expect(find.bySemanticsLabel('13 道菜'), findsOneWidget);
    expect(find.text('86%'), findsOneWidget);
    expect(find.text('32 人评过'), findsOneWidget);
    expect(find.bySemanticsLabel('招牌菜 虾仁云吞'), findsOneWidget);
    expect(find.bySemanticsLabel('招牌菜 牛肉饺子'), findsOneWidget);
    final queries = [
      for (final r in env.adapter.sent('GET /foods/list')) r.query,
    ];
    expect(queries, hasLength(2));
    final signatures = queries.singleWhere((q) => q['signatureOnly'] == true);
    final menu = queries.singleWhere((q) => q['signatureOnly'] == null);
    expect(signatures, containsPair('restaurantId', 7));
    expect(signatures, containsPair('pageSize', 3));
    expect(menu, containsPair('restaurantId', 7));
    expect(menu, containsPair('sort', 'MENU'));
    await expectAccessible(tester);

    await scrollTo(tester, '牛肉饺子');
    expect(find.bySemanticsLabel('主食 2 道'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('堂食评价不满 3 条、外卖满 3 条时，写外卖的推荐率', (tester) async {
    final env = shopEnv(
      details: [
        FakeAdapter.ok(
          detail(dineIn: 2, dineInRate: 1, delivery: 5, deliveryRate: 0.8),
        ),
      ],
    );
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    expect(find.text('外卖推荐率'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('5 人评过'), findsOneWidget);
    await unmountApp(tester, container);
  });

  for (final (dineIn, delivery, text) in [(1, 1, '2 条评价'), (0, 0, '还没人评价')]) {
    testWidgets('两个场景都不满 3 条时写「$text」，不写推荐率', (tester) async {
      final env = shopEnv(
        details: [
          FakeAdapter.ok(
            detail(
              dineIn: dineIn,
              dineInRate: dineIn == 0 ? null : 1,
              delivery: delivery,
              deliveryRate: delivery == 0 ? null : 0,
            ),
          ),
        ],
      );
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.shop(7),
      );

      expect(find.text(text), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      await unmountApp(tester, container);
    });
  }

  testWidgets('菜单方块上写平均分，不满 3 人也写', (tester) async {
    final env = shopEnv();
    env.adapter.on('GET /foods/list', [
      FakeAdapter.ok(
        pageJson([
          {
            ...foodJson(id: 1, name: '虾仁云吞', likes: 30),
            'rating': {'score': 4.6, 'count': 8},
          },
          {
            ...foodJson(id: 2, name: '牛肉饺子', likes: 20),
            'rating': {'score': 5.0, 'count': 2},
          },
        ]),
      ),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    await scrollTo(tester, '全部菜品');
    await scrollTo(tester, '4.6 分');
    expect(find.text('4.6 分'), findsOneWidget);
    await scrollTo(tester, '5.0 分');
    expect(find.text('5.0 分'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('评价：先选堂食或外卖，再选推荐或不推荐；再点一次撤回', (tester) async {
    final env = shopEnv(
      details: [
        FakeAdapter.ok(detail()),
        FakeAdapter.ok(detail(myDelivery: 'RECOMMEND')),
        FakeAdapter.ok(detail()),
      ],
    );
    env.adapter
      ..on('PUT /restaurant/7/rating', [
        FakeAdapter.ok({'dineIn': null, 'delivery': 'RECOMMEND'}),
      ])
      ..on('DELETE /restaurant/7/rating', [
        FakeAdapter.ok({'dineIn': null, 'delivery': null}),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    await tester.tap(find.text('推荐率'));
    await tester.pumpAndSettle();
    expect(find.text('评价这家店'), findsOneWidget);
    expect(find.text('先选在店里吃的还是点的外卖'), findsOneWidget);
    expect(find.text('推荐'), findsNothing, reason: '选场景之前不显示评价');
    await expectAccessible(tester);

    await tester.tap(find.text('外卖'));
    await tester.pumpAndSettle();
    expect(find.text('点选即提交，之后可修改'), findsOneWidget);
    await tester.tap(find.text('推荐'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('PUT /restaurant/7/rating').single.body, {
      'scene': 'delivery',
      'rating': 'RECOMMEND',
    });
    expect(find.text('已选「推荐」，再点一次取消'), findsOneWidget);
    expect(find.text('你：外卖推荐'), findsOneWidget);
    expect(
      env.adapter.sent('GET /restaurant/detail/7'),
      hasLength(2),
      reason: '评价后重新请求店铺详情，更新推荐率',
    );

    await tester.tap(find.text('推荐'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE /restaurant/7/rating').single.query, {
      'scene': 'delivery',
    });
    expect(find.text('你还没评价过这家店'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('已评价时数字条写出两个场景的评价，面板里选中已有的评价', (tester) async {
    final env = shopEnv(
      details: [
        FakeAdapter.ok(
          detail(myDineIn: 'RECOMMEND', myDelivery: 'NOT_RECOMMEND'),
        ),
      ],
    );
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    expect(find.text('你：堂食推荐，外卖不推荐'), findsOneWidget);
    await tester.tap(find.text('推荐率'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('堂食'));
    await tester.pumpAndSettle();
    expect(find.text('已选「推荐」，再点一次取消'), findsOneWidget);
    await tester.tap(find.text('外卖'));
    await tester.pumpAndSettle();
    expect(find.text('已选「不推荐」，再点一次取消'), findsOneWidget);
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

    await tester.tap(find.text('推荐率'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('堂食'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('不推荐'));
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

  testWidgets('没认证时点收藏、评价和编辑都弹拦截对话框，不发请求', (tester) async {
    final env = shopEnv();
    final (container, router) = await pumpApp(
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

    await tester.tap(find.text('推荐率'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能评价'), findsOneWidget);
    expect(find.text('评价这家店'), findsNothing);
    await tester.tap(find.text('先逛逛'));
    await tester.pumpAndSettle();

    await scrollTo(tester, '编辑店铺');
    await tester.tap(find.text('编辑店铺'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能编辑店铺'), findsOneWidget);
    expect(locationOf(router), Paths.shop(7));
    expect(env.adapter.sent('PUT /restaurant/7/favorite'), isEmpty);
    expect(env.adapter.sent('PUT /restaurant/7/rating'), isEmpty);
    await unmountApp(tester, container);
  });

  group('信息有误', () {
    Future<void> openPanel(WidgetTester tester) async {
      await scrollTo(tester, '信息有误');
      await tester.tap(find.text('信息有误'));
      await tester.pumpAndSettle();
    }

    testWidgets('选一项、写补充说明后提交，提示已提交；失败后面板保留，可以重试', (tester) async {
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
      expect(sent.last.headers.containsKey('Idempotency-Key'), isFalse);
      expect(find.text('信息有误'), findsOneWidget);
      expect(find.text('已提交，核实后会通过消息通知你'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });
  });

  testWidgets('已关门的店写「这家店已关门」，导航和加菜都不可用', (tester) async {
    final env = shopEnv(
      details: [
        FakeAdapter.ok({...detail(), 'permanentlyClosed': true}),
      ],
    );
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

  testWidgets('店铺已删除时写「这家店已删除」，不提供重试', (tester) async {
    final env = shopEnv(details: [FakeAdapter.fail(40009)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    expect(find.text('这家店已删除'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    expect(env.adapter.sent('GET /restaurant/detail/7'), hasLength(1));
    await unmountApp(tester, container);
  });

  group('编辑店铺', () {
    Future<ProviderContainer> openEdit(WidgetTester tester, TestEnv env) async {
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.shop(7),
      );
      await scrollTo(tester, '编辑店铺');
      await tester.tap(find.text('编辑店铺'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopEditPage), findsOneWidget);
      return container;
    }

    testWidgets('只提交改动的字段，保存后回到店铺页并刷新', (tester) async {
      final env = shopEnv(
        details: [
          FakeAdapter.ok(detail()),
          FakeAdapter.ok({...detail(), 'name': '袁记云饺万达店'}),
        ],
      );
      env.adapter.on('PUT /restaurant/edit/7', [
        FakeAdapter.ok({'id': 7, 'revisionId': 30}),
      ]);
      final container = await openEdit(tester, env);

      await tester.enterText(find.byType(EditableText).first, '袁记云饺万达店');
      await tester.tap(find.text('火锅麻辣烫'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('这家店已关门'),
        200,
        scrollable: downward,
      );
      expect(find.text('能点外卖'), findsNothing);
      await expectAccessible(tester);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(env.adapter.sent('PUT /restaurant/edit/7').single.body, {
        'name': '袁记云饺万达店',
        'categories': ['粉面', '火锅麻辣烫'],
      });
      expect(find.text('已保存'), findsOneWidget);
      expect(find.byType(ShopEditPage), findsNothing);
      expect(find.text('袁记云饺万达店'), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('品类最多选 2 个；改过内容后返回要确认放弃', (tester) async {
      final env = shopEnv();
      final container = await openEdit(tester, env);

      await tester.tap(find.text('火锅麻辣烫'));
      await tester.tap(find.text('汤粥'));
      await tester.pumpAndSettle();
      expect(find.text('品类最多选 2 个'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));

      await tester.tap(find.bySemanticsLabel('返回'));
      await tester.pumpAndSettle();
      expect(find.text('放弃修改？'), findsOneWidget);
      await tester.tap(find.text('放弃'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopEditPage), findsNothing);
      expect(env.adapter.sent('PUT /restaurant/edit/7'), isEmpty);
      await unmountApp(tester, container);
    });
  });

  group('修改记录', () {
    Map<String, Object?> revision(int id, String action, List<String> fields) =>
        {
          'id': id,
          'action': action,
          'editor': {'id': 9, 'displayName': '小林', 'avatar': null},
          'changes': [
            for (final f in fields) {'field': f, 'from': null, 'to': null},
          ],
          'createdAt': clock
              .now()
              .subtract(const Duration(minutes: 10))
              .millisecondsSinceEpoch,
        };

    testWidgets('写出编辑者、动作和改了哪些字段；最新一条是当前版本', (tester) async {
      final env = shopEnv();
      env.adapter.on('GET /restaurant/7/history', [
        FakeAdapter.ok(
          pageJson([
            revision(31, 'edit', ['name', 'gcjLng', 'gcjLat']),
            revision(29, 'create', ['name', 'address']),
          ]),
        ),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.shop(7),
      );

      await scrollTo(tester, '修改记录');
      await tester.tap(find.text('修改记录'));
      await tester.pumpAndSettle();

      expect(find.text('改了店名、位置'), findsOneWidget);
      expect(find.text('新建了这家店'), findsOneWidget);
      expect(find.text('小林'), findsNWidgets(2));
      expect(find.text('10 分钟前'), findsNWidgets(2));
      expect(find.text('当前版本'), findsOneWidget);
      expect(find.text('恢复'), findsOneWidget);
      await expectAccessible(tester);
      await unmountApp(tester, container);
    });

    testWidgets('恢复前二次确认；已经是这个版本时提示，成功后刷新', (tester) async {
      final env = shopEnv();
      env.adapter
        ..on('GET /restaurant/7/history', [
          FakeAdapter.ok(
            pageJson([
              revision(31, 'edit', ['name']),
              revision(29, 'create', ['name']),
            ]),
          ),
        ])
        ..on('POST /restaurant/7/history/29/restore', [
          FakeAdapter.fail(40002, '当前内容已经是这个版本'),
          FakeAdapter.ok({'id': 7, 'revisionId': 32}),
        ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.shopHistory(7),
      );

      Future<void> restore() async {
        await tester.tap(find.text('恢复'));
        await tester.pumpAndSettle();
        expect(find.text('恢复到这个版本？'), findsOneWidget);
        await tester.tap(find.text('恢复').last);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('恢复'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('先不恢复'));
      await tester.pumpAndSettle();
      expect(
        env.adapter.sent('POST /restaurant/7/history/29/restore'),
        isEmpty,
      );

      await restore();
      expect(find.text('已经是这个版本'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));

      await restore();
      expect(find.text('已恢复'), findsOneWidget);
      expect(
        env.adapter.sent('POST /restaurant/7/history/29/restore'),
        hasLength(2),
      );
      expect(env.adapter.sent('GET /restaurant/7/history'), hasLength(2));
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });
  });
}
