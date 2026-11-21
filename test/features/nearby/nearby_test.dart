import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/features/shop/shop_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('没配地图 Key 时只显示列表：校区中心附近的店，按距离排', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [
        FakeAdapter.ok(
          pageJson([
            restaurantJson(id: 1, name: '远一点的店', lat: 36.6760),
            restaurantJson(id: 2, name: '近一点的店', lat: 36.6680),
          ]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.nearby,
    );

    final query = env.adapter.sent('GET /restaurant/browse').last.query;
    expect(query['gcjLat'], 36.667382);
    expect(query['radius'], 3000);
    expect(query.containsKey('campusId'), isFalse);
    expect(find.text('附近 2 家', findRichText: true), findsOneWidget);
    final near = tester.getTopLeft(find.text('近一点的店'));
    final far = tester.getTopLeft(find.text('远一点的店'));
    expect(near.dy, lessThan(far.dy));
    expect(near.dy, lessThan(300), reason: '没有地图时不留空白的地图区域, 列表从搜索框下面开始');
    await unmountApp(tester, container);
  });

  testWidgets('店铺行右边是推荐率，评价不满 3 条的不写；已关门的店不出现；没有排序入口', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [
        FakeAdapter.ok(
          pageJson([
            {
              ...restaurantJson(id: 1, name: '袁记云饺'),
              'dineIn': {'rate': 0.86, 'count': 32},
            },
            {
              ...restaurantJson(id: 2, name: '新开的店', lat: 36.6760),
              'dineIn': {'rate': 1.0, 'count': 2},
            },
            {
              ...restaurantJson(id: 3, name: '关门的店', lat: 36.6690),
              'permanentlyClosed': true,
            },
          ]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.nearby,
    );

    expect(find.text('附近 2 家', findRichText: true), findsOneWidget);
    expect(find.text('关门的店'), findsNothing);
    expect(find.text('86%'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget, reason: '不满 3 条评价的店不写推荐率');
    expect(find.bySemanticsLabel(RegExp('^排序')), findsNothing);
    expect(
      env.adapter.sent('GET /restaurant/browse').last.query,
      containsPair('sort', 'DISTANCE'),
    );
    await unmountApp(tester, container);
  });

  group('选商圈', () {
    late TestEnv env;

    Map<String, Object?> hub(int id, String name, double lat, double lng) => {
      'id': id,
      'name': name,
      'gcjLng': lng,
      'gcjLat': lat,
      'boundary': null,
    };

    Future<ProviderContainer> open(WidgetTester tester) async {
      env = TestEnv();
      env.adapter
        ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
        ..on('GET /hub/list', [
          FakeAdapter.ok(
            pageJson([
              hub(2, '西门小吃街', 36.6900, 117.1700),
              hub(1, '舜泰广场', 36.6681, 117.1412),
              hub(3, '洪家楼', 36.687406, 117.068225),
            ]),
          ),
        ])
        ..on('GET /restaurant/browse', [
          FakeAdapter.ok(
            pageJson([
              restaurantJson(id: 1, name: '远一点的店', lat: 36.6760),
              restaurantJson(id: 2, name: '近一点的店', lat: 36.6680),
            ]),
          ),
        ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.nearby,
      );
      return container;
    }

    Finder panelField() => find.descendant(
      of: find.byType(EatPanel),
      matching: find.byType(EditableText),
    );

    Future<void> openPanel(WidgetTester tester, String current) async {
      await tester.tap(find.bySemanticsLabel('商圈，$current'));
      await _settle(tester);
      expect(find.text('选商圈'), findsOneWidget);
    }

    testWidgets('没选商圈时按钮写「附近」；面板里「附近」在前，商圈按离校区中心的距离排并写距离', (tester) async {
      final container = await open(tester);
      expect(find.bySemanticsLabel('商圈，附近'), findsOneWidget);
      expect(find.text('舜泰广场'), findsNothing, reason: '商圈不再横排在搜索框下面');

      await openPanel(tester, '附近');
      expect(find.text('最近'), findsNothing, reason: '还没选过商圈');
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('130 m'), findsOneWidget);
      expect(find.text('3.7 km'), findsOneWidget);
      expect(find.text('洪家楼'), findsNothing, reason: '不搜时只列离校区不远的商圈');
      final panel = find.byType(EatPanel);
      final nearby = tester.getTopLeft(
        find.descendant(of: panel, matching: find.text('附近')),
      );
      final near = tester.getTopLeft(find.text('舜泰广场'));
      final far = tester.getTopLeft(find.text('西门小吃街'));
      expect(
        nearby.dy < near.dy || (nearby.dy == near.dy && nearby.dx < near.dx),
        isTrue,
      );
      expect(
        near.dy < far.dy || (near.dy == far.dy && near.dx < far.dx),
        isTrue,
      );
      await expectAccessible(tester);
      await unmountApp(tester, container);
    });

    testWidgets('按名字搜：校区外的商圈也能搜到并选中，没有结果时写明', (tester) async {
      final container = await open(tester);
      await openPanel(tester, '附近');

      await tester.enterText(panelField(), '洪家');
      await _settle(tester);
      expect(find.text('洪家楼'), findsOneWidget);
      expect(find.text('舜泰广场'), findsNothing);
      expect(find.text('全部'), findsNothing);

      await tester.enterText(panelField(), '万达');
      await _settle(tester);
      expect(find.text('没找到「万达」'), findsOneWidget);

      await tester.enterText(panelField(), '洪家');
      await _settle(tester);
      await tester.tap(find.text('洪家楼'));
      await _settle(tester);
      expect(find.text('洪家楼 2 家', findRichText: true), findsOneWidget);
      expect(
        env.adapter.sent('GET /restaurant/browse').last.query,
        containsPair('hubId', 3),
      );
      await unmountApp(tester, container);
    });

    testWidgets('选商圈后关上面板，列表只看这个商圈；再打开有「最近」；选「附近」回到按地图中心找', (tester) async {
      final container = await open(tester);
      await openPanel(tester, '附近');
      await tester.tap(find.text('舜泰广场'));
      await _settle(tester);

      expect(find.text('选商圈'), findsNothing);
      expect(find.bySemanticsLabel('商圈，舜泰广场'), findsOneWidget);
      expect(find.text('舜泰广场 2 家', findRichText: true), findsOneWidget);
      var query = env.adapter.sent('GET /restaurant/browse').last.query;
      expect(query, containsPair('hubId', 1));
      expect(query.containsKey('radius'), isFalse);

      await openPanel(tester, '舜泰广场');
      expect(find.text('最近'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(EatPanel), matching: find.text('舜泰广场')),
        findsNWidgets(2),
        reason: '最近和全部里各一个',
      );
      await tester.tap(
        find.descendant(of: find.byType(EatPanel), matching: find.text('附近')),
      );
      await _settle(tester);

      expect(find.text('选商圈'), findsNothing);
      expect(find.bySemanticsLabel('商圈，附近'), findsOneWidget);
      expect(find.text('附近 2 家', findRichText: true), findsOneWidget);
      query = env.adapter.sent('GET /restaurant/browse').last.query;
      expect(query.containsKey('hubId'), isFalse);
      expect(query['radius'], 3000);
      await unmountApp(tester, container);
    });
  });

  testWidgets('有地图时朗读店数；地图加载失败后提示并只显示列表', (tester) async {
    final env = TestEnv();
    final map = FakeMapEngine();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [
        FakeAdapter.ok(
          pageJson([
            restaurantJson(id: 1, name: '远一点的店', lat: 36.6760),
            restaurantJson(id: 2, name: '近一点的店', lat: 36.6680),
          ]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.nearby,
      overrides: [mapEngineProvider.overrideWithValue(map)],
    );

    expect(find.bySemanticsLabel('地图，附近 2 家店'), findsOneWidget);
    expect(map.last!.initialCenter, const MapLatLng(36.667382, 117.140109));
    expect(map.last!.dark, isFalse);

    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(map.last!.dark, isTrue, reason: '深色模式下底图换成深灰');
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    await tester.pumpAndSettle();

    map.last!.onFailed!();
    await tester.pump();
    expect(find.text('地图加载失败，已切换为列表'), findsOneWidget);
    expect(find.bySemanticsLabel('地图，附近 2 家店'), findsNothing);
    expect(find.text('近一点的店'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('筛选：结果数随选项变化，确定后列表跟着变，按钮写明选了几项', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [
        FakeAdapter.ok(
          pageJson([
            restaurantJson(id: 1, name: '远一点的店', lat: 36.6760),
            restaurantJson(id: 2, name: '近一点的店', lat: 36.6680),
          ]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.nearby,
    );
    env.adapter.on('GET /restaurant/browse', [
      FakeAdapter.ok(pageJson([restaurantJson(id: 2, name: '近一点的店')])),
    ]);

    await tester.tap(find.bySemanticsLabel('筛选'));
    await _settle(tester);
    expect(find.text('看 2 家'), findsOneWidget);
    await expectAccessible(tester);

    Future<void> tap(String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await _settle(tester);
    }

    await tap('甜点饮品');
    await tap('粉面');
    await tap('¥ 15–30');
    expect(find.text('至少 3 条评价，推荐率不低于 70%'), findsOneWidget);
    await tap('只看口碑好的');
    final query = env.adapter.sent('GET /restaurant/browse').last.query;
    expect(query, containsPair('kind', 'drink'));
    expect(query['categories'], ['粉面']);
    expect(query, containsPair('priceBand', 'FROM_15_TO_30'));
    expect(query, containsPair('recommendedOnly', true));
    expect(query, containsPair('sort', 'DISTANCE'));
    expect(find.text('看 1 家'), findsOneWidget);

    final requests = env.adapter.sent('GET /restaurant/browse').length;
    await tester.tap(find.text('看 1 家'));
    await _settle(tester);
    expect(
      env.adapter.sent('GET /restaurant/browse'),
      hasLength(requests),
      reason: '面板里查过的条件生效时用缓存，不再请求',
    );
    expect(find.text('附近 1 家', findRichText: true), findsOneWidget);
    expect(find.text('远一点的店'), findsNothing);
    expect(find.bySemanticsLabel('筛选，已选 4 项'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('筛选，已选 4 项'));
    await _settle(tester);
    await tester.tap(find.text('重置'));
    await _settle(tester);
    expect(find.text('看 2 家'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('未认证账号也能只看收藏的店，不弹认证拦截', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [
        FakeAdapter.ok(pageJson([restaurantJson(id: 2, name: '收藏的店')])),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.nearby,
    );

    await tester.tap(find.bySemanticsLabel('筛选'));
    await _settle(tester);
    await tester.ensureVisible(find.text('只看我收藏的店'));
    await tester.tap(find.text('只看我收藏的店'));
    await _settle(tester);

    expect(find.textContaining('认证后才能'), findsNothing);
    expect(
      env.adapter.sent('GET /restaurant/browse').last.query,
      containsPair('favoritesOnly', true),
    );
    await expectAccessible(tester);
    await tester.tap(find.text('看 1 家'));
    await _settle(tester);
    expect(find.bySemanticsLabel('筛选，已选 1 项'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('游客打开「只看我收藏的店」先弹登录拦截，选项不打开，也不请求', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [
        FakeAdapter.ok(pageJson([restaurantJson(id: 2, name: '近一点的店')])),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const Guest(),
      location: Paths.nearby,
    );

    await tester.tap(find.bySemanticsLabel('筛选'));
    await _settle(tester);
    await tester.ensureVisible(find.text('只看我收藏的店'));
    await tester.tap(find.text('只看我收藏的店'));
    await _settle(tester);
    expect(find.text('登录后才能看收藏'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('先逛逛'));
    await _settle(tester);
    expect(
      env.adapter
          .sent('GET /restaurant/browse')
          .where((r) => r.query.containsKey('favoritesOnly')),
      isEmpty,
    );
    await tester.tap(find.text('看 1 家'));
    await _settle(tester);
    expect(find.bySemanticsLabel('筛选'), findsOneWidget, reason: '没有选上任何一项');
    await unmountApp(tester, container);
  });

  group('有地图时', () {
    late TestEnv env;
    late FakeMapEngine map;

    Future<ProviderContainer> open(WidgetTester tester) async {
      env = TestEnv();
      map = FakeMapEngine();
      env.adapter
        ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
        ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
        ..on('GET /restaurant/browse', [
          FakeAdapter.ok(
            pageJson([
              restaurantJson(id: 1, name: '远一点的店', lat: 36.6760),
              restaurantJson(id: 2, name: '近一点的店', lat: 36.6680),
            ]),
          ),
          FakeAdapter.ok(
            pageJson([restaurantJson(id: 3, name: '新地方的店', lat: 36.6700)]),
          ),
        ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.nearby,
        overrides: [mapEngineProvider.overrideWithValue(map)],
      );
      return container;
    }

    testWidgets('点列表里的店先在地图上选中并给出引导，再点一次进店', (tester) async {
      final container = await open(tester);

      await tester.tap(find.text('近一点的店'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopPage), findsNothing);
      expect(find.text('在地图上了，再点一次进店'), findsOneWidget);
      expect(
        env.adapter.sent('GET /restaurant/browse'),
        hasLength(1),
        reason: '地图移到这家店不重新查附近的店',
      );

      await tester.tap(find.text('近一点的店'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopPage), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('拖动地图后重新加载时先留着上一次的店，结果回来再换', (tester) async {
      final container = await open(tester);
      expect(find.text('近一点的店'), findsOneWidget);

      map.last!.onCameraIdle!(
        const MapCamera(center: MapLatLng(36.67, 117.14), zoom: 16),
        true,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('近一点的店'), findsOneWidget, reason: '新结果回来之前不退回骨架');
      expect(find.bySemanticsLabel('正在加载'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('近一点的店'), findsNothing);
      expect(find.text('新地方的店'), findsOneWidget);
      expect(find.bySemanticsLabel('正在加载'), findsNothing);
      await unmountApp(tester, container);
    });
  });
}

/// 推进时间, 直到请求完成且界面稳定.
///
/// 测试关闭了动画, 点击后不一定产生新帧. 没有新帧时 pumpAndSettle 不推进时间.
/// dio 的请求和响应依赖零时长定时器, 因此在 pumpAndSettle 之前推进 100ms, 使请求链执行完毕.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}
