import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/features/profile/user_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

/// `/user/userInfo` 的响应数据样例.
Map<String, Object?> _profile({
  String name = '阿哲',
  int fans = 56,
  bool fansVisible = true,
  bool followsMe = false,
  bool followedByMe = false,
}) => {
  'displayName': name,
  'avatar': null,
  'earnedLikes': 312,
  'fansCount': fans,
  'followingsCount': 21,
  'fansVisible': fansVisible,
  'followingsVisible': true,
  'isFollowingMe': followsMe,
  'isFollowingHim': followedByMe,
  'uploadedRestaurantsCount': 0,
  'uploadedFoodsCount': 1,
};

/// 文字为 [label] 的 [EatButton]. 舞台上的统计也显示 "关注", 按文字查找会同时命中统计.
Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is EatButton && w.label == label);

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /foods/by-user/9', [
        FakeAdapter.ok(pageJson([foodJson(name: '柳州螺蛳粉', likes: 96)])),
      ])
      ..on('GET /user/blocks/9', [
        FakeAdapter.ok({'blocked': false}),
      ]);
  });

  testWidgets('他人主页：对方关注了我时显示「回关」，回关后变「已互关」，粉丝数跟着变', (tester) async {
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok(_profile(followsMe: true)),
        FakeAdapter.ok(_profile(fans: 57, followsMe: true, followedByMe: true)),
      ])
      ..on('POST /user/follow', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.user(9),
    );

    expect(find.byType(UserPage), findsOneWidget);
    expect(find.text('阿哲'), findsWidgets);
    expect(find.text('56'), findsOneWidget);
    expect(find.text('柳州螺蛳粉'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('回关'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /user/follow').single.query,
      containsPair('userId', 9),
    );
    expect(find.text('已互关'), findsOneWidget);
    expect(find.text('57'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点「关注」弹拦截对话框，不发请求', (tester) async {
    env.adapter.on('GET /user/userInfo', [FakeAdapter.ok(_profile())]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.user(9),
    );

    await tester.tap(_button('关注'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能关注'), findsOneWidget);
    expect(env.adapter.sent('POST /user/follow'), isEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('关注失败时按钮退回原样并提示', (tester) async {
    env.adapter
      ..on('GET /user/userInfo', [FakeAdapter.ok(_profile())])
      ..on('POST /user/follow', [const FakeResponse.offline()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.user(9),
    );

    await tester.tap(_button('关注'));
    await tester.pumpAndSettle();
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    expect(_button('关注'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('从「更多」屏蔽：确认后发请求，舞台下提示已屏蔽', (tester) async {
    env.adapter
      ..on('GET /user/userInfo', [FakeAdapter.ok(_profile())])
      ..on('PUT /user/blocks/9', [
        FakeAdapter.ok({'blocked': true}),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.user(9),
    );

    await tester.tap(find.bySemanticsLabel('更多'));
    await tester.pumpAndSettle();
    expect(find.text('举报'), findsOneWidget);
    await tester.tap(find.text('屏蔽'));
    await tester.pumpAndSettle();
    expect(find.text('屏蔽「阿哲」？'), findsOneWidget);
    await tester.tap(find.text('屏蔽'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('PUT /user/blocks/9'), hasLength(1));
    expect(find.text('你已屏蔽对方'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('对方没公开粉丝列表时写「对方没有公开」，不请求列表', (tester) async {
    env.adapter.on('GET /user/userInfo', [
      FakeAdapter.ok(_profile(fansVisible: false)),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.follows(9, fans: true),
    );
    // 页面栈中列表页之下是对方主页. 主页在最后一帧发出上传列表的请求, pumpAndSettle 等待该请求完成.
    await tester.pumpAndSettle();

    expect(find.text('阿哲的粉丝和关注'), findsOneWidget);
    expect(find.text('对方未公开'), findsOneWidget);
    expect(find.text('「阿哲」未公开粉丝列表'), findsOneWidget);
    expect(env.adapter.sent('GET /user/followers'), isEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('我的关注列表：每行按关系显示按钮，点行进他人主页', (tester) async {
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok(_profile(name: '天凉被破王')),
        FakeAdapter.ok(_profile(followedByMe: true)),
      ])
      ..on('GET /user/followings', [
        FakeAdapter.ok(
          pageJson([
            {'id': 9, 'displayName': '阿哲', 'avatar': null, 'createdAt': 1},
          ]),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.follows(42, fans: false),
    );
    // 列表显示后, 每一行请求对应用户的资料. pumpAndSettle 等待这些请求完成.
    await tester.pumpAndSettle();

    expect(find.text('粉丝和关注'), findsOneWidget);
    expect(find.text('已关注'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('阿哲'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is UserPage && w.userId == 9),
      findsOneWidget,
    );
    await unmountApp(tester, container);
  });
}
