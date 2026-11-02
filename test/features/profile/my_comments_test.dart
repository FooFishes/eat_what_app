import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/comment_fixtures.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('「我的」评论分栏列出我写过的评论，注明审核状态，点进菜品详情', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '天凉被破王'}),
      ])
      ..on('GET /foods/my', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
      ..on('GET /foods/detail/2', [FakeAdapter.fail(40008)])
      ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())])
      ..on('GET /foods/1/comments', [
        FakeAdapter.ok(commentPageJson([commentJson(id: 11)])),
      ])
      ..on('GET /comments/11/replies', [
        FakeAdapter.ok(commentPageJson(const [])),
      ])
      ..on('GET /comments/submissions/my', [
        FakeAdapter.ok(
          commentPageJson([
            submissionJson(id: 11, text: '酸笋给得很大方'),
            submissionJson(id: 12, status: 'PENDING', text: '加了辣油更好吃'),
            submissionJson(id: 13, foodId: 2, text: '已经吃不到了'),
            submissionJson(id: 14, status: 'DELETED', text: null),
          ]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.me,
    );

    await tester.tap(find.text('评论'));
    await tester.pumpAndSettle();
    expect(find.text('酸笋给得很大方'), findsOneWidget);
    expect(find.text('加了辣油更好吃'), findsOneWidget);
    expect(find.text('审核中'), findsOneWidget);
    expect(find.text('这道菜已删除'), findsOneWidget);
    expect(find.text('鲜虾蟹籽云吞'), findsNWidgets(2));
    await expectAccessible(tester);

    await tester.tap(find.text('酸笋给得很大方'));
    await tester.pumpAndSettle();
    final page = tester.widget<DishPage>(find.byType(DishPage));
    expect((page.dishId, page.focusComment), (1, 11));
    await unmountApp(tester, container);
  });
}
