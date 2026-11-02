import 'package:eat/core/platform/location.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter.on('GET /campus/list', [FakeAdapter.ok(campusListJson)]);
  });

  testWidgets('输入停下才搜；菜没有、店有时停在「店」栏，搜过的词记下来', (tester) async {
    env.adapter
      ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [
        FakeAdapter.ok(pageJson([restaurantJson()])),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );

    await tester.enterText(find.byType(EditableText), '袁记');
    await tester.pump(const Duration(milliseconds: 100));
    expect(env.adapter.sent('GET /restaurant/browse'), isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      env.adapter.sent('GET /foods/list').single.query,
      containsPair('keyword', '袁记'),
    );
    expect(find.text('袁记云饺'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(env.kv.values['cache.search.42'], '["袁记"]');
  });

  testWidgets('有定位时搜菜按距离排，菜品方块写出店名和距离', (tester) async {
    env.location
      ..state = LocationAccess.granted
      ..point = (lat: 36.6660, lng: 117.1350);
    env.adapter
      ..on('GET /foods/list', [
        FakeAdapter.ok(
          pageJson([
            {...foodJson(), 'distanceMeters': 321.4},
          ]),
        ),
      ])
      ..on('GET /restaurant/browse', [FakeAdapter.ok(pageJson([]))]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );

    await tester.enterText(find.byType(EditableText), '云吞');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final query = env.adapter.sent('GET /foods/list').single.query;
    expect(query, containsPair('sort', 'DISTANCE'));
    expect(query.containsKey('gcjLat'), isTrue);
    expect(query.containsKey('gcjLng'), isTrue);
    expect(find.text('袁记云饺'), findsOneWidget);
    expect(find.text('320 m'), findsOneWidget);
    await expectAccessible(tester);
  });

  testWidgets('没有定位时搜菜按后端默认顺序，不写距离', (tester) async {
    env.adapter
      ..on('GET /foods/list', [
        FakeAdapter.ok(pageJson([foodJson()])),
      ])
      ..on('GET /restaurant/browse', [FakeAdapter.ok(pageJson([]))]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );

    await tester.enterText(find.byType(EditableText), '云吞');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final query = env.adapter.sent('GET /foods/list').single.query;
    expect(query.containsKey('sort'), isFalse);
    expect(query.containsKey('gcjLat'), isFalse);
    expect(find.text('袁记云饺'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+ k?m$')), findsNothing);
    await expectAccessible(tester);
  });

  testWidgets('什么都没找到：写「没找到」，认证用户可以新建一家店', (tester) async {
    env.adapter
      ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [FakeAdapter.ok(pageJson([]))]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );

    await tester.enterText(find.byType(EditableText), '螺蛳粉');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('没找到「螺蛳粉」'), findsOneWidget);
    expect(find.text('新建一家店'), findsOneWidget);
  });

  testWidgets('没有定位、校区也没加载出来：照常搜店，不带坐标和校区', (tester) async {
    env.adapter
      ..on('GET /campus/list', [const FakeResponse.offline()])
      ..on('GET /foods/list', [
        FakeAdapter.ok(pageJson([foodJson()])),
      ])
      ..on('GET /restaurant/browse', [
        FakeAdapter.ok(pageJson([restaurantJson()])),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );

    await tester.enterText(find.byType(EditableText), '袁记');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('店'));
    await tester.pumpAndSettle();

    final query = env.adapter.sent('GET /restaurant/browse').single.query;
    expect(query, containsPair('keyword', '袁记'));
    expect(query.containsKey('gcjLat'), isFalse);
    expect(query.containsKey('campusId'), isFalse);
    expect(find.text('袁记云饺'), findsWidgets);
    // 校区列表请求离线失败后按退避间隔重试. 卸载前推进 3 秒, 等待重试结束.
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('「店」栏查得到已关门的店，标明「已关门」；按菜名找到的店写出那道菜', (tester) async {
    env.adapter
      ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/browse', [
        FakeAdapter.ok(
          pageJson([
            {
              ...restaurantJson(id: 1, name: '张亮麻辣烫'),
              'operatingStatus': 'OPEN',
              'matchedFoods': [
                {'id': 5, 'name': '酸辣粉', 'price': 12},
              ],
            },
            {
              ...restaurantJson(id: 2, name: '老店'),
              'operatingStatus': 'CLOSED',
              'permanentlyClosed': true,
            },
          ]),
        ),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );

    await tester.enterText(find.byType(EditableText), '酸辣粉');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      env.adapter.sent('GET /restaurant/browse').single.query,
      containsPair('keyword', '酸辣粉'),
    );
    expect(find.text('有 酸辣粉 ¥12'), findsOneWidget);
    expect(find.textContaining('已关门'), findsOneWidget);
  });
}
