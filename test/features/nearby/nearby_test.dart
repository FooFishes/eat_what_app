import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
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
      ..on('GET /restaurant/search', [
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

    final query = env.adapter.sent('GET /restaurant/search').last.query;
    expect(query['gcjLat'], 36.667382);
    expect(query['radius'], 3000);
    expect(query['campusId'], 1);
    expect(find.text('附近 2 家', findRichText: true), findsOneWidget);
    final near = tester.getTopLeft(find.text('近一点的店'));
    final far = tester.getTopLeft(find.text('远一点的店'));
    expect(near.dy, lessThan(far.dy));
    expect(near.dy, lessThan(300), reason: '没有地图时不留空白的地图区域, 列表从搜索和商圈下面开始');
    await unmountApp(tester, container);
  });

  testWidgets('店铺行写出招牌菜，评价够了的店右边是推荐率', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/search', [
        FakeAdapter.ok(
          pageJson([
            {
              ...restaurantJson(id: 1, name: '袁记云饺'),
              'ratingSummaryState': 'READY',
              'ratingCount': 32,
              'recommendationRate': 86,
              'signatureFoods': [
                {'id': 5, 'name': '鲜虾蟹籽云吞', 'price': 18, 'likesCount': 40},
              ],
            },
            restaurantJson(id: 2, name: '新开的店', lat: 36.6760),
          ]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.nearby,
    );

    expect(find.text('招牌：鲜虾蟹籽云吞'), findsOneWidget);
    expect(find.text('86%'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget, reason: '没人评价的店不写推荐率');
    await unmountApp(tester, container);
  });

  testWidgets('有地图时朗读店数；地图加载失败后提示并只显示列表', (tester) async {
    final env = TestEnv();
    final map = FakeMapEngine();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/search', [
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
      ..on('GET /restaurant/search', [
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
    env.adapter.on('GET /restaurant/search', [
      FakeAdapter.ok(pageJson([restaurantJson(id: 2, name: '近一点的店')])),
    ]);

    await tester.tap(find.bySemanticsLabel('筛选'));
    await _settle(tester);
    expect(find.text('看 2 家'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('小吃'));
    await _settle(tester);
    await tester.tap(find.text('¥15–30'));
    await _settle(tester);
    await tester.ensureVisible(find.text('只看推荐率 80% 以上'));
    await tester.tap(find.text('只看推荐率 80% 以上'));
    await _settle(tester);
    final query = env.adapter.sent('GET /restaurant/search').last.query;
    expect(query['categories'], ['snack']);
    expect(query, containsPair('priceBand', 'FROM_15_TO_30'));
    expect(query, containsPair('recommendedOnly', true));
    expect(query, containsPair('sort', 'DISTANCE'));
    expect(find.text('看 1 家'), findsOneWidget);

    final requests = env.adapter.sent('GET /restaurant/search').length;
    await tester.tap(find.text('看 1 家'));
    await _settle(tester);
    expect(
      env.adapter.sent('GET /restaurant/search'),
      hasLength(requests),
      reason: '面板里查过的条件生效时用缓存，不再请求',
    );
    expect(find.text('附近 1 家', findRichText: true), findsOneWidget);
    expect(find.text('远一点的店'), findsNothing);
    expect(find.bySemanticsLabel('筛选，已选 3 项'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('筛选，已选 3 项'));
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
      ..on('GET /restaurant/search', [
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
      env.adapter.sent('GET /restaurant/search').last.query,
      containsPair('favoritesOnly', true),
    );
    await expectAccessible(tester);
    await tester.tap(find.text('看 1 家'));
    await _settle(tester);
    expect(find.bySemanticsLabel('筛选，已选 1 项'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('排序：选「推荐率最高」后按后端的顺序排，不再按距离重排', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/search', [
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
    expect(
      tester.getTopLeft(find.text('近一点的店')).dy,
      lessThan(tester.getTopLeft(find.text('远一点的店')).dy),
    );

    await tester.tap(find.bySemanticsLabel('排序：按距离'));
    await _settle(tester);
    await expectAccessible(tester);
    await tester.tap(find.text('推荐率最高'));
    await _settle(tester);

    expect(
      env.adapter.sent('GET /restaurant/search').last.query,
      containsPair('sort', 'RECOMMENDATION_RATE'),
    );
    expect(find.bySemanticsLabel('排序：推荐率最高'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('远一点的店')).dy,
      lessThan(tester.getTopLeft(find.text('近一点的店')).dy),
    );
    await expectAccessible(tester);
    await unmountApp(tester, container);
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
