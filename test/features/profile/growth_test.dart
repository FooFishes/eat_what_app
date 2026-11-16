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
  TestEnv meEnv() {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '天凉被破王'}),
      ])
      ..on('GET /foods/my', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /user/level', [FakeAdapter.ok(growthJson())])
      ..on('GET /user/level/logs', [
        FakeAdapter.ok(
          pageJson([
            experienceJson(),
            experienceJson(id: 2, date: '2026-11-09'),
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

  testWidgets('有经验规则时列出每项的经验和每日上限，不再单独写每日经验；满级显示称号', (tester) async {
    final env = meEnv()
      ..adapter.on('GET /user/level', [
        FakeAdapter.ok(
          growthJson(
            level: 10,
            total: 16020,
            start: 16000,
            next: null,
            title: '老吃家',
            rules: [
              ruleJson('每日使用'),
              ruleJson(
                '发布菜品',
                source: 'food_published',
                amount: 15,
                dailyCap: 3,
              ),
            ],
          ),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.growth,
    );

    expect(find.text('Lv.10'), findsOneWidget);
    expect(find.text('老吃家'), findsOneWidget);
    expect(find.text('经验规则'), findsOneWidget);
    expect(find.text('发布菜品'), findsOneWidget);
    expect(find.text('每天最多 3 次'), findsOneWidget);
    expect(find.text('每天最多 1 次'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('每天第一次使用得 5 经验'), findsNothing);
    await expectAccessible(tester);
    await unmountApp(tester, container);
  });

  testWidgets('满级时写「已满级」，没有进度条', (tester) async {
    final env = meEnv()
      ..adapter.on('GET /user/level', [
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

  testWidgets('「我的」昵称旁是等级胶囊，点了进等级页；统计第一项是获赞', (tester) async {
    final env = meEnv()
      ..adapter.on('GET /user/userInfo', [
        FakeAdapter.ok({
          'displayName': '天凉被破王',
          'level': 3,
          'earnedLikes': 128,
          'fansCount': 2,
          'followingsCount': 5,
          'fansVisible': true,
          'followingsVisible': true,
        }),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.me,
    );

    expect(find.text('128'), findsOneWidget);
    expect(find.text('获赞'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('等级 3'));
    await tester.pumpAndSettle();
    expect(find.byType(GrowthPage), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('封禁中点等级弹拦截对话框，不进等级页', (tester) async {
    final env = meEnv()
      ..adapter.on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '天凉被破王', 'level': 3}),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(
        user: CurrentUser(
          id: 42,
          nickname: '天凉被破王',
          hasPassword: false,
          verified: true,
          banned: true,
          banReason: '刷赞',
        ),
      ),
      location: Paths.me,
    );

    expect(find.textContaining('账号封禁中，永久封禁，原因：刷赞'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('等级 3'));
    await tester.pumpAndSettle();
    expect(find.text('账号封禁中，暂时不能查看等级'), findsOneWidget);
    expect(find.byType(GrowthPage), findsNothing);
    expect(env.adapter.sent('GET /user/level/logs'), isEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('他人主页的等级胶囊点了没有反应', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '阿哲', 'level': 4, 'earnedLikes': 7}),
      ])
      ..on('GET /foods/by-user/9', [FakeAdapter.ok(pageJson([]))]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.user(9),
    );

    expect(find.text('Lv.4'), findsOneWidget);
    await tester.tap(find.text('Lv.4'));
    await tester.pumpAndSettle();
    expect(find.byType(GrowthPage), findsNothing);
    expect(env.adapter.sent('GET /user/level'), isEmpty);
    expect(find.text('7'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('有称号时等级胶囊里跟着称号', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({'displayName': '阿哲', 'level': 10, 'title': '老吃家'}),
      ])
      ..on('GET /foods/by-user/9', [FakeAdapter.ok(pageJson([]))]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.user(9),
    );

    expect(find.text('Lv.10 老吃家'), findsOneWidget);
    expect(find.bySemanticsLabel('等级 10，老吃家'), findsOneWidget);
    await unmountApp(tester, container);
  });
}
