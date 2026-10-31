import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

const _names = ['铁锅炖', '粘豆包', '红烧肉', '酸辣粉', '烤冷面'];

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /notification/unread/count', [FakeAdapter.ok(3)])
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
    expect(find.text('¥18'), findsOneWidget);
    expect(
      env.adapter.sent('GET /foods/recommend').map((r) => r.query['campusId']),
      everyElement(1),
      reason: '校区定下来之前不拉推荐：推荐按天去重，发错的请求也会占掉菜',
    );
    expect(find.textContaining('袁记云饺 · 万达金街'), findsOneWidget);
    expect(find.bySemanticsLabel('消息，3 条未读'), findsOneWidget);
    expect(find.text('软件园 ${_mealLabel()}'), findsOneWidget);
    await expectAccessible(tester);

    // 方块里也有菜名：舞台换了以后，铁锅炖只剩方块里那个。
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

  testWidgets('点分类，抽屉里换成这个分类的推荐', (tester) async {
    await pumpApp(tester, env, session: const SignedIn(user: verifiedUser));

    await tester.tap(find.text('小吃'));
    await tester.pumpAndSettle();

    final categories = env.adapter
        .sent('GET /foods/recommend')
        .map((r) => r.query['category']);
    expect(categories, contains('snack'));
  });

  testWidgets('一道菜都没有时，舞台写「这附近还没人发过菜」并给「发布一道菜」', (tester) async {
    env.adapter.on('GET /foods/recommend', [FakeAdapter.ok(<Object>[])]);
    await pumpApp(tester, env, session: const SignedIn(user: verifiedUser));

    expect(find.text('这附近还没人发过菜，发第一道'), findsOneWidget);
    expect(find.text('发布一道菜'), findsWidgets);
  });

  testWidgets('地点和饭点面板：手动选的饭点立即生效，再点「按现在的时间」恢复', (tester) async {
    await pumpApp(tester, env, session: const SignedIn(user: verifiedUser));

    await tester.tap(find.textContaining('软件园'));
    await tester.pumpAndSettle();
    expect(find.text('在哪吃，吃哪顿'), findsOneWidget);
    final other = _mealLabel() == '夜宵' ? '早饭' : '夜宵';
    await tester.tap(find.text(other));
    await tester.pumpAndSettle();

    final meals = env.adapter
        .sent('GET /foods/recommend')
        .map((r) => r.query['mealTime']);
    expect(meals, contains(other == '夜宵' ? 'night' : 'breakfast'));
    expect(
      env.kv.values['prefs.meal'],
      startsWith(other == '夜宵' ? 'night|' : 'breakfast|'),
    );
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
