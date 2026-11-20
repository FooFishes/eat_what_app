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
      ..on('GET /restaurant/search', [
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
    expect(env.adapter.sent('GET /restaurant/search'), isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final dishQuery = env.adapter.sent('GET /foods/list').single.query;
    expect(dishQuery, containsPair('keyword', '袁记'));
    expect(dishQuery.containsKey('campusId'), isFalse, reason: '后端搜菜不按校区筛选');
    expect(dishQuery.containsKey('mealTime'), isFalse);
    expect(
      dishQuery,
      containsPair('scene', 'dine_in'),
      reason: '带场景时服务端才排除已关门的店',
    );
    expect(find.text('袁记云饺'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(env.kv.values['cache.search.42'], '["袁记"]');
  });

  testWidgets('有定位时搜菜也按最新排，不带坐标，菜品方块写出店名、不写距离', (tester) async {
    env.location
      ..state = LocationAccess.granted
      ..point = (lat: 36.6660, lng: 117.1350);
    env.adapter
      ..on('GET /foods/list', [
        FakeAdapter.ok(pageJson([foodJson()])),
      ])
      ..on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
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
    expect(query, containsPair('sort', 'NEWEST'));
    expect(query.containsKey('gcjLat'), isFalse);
    expect(query.containsKey('gcjLng'), isFalse);
    expect(find.text('袁记云饺'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+ k?m$')), findsNothing);
    await expectAccessible(tester);
  });

  testWidgets('没有定位时搜菜按最新排，不写距离', (tester) async {
    env.adapter
      ..on('GET /foods/list', [
        FakeAdapter.ok(pageJson([foodJson()])),
      ])
      ..on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
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
    expect(query, containsPair('sort', 'NEWEST'));
    expect(query.containsKey('gcjLat'), isFalse);
    expect(find.text('袁记云饺'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+ k?m$')), findsNothing);
    await expectAccessible(tester);
  });

  testWidgets('什么都没找到：写「没找到」，认证用户可以新建一家店', (tester) async {
    env.adapter
      ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
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
      ..on('GET /restaurant/search', [
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

    final query = env.adapter.sent('GET /restaurant/search').single.query;
    expect(query, containsPair('keyword', '袁记'));
    expect(query.containsKey('gcjLat'), isFalse);
    expect(query.containsKey('campusId'), isFalse);
    expect(
      env.adapter.sent('GET /foods/list').single.query.containsKey('campusId'),
      isFalse,
    );
    expect(find.text('袁记云饺'), findsWidgets);
    // 校区列表请求离线失败后按退避间隔重试. 卸载前推进 3 秒, 等待重试结束.
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('「店」栏查得到已关门的店，排在最后并标明「已关门」', (tester) async {
    env.adapter
      ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/search', [
        FakeAdapter.ok(
          pageJson([
            {...restaurantJson(id: 2, name: '老店'), 'permanentlyClosed': true},
            restaurantJson(id: 1, name: '张亮麻辣烫', lat: 36.6760),
            restaurantJson(id: 3, name: '杨国福麻辣烫', lat: 36.6790),
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
      env.adapter.sent('GET /restaurant/search').single.query,
      containsPair('keyword', '酸辣粉'),
    );
    expect(find.textContaining('已关门'), findsOneWidget);
    final top = [
      for (final name in ['张亮麻辣烫', '杨国福麻辣烫', '老店'])
        tester.getTopLeft(find.text(name)).dy,
    ];
    expect(top[0], lessThan(top[1]), reason: '营业中的店保持后端的距离顺序');
    expect(top[1], lessThan(top[2]));
  });

  testWidgets('按菜名搜到的店写出搜到的那道菜和价格', (tester) async {
    env.adapter
      ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/search', [
        FakeAdapter.ok(
          pageJson([
            {
              ...restaurantJson(id: 1, name: '袁记云饺'),
              'matchedFood': {'id': 5, 'name': '鲜虾云吞', 'price': 18},
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

    await tester.enterText(find.byType(EditableText), '云吞');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('有「鲜虾云吞」 ¥ 18'), findsOneWidget);
  });
}
