import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('没配地图 Key 时只显示列表：校区中心附近的店，按距离排', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /hub/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/search', [
        FakeAdapter.ok(
          pageJson([
            restaurantJson(id: 1, name: '远一点的店', lat: 36.6760),
            restaurantJson(id: 2, name: '近一点的店', lat: 36.6680),
          ]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.nearby,
    );

    final query = env.adapter.sent('GET /restaurant/search').last.query;
    expect(query['gcjLat'], 36.667382);
    expect(query['radius'], 3000);
    expect(find.text('附近 2 家', findRichText: true), findsOneWidget);
    final near = tester.getTopLeft(find.text('近一点的店'));
    final far = tester.getTopLeft(find.text('远一点的店'));
    expect(near.dy, lessThan(far.dy));
    await unmountApp(tester, container);
  });
}
