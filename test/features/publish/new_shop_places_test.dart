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
      ..on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/duplicates', [FakeAdapter.ok([])]);
  });

  /// 后端查出的同一地点上的店.
  final samePlace = FakeAdapter.ok([
    {
      'id': 7,
      'name': '袁记云饺',
      'address': '舜泰广场',
      'distanceMeters': 0.0,
      'permanentlyClosed': false,
      'reason': 'poi',
    },
  ]);

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

  /// 选 "美食" 后提交.
  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('美食'));
    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步：去加菜'));
    await tester.pumpAndSettle();
  }

  testWidgets('按选店页的关键词搜地图，选中后预填店名和地址，提交时带上地点', (tester) async {
    map.places = [place];
    env.adapter.on('POST /restaurant/add', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final (container, _) = await open(tester, '袁记');

    expect(map.searched, ['袁记']);
    expect(find.text('新建一家店'), findsOneWidget);
    await expectAccessible(tester);
    await tester.tap(find.text('袁记云饺(舜泰店)'));
    // 地图建好后报一次中心, 查重的防抖重新计时, 因此等两轮.
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    expect(fieldText(tester, 0), '袁记云饺(舜泰店)');
    expect(fieldText(tester, 1), '舜泰广场 9 号楼 1-105');
    expect(map.last!.initialCenter, place.point);
    await submit(tester);

    final body = env.adapter.sent('POST /restaurant/add').single.body as Map;
    expect(body['poi'], 'baidu-1');
    expect(body['name'], '袁记云饺(舜泰店)');
    expect(body['gcjLat'], 36.6681);
    expect(env.adapter.sent('GET /restaurant/detail/9'), isNotEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('选中的地点已经有人建过店：提示，可以直接选那家', (tester) async {
    map.places = [place];
    env.adapter.on('GET /restaurant/duplicates', [samePlace]);
    final (container, _) = await open(tester, '袁记');
    await tester.tap(find.text('袁记云饺(舜泰店)'));
    // 地图建好后报一次中心, 查重的防抖重新计时, 因此等两轮.
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    expect(find.text('这家店已经有了，叫「袁记云饺」'), findsOneWidget);
    expect(
      env.adapter.sent('GET /restaurant/duplicates').last.query,
      containsPair('poi', 'baidu-1'),
    );
    await tester.tap(find.text('就选它'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('POST /restaurant/add'), isEmpty);
    expect(env.adapter.sent('GET /restaurant/detail/7'), isNotEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('选中的地点已经有店，也可以继续新建：照样带上地点，并带 force', (tester) async {
    map.places = [place];
    env.adapter
      ..on('GET /restaurant/duplicates', [samePlace])
      ..on('POST /restaurant/add', [
        FakeAdapter.ok({'id': 9}),
      ]);
    final (container, _) = await open(tester, '袁记');
    await tester.tap(find.text('袁记云饺(舜泰店)'));
    // 地图建好后报一次中心, 查重的防抖重新计时, 因此等两轮.
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('下一步：去加菜'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /restaurant/add'), isEmpty);
    await tester.tap(find.text('不是同一家，继续新建'));
    await tester.pumpAndSettle();
    expect(find.textContaining('这家店已经有了'), findsNothing);
    await submit(tester);

    final body = env.adapter.sent('POST /restaurant/add').single.body as Map;
    expect(body['poi'], 'baidu-1');
    expect(body['force'], true);
    expect(body['name'], '袁记云饺(舜泰店)');
    expect(body['gcjLat'], 36.6681);
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
    await submit(tester);

    final body = env.adapter.sent('POST /restaurant/add').single.body as Map;
    expect(body.containsKey('poi'), isFalse);
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

  group('调整位置', () {
    /// 查商圈时带的纬度, 按请求顺序.
    List<Object?> hubLats() => [
      for (final r in env.adapter.sent('GET /hub/locate')) r.query['gcjLat'],
    ];

    bool mapLocked(WidgetTester tester) => tester
        .widget<IgnorePointer>(
          find
              .ancestor(
                of: find.byType(EatMap, skipOffstage: false),
                matching: find.byType(IgnorePointer, skipOffstage: false),
              )
              .first,
        )
        .ignoring;

    Future<void> settle(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    /// 把地图滚到屏幕中间, 上面的标题和下面的按钮, 商圈都在屏幕上.
    Future<void> showMap(WidgetTester tester) async {
      await Scrollable.ensureVisible(
        tester.element(find.byType(EatMap, skipOffstage: false)),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
    }

    /// 选中候选进入表单, 等商圈查完.
    Future<dynamic> openForm(WidgetTester tester) async {
      map.places = [place];
      env.adapter.on('GET /hub/locate', [
        FakeAdapter.ok({
          'id': 1,
          'name': '舜泰广场',
          'gcjLat': 36.6681,
          'gcjLng': 117.1412,
          'boundary': null,
        }),
      ]);
      final (container, _) = await open(tester, '袁记');
      await tester.tap(find.text('袁记云饺(舜泰店)'));
      await settle(tester);
      await showMap(tester);
      return container;
    }

    void idle(double lat, double lng, {required bool byGesture}) =>
        map.last!.onCameraIdle!(
          MapCamera(center: MapLatLng(lat, lng), zoom: 17),
          byGesture,
        );

    /// 点地图下面的按钮. [showMap] 已把它们留在屏幕上, 不再滚动.
    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    testWidgets('地图默认锁定，点「调整位置」后才能拖', (tester) async {
      final container = await openForm(tester);
      expect(find.text('位置'), findsOneWidget);
      expect(mapLocked(tester), isTrue);
      expect(find.text('用这个位置'), findsNothing);

      await tapText(tester, '调整位置');
      expect(mapLocked(tester), isFalse);
      expect(find.text('拖动地图，让标记对准店门口'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('用这个位置'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('不是手势引起的视角变化不改位置', (tester) async {
      final container = await openForm(tester);
      idle(0.0001, 0.0001, byGesture: false);
      await tapText(tester, '调整位置');
      idle(0.0001, 0.0001, byGesture: false);
      await tapText(tester, '用这个位置');
      await settle(tester);

      expect(hubLats(), isNotEmpty);
      expect(hubLats(), everyElement(36.6681));
      expect(find.textContaining('属于 舜泰广场'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('拖动后点「用这个位置」才按新位置查商圈', (tester) async {
      final container = await openForm(tester);
      await tapText(tester, '调整位置');
      idle(36.6700, 117.1500, byGesture: true);
      await settle(tester);
      expect(hubLats(), everyElement(36.6681), reason: '确认之前不按拖到的点查');

      await tapText(tester, '用这个位置');
      await settle(tester);
      expect(hubLats().last, 36.6700);
      expect(mapLocked(tester), isTrue);
      expect(find.text('调整位置'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('拖动后点「取消」位置不变', (tester) async {
      final container = await openForm(tester);
      await tapText(tester, '调整位置');
      idle(36.6700, 117.1500, byGesture: true);
      await tapText(tester, '取消');
      await settle(tester);

      expect(hubLats(), everyElement(36.6681));
      expect(mapLocked(tester), isTrue);
      await unmountApp(tester, container);
    });

    testWidgets('查商圈失败时显示「暂时无法判断」', (tester) async {
      map.places = [place];
      env.adapter.on('GET /hub/locate', [FakeAdapter.fail(10001)]);
      final (container, _) = await open(tester, '袁记');
      await tester.tap(find.text('袁记云饺(舜泰店)'));
      await settle(tester);
      await showMap(tester);
      await settle(tester);

      expect(find.textContaining('暂时无法判断'), findsOneWidget);
      expect(find.textContaining('判断中'), findsNothing);
      await unmountApp(tester, container);
    });
  });
}
