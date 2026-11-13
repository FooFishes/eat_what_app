import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/features/topic/topic_archive_page.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';
import '../../support/topic_json.dart';

const _names = ['铁锅炖', '粘豆包', '红烧肉', '酸辣粉', '烤冷面'];

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /notification/cards/unread/count', [
        FakeAdapter.ok({'cards': 3, 'members': 5}),
      ])
      ..on('GET /topics/current', [FakeAdapter.ok()])
      ..on('GET /foods/recommend', [
        FakeAdapter.ok([
          for (final (i, name) in _names.indexed)
            foodJson(id: i + 1, name: name, recommend: true),
        ]),
      ]);
  });

  testWidgets('舞台上是推荐的第一道菜；「换一个」转到下一道，「就它了」进菜品详情', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
    );

    expect(find.text('铁锅炖'), findsNWidgets(2));
    // 舞台上的大号价格一处, 抽屉里已经排出来的方块菜名右边各一处.
    expect(find.text('¥18'), findsAtLeast(2));
    expect(
      env.adapter.sent('GET /foods/recommend').map((r) => r.query['campusId']),
      everyElement(1),
      reason: '校区定下来之前不拉推荐：推荐按天去重，发错的请求也会占掉菜',
    );
    expect(find.textContaining('袁记云饺  万达金街'), findsOneWidget);
    expect(find.bySemanticsLabel('消息，3 条未读'), findsOneWidget);
    expect(find.text('在 软件园 吃 ${_mealLabel()}'), findsOneWidget);
    await expectAccessible(tester);

    // 菜名同时出现在舞台和推荐流方块中.
    // 换菜后, 新菜 "粘豆包" 出现两处, 原先的 "铁锅炖" 只剩方块中的一处.
    expect(find.text('粘豆包'), findsOneWidget);
    await tester.tap(find.text('换一个'));
    await tester.pumpAndSettle();
    expect(find.text('粘豆包'), findsNWidgets(2));
    expect(find.text('铁锅炖'), findsOneWidget);

    await tester.tap(find.text('就它了'));
    await tester.pumpAndSettle();
    final page = tester.widget<DishPage>(find.byType(DishPage));
    expect(page.dishId, 2);
    expect(page.initial?.name, '粘豆包', reason: '舞台先用手上的那道菜画出来');
    await unmountApp(tester, container);
  });

  testWidgets('往下翻时顶栏和分类栏停在顶部；下拉刷新重新拉这一栏', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
    );
    expect(find.text('今日推荐'), findsOneWidget);
    expect(find.text('袁记云饺'), findsWidgets, reason: '方块第二行写店名');

    await tester.dragFrom(const Offset(195, 700), const Offset(0, -560));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('搜索'), findsOneWidget);
    expect(tester.getTopLeft(find.bySemanticsLabel('搜索')).dy, lessThan(60));
    // 抽屉里的分类栏滚到顶栏下方后, 顶栏下面显示它的副本.
    double topMost() => find
        .text('今日推荐')
        .evaluate()
        .map((e) => tester.getTopLeft(find.byWidget(e.widget)).dy)
        .reduce((a, b) => a < b ? a : b);
    expect(topMost(), inInclusiveRange(40, 80));

    await tester.dragFrom(const Offset(195, 300), const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(find.text('今日推荐'), findsOneWidget);
    expect(topMost(), greaterThan(400));
    final before = env.adapter.sent('GET /foods/recommend').length;
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();
    // 重新请求第一批后, 列表末尾的分页触发器会接着请求下一批, 因此不止多一次.
    expect(
      env.adapter.sent('GET /foods/recommend').length,
      greaterThan(before),
    );
    expect(
      env.adapter.sent('GET /notification/cards/unread/count'),
      hasLength(greaterThan(1)),
      reason: '刷新时顺带更新铃铛上的未读数',
    );
    await unmountApp(tester, container);
  });

  testWidgets('点分类，抽屉里换成这个分类的推荐', (tester) async {
    await pumpApp(tester, env, session: const SignedIn(user: verifiedUser));

    await tester.tap(find.text('小吃'));
    await tester.pumpAndSettle();

    final categories = env.adapter
        .sent('GET /foods/recommend')
        .map((r) => r.query['category']);
    expect(categories, contains('snack'));
  });

  testWidgets('没有当期专题时分类栏不显示专题', (tester) async {
    await pumpApp(tester, env, session: const SignedIn(user: verifiedUser));

    expect(find.text('今日推荐'), findsOneWidget);
    expect(find.text('期末续命餐'), findsNothing);
    expect(
      env.adapter.sent('GET /topics/current').map((r) => r.query['campusId']),
      everyElement(1),
    );
  });

  testWidgets('有当期专题时紧跟「今日推荐」；选中后列出介绍、专题里的菜和「往期专题」', (tester) async {
    env.adapter
      ..on('GET /topics/current', [FakeAdapter.ok(topicJson())])
      ..on('GET /topics/7', [FakeAdapter.ok(topicDetailJson())])
      ..on('GET /topics/history', [
        FakeAdapter.ok(pageJson([topicJson(id: 3, name: '降温了喝碗汤')])),
      ])
      ..on('GET /topics/3', [FakeAdapter.ok(topicDetailJson())]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
    );

    final tabs = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((d) => d == '今日推荐' || d == '期末续命餐' || d == '主食')
        .toList();
    expect(tabs, ['今日推荐', '期末续命餐', '主食']);

    await tester.tap(find.text('期末续命餐'));
    await tester.pumpAndSettle();
    expect(find.text('复习到半夜，来点热的。'), findsOneWidget);
    expect(find.textContaining('本周专题，'), findsOneWidget);
    await tester.ensureVisible(find.text('往期专题'));
    await tester.pumpAndSettle();
    expect(find.text('柳州螺蛳粉'), findsWidgets);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    // 往期专题页的请求分两轮: 首轮请求列表, 列表返回后逐行请求专题详情.
    // 两轮请求都在当前帧之后发出, 单独调用 pumpAndSettle 等不到这些请求.
    await tester.tap(find.text('往期专题'));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();
    expect(find.byType(TopicArchivePage), findsOneWidget);
    expect(find.text('「降温了喝碗汤」'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('一道菜都没有时，舞台写「这附近还没人发过菜」并给「发布一道菜」', (tester) async {
    env.adapter.on('GET /foods/recommend', [FakeAdapter.ok(<Object>[])]);
    await pumpApp(tester, env, session: const SignedIn(user: verifiedUser));

    expect(find.text('这附近还没人发过菜，来发第一道'), findsOneWidget);
    expect(find.text('加一道菜'), findsWidgets);
  });

  testWidgets('地点和饭点面板：点「确定」后才生效，再点「按现在的时间」恢复', (tester) async {
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
        .sent('GET /foods/recommend')
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
