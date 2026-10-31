import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('舞台写店名、地址和菜数；招牌是获赞最多的三道，点口味词筛菜', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())])
      ..on('GET /foods/list', [
        FakeAdapter.ok(
          pageJson([
            foodJson(
              id: 1,
              name: '虾仁云吞',
              likes: 30,
              systemTags: [
                {'id': 3, 'name': '皮薄', 'count': 5, 'taggedByMe': false},
              ],
            ),
            foodJson(id: 2, name: '牛肉饺子', likes: 20),
            foodJson(id: 3, name: '紫菜汤', likes: 2),
            foodJson(id: 4, name: '煎饺', likes: 9),
          ]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.shop(7),
    );

    expect(find.text('袁记云饺'), findsOneWidget);
    expect(find.text('4 道菜'), findsOneWidget);
    expect(find.text('招牌'), findsOneWidget);
    expect(find.text('导航去店里'), findsOneWidget);
    final sent = env.adapter.sent('GET /foods/list').single.query;
    expect(sent, containsPair('restaurantId', 7));
    expect(sent, containsPair('sort', 'POPULAR'));
    await expectAccessible(tester);

    await tester.scrollUntilVisible(
      find.text('皮薄'),
      200,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    await tester.tap(find.text('皮薄'));
    await tester.pumpAndSettle();
    expect(find.text('紫菜汤'), findsNothing, reason: '只看带「皮薄」的菜');
    await unmountApp(tester, container);
  });
}
