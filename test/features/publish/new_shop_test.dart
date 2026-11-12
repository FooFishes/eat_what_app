import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
  });

  /// 打开新建店页. 没配地图 Key, 直接进手动添加的表单, 店名预填 "麻辣烫".
  Future<(ProviderContainer, GoRouter)> open(WidgetTester tester) async {
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );
    router.push(Paths.publishShop(name: '麻辣烫'));
    await tester.pumpAndSettle();
    return (container, router);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// 填地址描述, 选 "美食". 不滚动页面, 店名下的提示保持在屏幕上.
  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(find.byType(EditableText).at(1), '万达金街 1 层');
    await settle(tester);
    await tester.tap(find.text('美食'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('下一步：去加菜'));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await fill(tester);
    await submit(tester);
  }

  testWidgets('提交失败后可以重试；新店带类型提交，不带幂等键', (tester) async {
    env.adapter.on('POST /restaurant/add', [
      const FakeResponse.offline(),
      FakeAdapter.ok({'id': 9}),
    ]);
    final (container, _) = await open(tester);

    await fillAndSubmit(tester);
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步：去加菜'));
    await tester.pumpAndSettle();

    expect(find.text('新建一家店'), findsNothing);
    final sent = env.adapter.sent('POST /restaurant/add').toList();
    expect(sent, hasLength(2));
    expect(sent.last.body, containsPair('kind', 'food'));
    expect(sent.last.headers.containsKey('Idempotency-Key'), isFalse);
    await unmountApp(tester, container);
  });

  testWidgets('选填项都不动也能提交：饭点默认午饭和晚饭，其余不带；建好后去加菜页', (tester) async {
    env.adapter.on('POST /restaurant/add', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final (container, _) = await open(tester);

    await fillAndSubmit(tester);

    final body = env.adapter.sent('POST /restaurant/add').single.body as Map;
    expect(body['mealTimes'], ['lunch', 'dinner']);
    expect(body['deliveryEnabled'], false);
    for (final key in ['categories', 'tags', 'priceBand', 'picture', 'poi']) {
      expect(body.containsKey(key), isFalse, reason: key);
    }
    expect(find.text('新建一家店'), findsNothing);
    expect(env.adapter.sent('GET /restaurant/detail/9'), isNotEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('类型必选：没选时不能提交，底部提示', (tester) async {
    env.adapter.on('POST /restaurant/add', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final (container, _) = await open(tester);
    await tester.enterText(find.byType(EditableText).at(1), '万达金街 1 层');
    await settle(tester);

    expect(find.text('请选择店铺类型'), findsOneWidget);
    await submit(tester);
    expect(env.adapter.sent('POST /restaurant/add'), isEmpty);

    await tap(tester, '甜点饮品');
    expect(find.text('请选择店铺类型'), findsNothing);
    await expectAccessible(tester);
    await submit(tester);
    final body = env.adapter.sent('POST /restaurant/add').single.body as Map;
    expect(body, containsPair('kind', 'drink'));
    await unmountApp(tester, container);
  });

  testWidgets('选填项：品类最多 2 个，口味、饭点、价位、外卖照选的提交', (tester) async {
    env.adapter.on('POST /restaurant/add', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final (container, _) = await open(tester);
    await fill(tester);

    await tap(tester, '粉面');
    await tap(tester, '米饭炒菜');
    await tap(tester, '汤粥');
    expect(find.text('品类最多选 2 个'), findsOneWidget);
    await tap(tester, '辣');
    await tap(tester, '早饭');
    await tap(tester, '¥15 以下');
    await tap(tester, '能点外卖');
    await submit(tester);

    final body = env.adapter.sent('POST /restaurant/add').single.body as Map;
    expect(body['categories'], ['米饭炒菜', '粉面']);
    expect(body['tags'], ['辣']);
    expect(body['mealTimes'], ['breakfast', 'lunch', 'dinner']);
    expect(body, containsPair('priceBand', 'UNDER_15'));
    expect(body, containsPair('deliveryEnabled', true));
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('100 m 内有店名相同的店：只能选它或改名，改名后能提交', (tester) async {
    env.adapter
      ..on('GET /restaurant/search', [
        FakeAdapter.ok(
          pageJson([
            restaurantJson(id: 5, name: '麻辣烫', lat: 36.6676, lng: 117.1402),
          ]),
        ),
      ])
      ..on('POST /restaurant/add', [
        FakeAdapter.ok({'id': 9}),
      ]);
    final (container, _) = await open(tester);
    await fill(tester);

    expect(find.textContaining('附近已有一家「麻辣烫」'), findsOneWidget);
    expect(find.text('就选它'), findsOneWidget);
    expect(find.text('不是同一家，继续新建'), findsNothing);
    expect(find.text('附近已有同名的店，请换一个店名'), findsOneWidget);
    await submit(tester);
    expect(env.adapter.sent('POST /restaurant/add'), isEmpty);

    await tester.enterText(find.byType(EditableText).at(0), '麻辣烫二店');
    await settle(tester);
    expect(find.textContaining('附近已有一家'), findsNothing);
    await submit(tester);
    final body = env.adapter.sent('POST /restaurant/add').single.body as Map;
    expect(body, containsPair('name', '麻辣烫二店'));
    await unmountApp(tester, container);
  });

  testWidgets('100–200 m 内有同名的店：只提示，可以继续建', (tester) async {
    env.adapter
      ..on('GET /restaurant/search', [
        FakeAdapter.ok(pageJson([restaurantJson(id: 5, name: '麻辣烫')])),
      ])
      ..on('POST /restaurant/add', [
        FakeAdapter.ok({'id': 9}),
      ]);
    final (container, _) = await open(tester);
    await fill(tester);

    expect(find.textContaining('附近已有一家「麻辣烫」'), findsOneWidget);
    await submit(tester);
    expect(env.adapter.sent('POST /restaurant/add'), isEmpty);
    await tap(tester, '不是同一家，继续新建');
    await submit(tester);
    expect(env.adapter.sent('POST /restaurant/add'), hasLength(1));
    await unmountApp(tester, container);
  });

  testWidgets('提交时后端说附近已有这家店：提示，重新查同名，给出那家店的入口，不能再继续建', (tester) async {
    env.adapter.on('POST /restaurant/add', [FakeAdapter.fail(40004)]);
    final (container, _) = await open(tester);
    await fill(tester);
    expect(find.textContaining('附近已有一家'), findsNothing);

    // 填表时还查不到, 提交前别人刚建好了同名的店.
    env.adapter.on('GET /restaurant/search', [
      FakeAdapter.ok(pageJson([restaurantJson(id: 5, name: '麻辣烫')])),
    ]);
    await submit(tester);
    expect(find.text('附近已有这家店'), findsOneWidget);
    await settle(tester);

    expect(find.textContaining('附近已有一家「麻辣烫」'), findsOneWidget);
    expect(find.text('不是同一家，继续新建'), findsNothing);
    expect(find.text('附近已有同名的店，请换一个店名'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tap(tester, '就选它');
    expect(env.adapter.sent('POST /restaurant/add'), hasLength(1));
    expect(env.adapter.sent('GET /restaurant/detail/5'), isNotEmpty);
    await unmountApp(tester, container);
  });
}
