import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

/// 新建店先从地图候选里选. 地图不可用时直接手动添加的情形见 new_shop_test.dart.
void main() {
  late TestEnv env;
  late FakeMapEngine map;

  const place = MapPoi(
    uid: 'baidu-1',
    name: '袁记云饺(舜泰店)',
    address: '舜泰广场 9 号楼 1-105',
    point: MapLatLng(36.6681, 117.1412),
  );

  setUp(() {
    env = TestEnv();
    map = FakeMapEngine();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /restaurant/browse', [FakeAdapter.ok(pageJson([]))]);
  });

  Future<(dynamic, GoRouter)> open(WidgetTester tester, String name) async {
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
      overrides: [mapEngineProvider.overrideWithValue(map)],
    );
    router.push(Paths.publishShop(name: name));
    await tester.pumpAndSettle();
    // 页面建好后检索才开始防抖.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    return (container, router);
  }

  String fieldText(WidgetTester tester, int index) => tester
      .widget<EditableText>(find.byType(EditableText).at(index))
      .controller
      .text;

  testWidgets('按选店页的关键词搜地图，选中后预填店名和地址，提交时带上地点', (tester) async {
    map.places = [place];
    env.adapter.on('POST /restaurant/add', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final (container, _) = await open(tester, '袁记');

    expect(map.searched, ['袁记']);
    expect(find.text('先在地图上找找这家店'), findsOneWidget);
    await expectAccessible(tester);
    await tester.tap(find.text('袁记云饺(舜泰店)'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(fieldText(tester, 0), '袁记云饺(舜泰店)');
    expect(fieldText(tester, 1), '舜泰广场 9 号楼 1-105');
    expect(map.last!.initialCenter, place.point);
    await tester.tap(find.text('下一步：去加菜'));
    await tester.pumpAndSettle();

    final body = env.adapter.sent('POST /restaurant/add').single.body as Map;
    expect(body['POI'], 'baidu-1');
    expect(body['name'], '袁记云饺(舜泰店)');
    expect(body['gcjLat'], 36.6681);
    expect(env.adapter.sent('GET /restaurant/detail/9'), isNotEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('选中的地点已经有人建过店：提示，可以直接选那家', (tester) async {
    map.places = [place];
    env.adapter.on('GET /restaurant/browse', [
      FakeAdapter.ok(pageJson([restaurantJson(id: 7, poi: 'baidu-1')])),
    ]);
    final (container, _) = await open(tester, '袁记');
    await tester.tap(find.text('袁记云饺(舜泰店)'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('这家店已经有了，叫「袁记云饺」'), findsOneWidget);
    expect(find.textContaining('附近已有一家'), findsNothing);
    await tester.tap(find.text('就选它'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('POST /restaurant/add'), isEmpty);
    expect(env.adapter.sent('GET /restaurant/detail/7'), isNotEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('搜不到时手动添加：店名用关键词，返回回到候选，提交不带地点', (tester) async {
    env.adapter.on('POST /restaurant/add', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final (container, _) = await open(tester, '麻辣烫');
    expect(find.text('附近没搜到「麻辣烫」'), findsOneWidget);

    await tester.tap(find.text('搜不到？手动添加'));
    await tester.pumpAndSettle();
    expect(fieldText(tester, 0), '麻辣烫');
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('附近没搜到「麻辣烫」'), findsOneWidget);

    await tester.tap(find.text('搜不到？手动添加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(1), '万达金街 1 层');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步：去加菜'));
    await tester.pumpAndSettle();

    final body = env.adapter.sent('POST /restaurant/add').single.body as Map;
    expect(body.containsKey('POI'), isFalse);
    await unmountApp(tester, container);
  });

  testWidgets('地图上的地址超过 30 个字时照样预填，提示删改，不能提交', (tester) async {
    map.places = [
      const MapPoi(
        uid: 'baidu-2',
        name: '一家店',
        address: '山东省济南市历城区舜华路街道舜泰广场9号楼1层105-1号商铺东侧',
        point: MapLatLng(36.6681, 117.1412),
      ),
    ];
    final (container, _) = await open(tester, '一家店');
    await tester.tap(find.text('一家店').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('地址描述最多 30 个字'), findsOneWidget);
    await tester.tap(find.text('下一步：去加菜'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /restaurant/add'), isEmpty);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('地图搜索失败时可以重试，也可以手动添加', (tester) async {
    map.places = Exception('offline');
    final (container, _) = await open(tester, '袁记');
    expect(find.text('搜索失败'), findsOneWidget);
    expect(find.text('搜不到？手动添加'), findsOneWidget);

    map.places = [place];
    await tester.tap(find.text('重试'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('袁记云饺(舜泰店)'), findsOneWidget);
    await unmountApp(tester, container);
  });
}
