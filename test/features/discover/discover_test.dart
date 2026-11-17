import 'dart:math' as math;

import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/turntable.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/features/discover/shop_entry.dart';
import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/features/shop/shop_page.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/analytics.dart';
import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';
import '../../support/recommend_json.dart';
import '../../support/screen.dart';

const _names = ['袁记云饺', '一碗面', '老王烧烤', '粥铺', '饺子馆'];

/// 推荐接口的一批: [_names] 五家店, 第一家带招牌菜和推荐率, 其余没有.
Map<String, Object?> _feed({bool hasNext = false}) => FakeAdapter.ok(
  feedJson([
    for (final (i, name) in _names.indexed)
      i == 0
          ? cardJson(id: i + 1, name: name)
          : cardJson(
              id: i + 1,
              name: name,
              signature: null,
              dineIn: (rate: 0.5, count: 1),
            ),
  ], hasNext: hasNext),
);

/// 抽屉店铺条目以外 (即舞台上) 文字为 [text] 的组件数.
int _offRows(String text) =>
    find.text(text).evaluate().length -
    find
        .descendant(of: find.byType(ShopEntry), matching: find.text(text))
        .evaluate()
        .length;

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /notification/cards/unread/count', [
        FakeAdapter.ok({'cards': 3, 'members': 5}),
      ])
      ..on('GET /recommend', [_feed()]);
  });

  testWidgets('舞台上是推荐的第一家店；「换一个」转到下一家，「就它了」进餐厅详情', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
    );

    // 有招牌菜时菜名是舞台大字, 店名排在下面, 同时出现在抽屉的店铺行中.
    expect(
      find.text(DishRules.stageLines('鲜虾蟹籽云吞').join('\n')),
      findsOneWidget,
    );
    expect(find.text('袁记云饺'), findsNWidgets(2));
    expect(_offRows('¥18'), 1, reason: '舞台上的价格');
    expect(find.text('86% 推荐'), findsOneWidget, reason: '舞台上的推荐率');
    expect(find.text('招牌：鲜虾蟹籽云吞'), findsNothing, reason: '招牌菜在店铺行下面单独排成方块');
    expect(find.text('万达金街'), findsWidgets, reason: '没有定位时写商圈名');
    final sent = env.adapter.sent('GET /recommend');
    expect(
      sent.map((r) => r.query['campusId']),
      everyElement(1),
      reason: '校区定下来之前不拉推荐：推荐按天去重，发错的请求也会占掉店',
    );
    expect(sent.map((r) => r.query['scene']), everyElement('dine_in'));
    expect(sent.map((r) => r.query['kind']), everyElement('food'));
    expect(sent.map((r) => r.query['pageSize']), containsAll([8, 10]));
    expect(find.bySemanticsLabel('消息，3 条未读'), findsOneWidget);
    expect(find.text('在 软件园 吃 ${_mealLabel()}'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('换一个'));
    await tester.pumpAndSettle();
    expect(_offRows('一碗面'), 1, reason: '舞台换到下一家');
    expect(find.text('袁记云饺'), findsOneWidget);
    expect(_offRows('¥18'), 0, reason: '没有招牌菜的店名是大字，不写价格');
    expect(find.text('50% 推荐'), findsNothing, reason: '评价不满 3 条不显示推荐率');

    await tester.tap(find.text('就它了'));
    await tester.pumpAndSettle();
    expect(tester.widget<ShopPage>(find.byType(ShopPage)).shopId, 2);
    await unmountApp(tester, container);
  });

  testWidgets('抽屉里每家店：序号和推荐理由，菜排成一行、第一道最宽，不放门头照；点菜进菜品详情、点店名进餐厅详情', (
    tester,
  ) async {
    env.adapter.on('GET /recommend', [
      FakeAdapter.ok(
        feedJson([
          cardJson(
            id: 1,
            moreFoods: [
              {
                'id': 201,
                'name': '鲜肉小馄饨',
                'price': 12,
                'pictureUrl': 'https://img.test/foods/2.jpg',
                'signature': true,
                'rating': {'score': 4.3, 'count': 5},
              },
              {'id': 202, 'name': '紫菜蛋花汤', 'price': null},
            ],
          ),
          cardJson(
            id: 2,
            name: '一碗面',
            signature: null,
            moreFoods: [
              {
                'id': 301,
                'name': '牛肉面',
                'price': 16,
                'rating': {'score': 4.0, 'count': 7},
              },
            ],
          ),
        ]),
      ),
    ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
    );

    final first = find.ancestor(
      of: find.textContaining('紫菜蛋花汤', findRichText: true),
      matching: find.byType(ShopEntry),
    );
    Finder inFirst(Finder finder) =>
        find.descendant(of: first, matching: finder);
    expect(inFirst(find.byType(CoverImage)), findsNWidgets(3));
    expect(inFirst(find.byType(DishPlate)), findsNothing, reason: '带盘沿的盘子只给舞台');
    expect(inFirst(find.byType(ListThumb)), findsNothing, reason: '不放门头照');
    expect(inFirst(find.text('招牌')), findsOneWidget, reason: '只有标过招牌的菜挂签');
    expect(
      inFirst(find.textContaining('¥12', findRichText: true)),
      findsOneWidget,
    );
    expect(
      inFirst(find.textContaining('¥18', findRichText: true)),
      findsOneWidget,
      reason: '第一道是主图',
    );
    expect(
      inFirst(find.textContaining('4.3 分', findRichText: true)),
      findsNothing,
      reason: '一行里的菜只写菜名和价格',
    );
    expect(inFirst(find.text('01')), findsOneWidget, reason: '榜单序号');
    expect(inFirst(find.text('86%')), findsOneWidget, reason: '推荐理由：推荐率');
    expect(
      inFirst(find.textContaining('招牌：')),
      findsNothing,
      reason: '菜已经摆出来了，不再写一行招牌菜名',
    );

    await tester.dragUntilVisible(
      find.textContaining('牛肉面', findRichText: true),
      first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    final second = find.ancestor(
      of: find.textContaining('牛肉面', findRichText: true),
      matching: find.byType(ShopEntry),
    );
    expect(
      find.descendant(of: second, matching: find.text('02')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: second, matching: find.byType(CoverImage)),
      findsOneWidget,
      reason: '只有一道菜时图在左，菜名和价格在右',
    );

    await tester.ensureVisible(
      find.textContaining('鲜肉小馄饨', findRichText: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('鲜肉小馄饨', findRichText: true));
    await tester.pumpAndSettle();
    expect(tester.widget<DishPage>(find.byType(DishPage)).dishId, 201);

    router.pop();
    await tester.pumpAndSettle();
    // 刚才往下翻过, 店名被固定在顶部的分类栏挡住, 先拉回来再点.
    await tester.drag(first, const Offset(0, 400));
    await tester.pumpAndSettle();
    await tester.tap(inFirst(find.text('袁记云饺')));
    await tester.pumpAndSettle();
    expect(tester.widget<ShopPage>(find.byType(ShopPage)).shopId, 1);
    await unmountApp(tester, container);
  });

  testWidgets('「就它了」记店和招牌菜；「换一个」和拖动转盘各记一次换菜', (tester) async {
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      overrides: [recordAnalytics],
    );

    await tester.tap(find.text('就它了'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    final recorded = recordedIn(container);
    expect(recorded.propertiesOf<DishDecideEvent>(), [
      {'event': 'dish_decide', 'restaurantId': 1, 'foodId': 101},
    ]);
    expect(recorded.propertiesOf<DishShuffleEvent>(), isEmpty);

    await tester.tap(find.text('换一个'));
    await tester.pumpAndSettle();
    final plate = find
        .descendant(
          of: find.byType(Turntable),
          matching: find.byType(DishPlate),
        )
        .first;
    await tester.dragFrom(tester.getCenter(plate), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(_offRows('老王烧烤'), 1, reason: '拖到了第三家');
    await tester.dragFrom(tester.getCenter(plate), const Offset(-2, 0));
    await tester.pumpAndSettle();

    expect(recorded.propertiesOf<DishShuffleEvent>(), hasLength(2));
    await unmountApp(tester, container);
  });

  testWidgets('「不想去这家」：确认后标记，这家从转盘和列表里去掉；「算了」不发请求', (tester) async {
    env.adapter.on('POST /recommend/dismiss/1', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
    );

    await tester.tap(find.bySemanticsLabel('不想去这家'));
    await tester.pumpAndSettle();
    expect(find.text('不喜欢这家店？'), findsOneWidget);
    expect(
      find.text('袁记云饺 30 天内不会再出现在推荐里。', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text('算了'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /recommend/dismiss/1'), isEmpty);

    await tester.tap(find.bySemanticsLabel('不想去这家'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('不喜欢'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('POST /recommend/dismiss/1'), hasLength(1));
    expect(find.text('30 天内不再推荐这家店'), findsOneWidget);
    expect(find.text('袁记云饺'), findsNothing);
    expect(_offRows('一碗面'), 1, reason: '舞台停在下一家');
    await _waitToast(tester);
    await unmountApp(tester, container);
  });

  testWidgets('游客点「不想去这家」弹出登录拦截，不发请求', (tester) async {
    final (container, _) = await pumpApp(tester, env, session: const Guest());

    await tester.tap(find.bySemanticsLabel('不想去这家'));
    await tester.pumpAndSettle();

    expect(find.text('登录后才能标记不想去'), findsOneWidget);
    expect(env.adapter.sent('POST /recommend/dismiss/1'), isEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('分类栏：「甜点饮品」只换抽屉列表；专题待接入，不请求专题', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
    );
    expect(find.text('美食'), findsOneWidget);
    final turntable = env.adapter
        .sent('GET /recommend')
        .where((r) => r.query['pageSize'] == 8)
        .length;

    env.adapter.on('GET /recommend', [
      FakeAdapter.ok(feedJson([cardJson(id: 9, name: '一点点', kind: 'drink')])),
    ]);
    await tester.tap(find.text('甜点饮品'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('GET /recommend').map((r) => r.query['kind']),
      contains('drink'),
    );
    expect(find.text('一点点'), findsOneWidget);
    expect(find.text('袁记云饺'), findsOneWidget, reason: '转盘不受分类栏影响');
    expect(
      env.adapter.sent('GET /recommend').where((r) => r.query['pageSize'] == 8),
      hasLength(turntable),
    );

    await tester.tap(find.text('专题'));
    await tester.pumpAndSettle();
    expect(find.text('该功能即将上线'), findsOneWidget);
    expect(find.text('一点点'), findsOneWidget, reason: '专题没有接入，列表不变');
    expect(
      env.adapter.requests.where((r) => r.path.startsWith('/topics')),
      isEmpty,
    );
    await _waitToast(tester);
    await unmountApp(tester, container);
  });

  testWidgets('往下翻时顶栏和分类栏停在顶部；下拉刷新重新拉这一栏', (tester) async {
    env.adapter.on('GET /recommend', [
      FakeAdapter.ok(
        feedJson([
          for (var i = 1; i <= 10; i++) cardJson(id: i, name: '店$i'),
        ], hasNext: true),
      ),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
    );
    expect(find.text('美食'), findsOneWidget);

    await tester.dragFrom(const Offset(195, 700), const Offset(0, -560));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('搜索'), findsOneWidget);
    expect(tester.getTopLeft(find.bySemanticsLabel('搜索')).dy, lessThan(60));
    // 抽屉里的分类栏滚到顶栏下方后, 顶栏下面显示它的副本.
    // 列表比屏幕长, 抽屉里的分类栏会滚出屏幕, 因此只看能点到的那一个.
    double topMost() => find
        .text('美食')
        .hitTestable()
        .evaluate()
        .map((e) => tester.getTopLeft(find.byWidget(e.widget)).dy)
        .reduce((a, b) => a < b ? a : b);
    expect(topMost(), inInclusiveRange(40, 80));

    await tester.dragFrom(const Offset(195, 300), const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(find.text('美食'), findsOneWidget);
    expect(topMost(), greaterThan(400));
    final before = env.adapter.sent('GET /recommend').length;
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();
    final after = env.adapter.sent('GET /recommend').skip(before);
    expect(after.map((r) => r.query['page']), contains(1));
    expect(after.map((r) => r.query['pageSize']), everyElement(10));
    expect(
      env.adapter.sent('GET /notification/cards/unread/count'),
      hasLength(greaterThan(1)),
      reason: '刷新时顺带更新铃铛上的未读数',
    );
    await unmountApp(tester, container);
  });

  for (final (size, top) in [
    (const Size(390, 844), 47.0),
    (const Size(360, 640), 24.0),
  ]) {
    testWidgets(
      '${size.width.toInt()}×${size.height.toInt()}：盘子和文字不压到顶栏，盘子不压「就它了」「不想去这家」',
      (tester) async {
        final (container, _) = await pumpApp(
          tester,
          env,
          session: const SignedIn(user: verifiedUser),
          size: size,
        );
        useScreen(tester, size, padding: EdgeInsets.only(top: top));
        await tester.pumpAndSettle();

        final photo = tester.getRect(
          find
              .descendant(
                of: find.byType(Turntable),
                matching: find.byType(DishPlate),
              )
              .first,
        );
        final plate = photo.inflate(DishPlate.rimFor(photo.width));
        final button = tester.getRect(
          find.ancestor(of: find.text('就它了'), matching: find.byType(EatButton)),
        );
        final more = tester.getRect(find.bySemanticsLabel('不想去这家'));
        final search = tester.getRect(find.bySemanticsLabel('搜索'));
        expect(plate.bottom, lessThanOrEqualTo(math.min(button.top, more.top)));
        expect(plate.top, greaterThanOrEqualTo(search.bottom));
        final hero = tester.getRect(
          find.text(DishRules.stageLines('鲜虾蟹籽云吞').join('\n')),
        );
        expect(
          hero.top,
          greaterThanOrEqualTo(search.bottom),
          reason: '菜名不顶到顶栏',
        );
        await unmountApp(tester, container);
      },
    );
  }

  testWidgets('转到这一批的末尾前请求下一页', (tester) async {
    env.adapter.on('GET /recommend', [_feed(hasNext: true)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
    );

    await tester.tap(find.text('换一个'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('换一个'));
    await tester.pumpAndSettle();

    final turntable = env.adapter
        .sent('GET /recommend')
        .where((r) => r.query['pageSize'] == 8)
        .map((r) => r.query['page']);
    expect(turntable, [1, 2]);
    await unmountApp(tester, container);
  });

  testWidgets('一家店都没有时，舞台写「这附近还没人加过店」并给「发布一道菜」', (tester) async {
    env.adapter.on('GET /recommend', [FakeAdapter.ok(feedJson([]))]);
    await pumpApp(tester, env, session: const SignedIn(user: verifiedUser));

    expect(find.text('这附近还没人加过店，来发第一道菜'), findsOneWidget);
    expect(find.text('发布一道菜'), findsOneWidget);
    expect(find.text('还没有推荐的店'), findsOneWidget);
  });

  testWidgets('在哪吃面板：点「确定」后才生效，再点「按现在的时间」恢复', (tester) async {
    await pumpApp(tester, env, session: const SignedIn(user: verifiedUser));

    expect(find.text('在 软件园 吃 ${_mealLabel()}'), findsOneWidget);
    await tester.tap(find.textContaining('软件园'));
    await tester.pumpAndSettle();
    expect(find.text('在哪吃？'), findsOneWidget);
    expect(find.text('吃哪顿？'), findsOneWidget);
    final other = _mealLabel() == '夜宵' ? '早饭' : '夜宵';
    final api = other == '夜宵' ? 'night' : 'breakfast';
    await tester.tap(find.text(other));
    await tester.pumpAndSettle();
    expect(env.kv.values['prefs.meal'], isNull);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(find.text('在 软件园 吃 $other'), findsOneWidget);
    final meals = env.adapter
        .sent('GET /recommend')
        .map((r) => r.query['mealTime']);
    expect(meals, contains(api));
    expect(env.kv.values['prefs.meal'], startsWith('$api|'));

    await tester.tap(find.textContaining('软件园'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按现在的时间'));
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(env.kv.values['prefs.meal'], isNull);
    expect(find.text('在 软件园 吃 ${_mealLabel()}'), findsOneWidget);
  });

  testWidgets('在哪吃面板：选「点外卖」后顶栏带上外卖，按外卖重新推荐并记住', (tester) async {
    await pumpApp(tester, env, session: const SignedIn(user: verifiedUser));

    await tester.tap(find.textContaining('软件园'));
    await tester.pumpAndSettle();
    expect(find.text('怎么吃？'), findsOneWidget);
    await tester.ensureVisible(find.text('点外卖'));
    await tester.tap(find.text('点外卖'));
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('在 软件园 吃 ${_mealLabel()} · 外卖'), findsOneWidget);
    final scenes = env.adapter
        .sent('GET /recommend')
        .map((r) => r.query['scene']);
    expect(scenes, contains('delivery'));
    expect(scenes.last, 'delivery');
    expect(env.kv.values['prefs.scene'], 'delivery');
  });
}

/// 等轻提示消失. 提示的计时器未结束时卸载页面, 测试框架会报告未完成的定时器.
Future<void> _waitToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

String _mealLabel() {
  final now = DateTime.now();
  final minute = now.hour * 60 + now.minute;
  if (minute < 300) return '夜宵';
  if (minute < 630) return '早饭';
  if (minute < 870) return '午饭';
  if (minute < 1230) return '晚饭';
  return '夜宵';
}
