import 'package:eat/features/profile/growth_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';
import '../../support/growth_fixtures.dart';

void main() {
  TestEnv meEnv() {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '天凉被破王'}),
      ])
      ..on('GET /foods/my', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /user/growth', [FakeAdapter.ok(growthJson())])
      ..on('GET /user/growth/ledger', [
        FakeAdapter.ok(
          pageJson([
            experienceJson(),
            experienceJson(id: 'e-2', date: '2026-11-09'),
          ]),
        ),
      ]);
    return env;
  }

  testWidgets('等级页：进度、规则和明细', (tester) async {
    final env = meEnv();
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.growth,
    );

    expect(find.byType(GrowthPage), findsOneWidget);
    expect(find.text('累计 125 经验'), findsOneWidget);
    expect(find.text('距 Lv.4 还差 125 经验'), findsOneWidget);
    expect(find.text('每天第一次使用得 5 经验'), findsOneWidget);
    expect(find.text('每日使用'), findsNWidgets(2));
    expect(find.textContaining('11 月 10 日'), findsOneWidget);
    expect(find.text('+5'), findsNWidgets(2));
    await expectAccessible(tester);
    await unmountApp(tester, container);
  });

  testWidgets('满级时写「已满级」，没有进度条', (tester) async {
    final env = meEnv()
      ..adapter.on('GET /user/growth', [
        FakeAdapter.ok(
          growthJson(level: 10, total: 16020, start: 16000, next: null),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.growth,
    );

    expect(find.text('已满级'), findsOneWidget);
    expect(find.bySemanticsLabel('本级进度'), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('他人主页不显示等级胶囊', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '阿哲'}),
      ])
      ..on('GET /foods/by-user/9', [FakeAdapter.ok(pageJson([]))]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.user(9),
    );

    expect(find.textContaining('Lv.'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('^等级')), findsNothing);
    expect(env.adapter.sent('GET /user/growth'), isEmpty);
    await unmountApp(tester, container);
  });
}
