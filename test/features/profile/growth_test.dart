import 'package:eat/domain/models/current_user.dart';
import 'package:eat/features/profile/growth_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';
import '../../support/growth_fixtures.dart';

void main() {
  TestEnv meEnv({int? level = 3}) {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '天凉被破王', 'level': ?level}),
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

  testWidgets('「我的」昵称旁是等级，点了进等级页：进度、规则和明细', (tester) async {
    final env = meEnv();
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.me,
    );

    expect(find.text('Lv.3'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('等级 3'));
    await tester.pumpAndSettle();

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

  testWidgets('等级页上的等级和舞台上的不一样时，回到「我的」看到新等级', (tester) async {
    final env = meEnv(level: 2)
      ..adapter.on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '天凉被破王', 'level': 2}),
        FakeAdapter.ok({'displayName': '天凉被破王', 'level': 3}),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.me,
    );
    expect(find.text('Lv.2'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('等级 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();

    expect(find.text('Lv.3'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('资料里没有等级时不显示胶囊', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      meEnv(level: null),
      session: const SignedIn(user: verifiedUser),
      location: Paths.me,
    );

    expect(find.textContaining('Lv.'), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('他人主页显示等级，点了没有反应', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '阿哲', 'level': 2}),
      ])
      ..on('GET /foods/by-user/9', [FakeAdapter.ok(pageJson([]))]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.user(9),
    );

    expect(find.text('Lv.2'), findsOneWidget);
    await tester.tap(find.text('Lv.2'));
    await tester.pumpAndSettle();
    expect(find.byType(GrowthPage), findsNothing);
    expect(env.adapter.sent('GET /user/growth'), isEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('封禁中点等级弹拦截对话框，不请求', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '天凉被破王', 'level': 3}),
      ])
      ..on('GET /foods/by-user/42', [FakeAdapter.ok(pageJson([]))]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(
        user: CurrentUser(
          id: 42,
          nickname: '天凉被破王',
          hasPassword: true,
          verified: true,
          banned: true,
          banReason: '刷赞',
        ),
      ),
      location: Paths.me,
    );

    await tester.tap(find.bySemanticsLabel('等级 3'));
    await tester.pumpAndSettle();

    expect(find.text('账号封禁中，暂时不能查看等级'), findsOneWidget);
    expect(find.byType(GrowthPage), findsNothing);
    expect(env.adapter.sent('GET /user/growth'), isEmpty);
    await unmountApp(tester, container);
  });
}
