import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/features/topic/topic_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';
import '../../support/topic_json.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /topics/7', [FakeAdapter.ok(topicDetailJson())]);
  });

  testWidgets('专题页写名字、介绍、起止时间和菜数，点菜进菜品详情', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.topic(7),
    );

    expect(find.text('期末续命餐'), findsOneWidget);
    expect(find.text('复习到半夜，来点热的。'), findsOneWidget);
    expect(find.text('本周专题'), findsOneWidget);
    expect(find.textContaining(' 道菜', findRichText: true), findsOneWidget);
    expect(find.text('柳州螺蛳粉'), findsOneWidget);
    expect(find.text('东北饭庄'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('铁锅炖大鹅'));
    await tester.pumpAndSettle();
    final page = tester.widget<DishPage>(find.byType(DishPage));
    expect(page.dishId, 2);
    expect(page.initial?.name, '铁锅炖大鹅');
    await unmountApp(tester, container);
  });

  testWidgets('专题不存在或尚未开始时说明，不给重试', (tester) async {
    env.adapter.on('GET /topics/9', [FakeAdapter.fail(40002, '专题不存在或尚未开始')]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.topic(9),
    );

    expect(find.text('找不到这期专题'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('往期专题按校区列出，每行带前三道菜，点进专题页', (tester) async {
    env.adapter.on('GET /topics/history', [
      FakeAdapter.ok(
        pageJson([
          topicJson(
            id: 7,
            startsAt: DateTime(2026, 10, 13),
            endsAt: DateTime(2026, 10, 20),
          ),
        ]),
      ),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.topics,
    );

    expect(find.textContaining('往期专题'), findsOneWidget);
    expect(find.text('「期末续命餐」'), findsOneWidget);
    expect(find.textContaining('10 月 13 日–'), findsOneWidget);
    expect(
      env.adapter.sent('GET /topics/history').single.query,
      containsPair('campusId', 1),
    );
    await expectAccessible(tester);

    await tester.tap(find.text('「期末续命餐」'));
    await tester.pumpAndSettle();
    expect(tester.widget<TopicPage>(find.byType(TopicPage)).topicId, 7);
    expect(
      env.adapter.sent('GET /topics/7'),
      hasLength(1),
      reason: '列表行已经拉过详情，进专题页不重新请求',
    );
    await unmountApp(tester, container);
  });

  testWidgets('菜品详情不请求专题，也不显示「收进了本周专题」', (tester) async {
    env.adapter
      ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
      ..on('GET /topics/by-food/1', [
        FakeAdapter.ok([topicJson()]),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    expect(find.textContaining('收进了'), findsNothing);
    expect(env.adapter.sent('GET /topics/by-food/1'), isEmpty);
    await unmountApp(tester, container);
  });
}
