import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('舞台上是获赞最多的菜、昵称和统计；没认证时提示去认证', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({
          'displayName': '天凉被破王',
          'avatar': null,
          'earnedLikes': 128,
          'fansCount': 3,
          'followingsCount': 5,
          'fansVisible': true,
          'followingsVisible': true,
          'isFollowingMe': false,
          'isFollowingHim': false,
          'uploadedRestaurantsCount': 1,
          'uploadedFoodsCount': 2,
        }),
      ])
      ..on('GET /foods/my', [
        FakeAdapter.ok(
          pageJson([
            foodJson(id: 1, name: '虾仁云吞', likes: 30, stageColor: 'chili'),
            foodJson(id: 2, name: '紫菜汤', likes: 2),
          ]),
        ),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.me,
    );

    expect(find.text('天凉被破王'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('认证后可以发布和互动'), findsOneWidget);
    expect(find.text('虾仁云吞'), findsOneWidget);
    expect(
      env.adapter.sent('GET /user/userInfo').single.query,
      containsPair('userId', 42),
    );
    await expectAccessible(tester);
  });
}
