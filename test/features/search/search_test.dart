import 'package:eat/core/platform/location.dart';
import 'package:eat/design/widgets/dish_tile.dart';
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

  Future<void> search(WidgetTester tester, String keyword) async {
    await tester.enterText(find.byType(EditableText), keyword);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('再点一次「菜」从分栏长出饭点筛选；选了就生效、收起，没菜了也停在「菜」', (tester) async {
    env.adapter
      ..on('GET /foods/list', [
        FakeAdapter.ok(pageJson([foodJson()])),
        FakeAdapter.ok(pageJson([])),
      ])
      ..on('GET /restaurant/search', [
        FakeAdapter.ok(pageJson([restaurantJson()])),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );
    await search(tester, '云吞');
    Map<String, dynamic> lastDishQuery() =>
        env.adapter.sent('GET /foods/list').last.query;
    expect(lastDishQuery().containsKey('mealTime'), isFalse);
    expect(find.text('筛选'), findsNothing, reason: '搜索框不再带筛选按钮');
    expect(find.text('吃哪顿'), findsNothing);

    await tester.tap(find.text('菜'));
    await tester.pumpAndSettle();
    expect(find.text('吃哪顿'), findsOneWidget);
    for (final label in ['不限', '早饭', '午饭', '晚饭', '夜宵']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      tester.getTopLeft(find.text('吃哪顿')).dy,
      greaterThan(tester.getBottomLeft(find.text('菜')).dy),
    );
    await expectAccessible(tester);

    await tester.tap(find.text('午饭'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('吃哪顿'), findsNothing);
    expect(lastDishQuery(), containsPair('mealTime', 'lunch'));
    expect(lastDishQuery(), containsPair('keyword', '云吞'));
    expect(find.text('没找到「云吞」'), findsOneWidget, reason: '改了筛选后不自动切到有结果的「店」栏');
    expect(find.bySemanticsLabel(RegExp('午饭')), findsOneWidget);

    final sent = env.adapter.sent('GET /foods/list').length;
    await tester.tap(find.text('菜'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('不限'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('GET /foods/list').length, greaterThan(sent));
    expect(lastDishQuery().containsKey('mealTime'), isFalse);
  });

  testWidgets('筛选开着时点「店」，浮层跟过去换成排序；选外卖推荐率按外卖排，已关门的店仍在最后', (tester) async {
    env.location
      ..state = LocationAccess.granted
      ..point = (lat: 36.6660, lng: 117.1350);
    env.adapter
      ..on('GET /foods/list', [
        FakeAdapter.ok(pageJson([foodJson()])),
      ])
      ..on('GET /restaurant/search', [
        FakeAdapter.ok(pageJson([restaurantJson(id: 1, name: '张亮麻辣烫')])),
        FakeAdapter.ok(
          pageJson([
            {...restaurantJson(id: 2, name: '老店'), 'permanentlyClosed': true},
            restaurantJson(id: 3, name: '杨国福麻辣烫'),
            restaurantJson(id: 1, name: '张亮麻辣烫'),
          ]),
        ),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );
    await search(tester, '麻辣烫');
    Map<String, dynamic> lastShopQuery() =>
        env.adapter.sent('GET /restaurant/search').last.query;
    expect(lastShopQuery(), containsPair('sort', 'DISTANCE'));
    expect(lastShopQuery().containsKey('scene'), isFalse);

    await tester.tap(find.text('菜'));
    await tester.pumpAndSettle();
    final dishPanel = tester.getTopLeft(find.text('吃哪顿'));

    await tester.tap(find.text('店'));
    await tester.pumpAndSettle();
    expect(find.text('吃哪顿'), findsNothing);
    expect(find.text('排序'), findsOneWidget);
    for (final label in ['离我近', '堂食推荐率', '外卖推荐率', '最新']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      tester.getTopLeft(find.text('排序')).dx,
      greaterThan(dishPanel.dx),
      reason: '浮层挪到「店」下面',
    );
    expect(find.text('张亮麻辣烫'), findsOneWidget, reason: '换到了「店」栏');

    await tester.tap(find.text('外卖推荐率'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('排序'), findsNothing);
    expect(lastShopQuery(), containsPair('sort', 'RATING'));
    expect(lastShopQuery(), containsPair('scene', 'delivery'));
    expect(lastShopQuery(), containsPair('keyword', '麻辣烫'));
    expect(find.bySemanticsLabel(RegExp('外卖推荐率')), findsOneWidget);
    final top = [
      for (final name in ['杨国福麻辣烫', '张亮麻辣烫', '老店'])
        tester.getTopLeft(find.text(name)).dy,
    ];
    expect(top[0], lessThan(top[1]), reason: '营业中的店保持后端的顺序');
    expect(top[1], lessThan(top[2]), reason: '已关门的店排在最后');

    await tester.tap(find.text('店'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('堂食推荐率'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(lastShopQuery(), containsPair('sort', 'RATING'));
    expect(lastShopQuery(), containsPair('scene', 'dine_in'));

    await tester.tap(find.text('菜'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('GET /foods/list').last.query.containsKey('mealTime'),
      isFalse,
      reason: '两栏的筛选各管各的',
    );
  });

  testWidgets('再点一次选中的分栏、点外面或系统返回都收起筛选，不改筛选', (tester) async {
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
    await search(tester, '云吞');
    final sent = env.adapter.sent('GET /foods/list').length;

    await tester.tap(find.text('菜'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('菜'));
    await tester.pumpAndSettle();
    expect(find.text('吃哪顿'), findsNothing);

    await tester.tap(find.text('菜'));
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getBottomLeft(find.byType(DishTile)) + const Offset(4, 40),
    );
    await tester.pumpAndSettle();
    expect(find.text('吃哪顿'), findsNothing);

    await tester.tap(find.text('菜'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('吃哪顿'), findsNothing);
    expect(find.text('袁记云饺'), findsOneWidget, reason: '返回先收起浮层，不离开搜索页');
    expect(env.adapter.sent('GET /foods/list').length, sent);
  });
}
