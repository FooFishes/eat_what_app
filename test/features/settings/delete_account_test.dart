import 'package:eat/core/network/auth_token.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

const _token = AuthToken(name: 'satoken', value: 'tk');

/// 文字为 [label] 的 [EatButton]. 页面标题与按钮同名时, 按文字查找会同时命中标题.
Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is EatButton && w.label == label);

Map<String, Object?> _preparing() => FakeAdapter.ok({
  'requestId': 'r',
  'phase': 'PREPARING',
  'deadline': '2026-11-18T08:00:00Z',
  'complete': false,
});

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter.on('POST /auth/logout', [FakeAdapter.ok()]);
  });

  testWidgets('默认保留评论；确认后提交申请、存下凭据并退出登录', (tester) async {
    env.adapter.on('POST /user/cancellation', [_preparing()]);
    final (_, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      token: _token,
      location: Paths.settingsDelete,
    );

    expect(find.text('待接入'), findsNothing);
    expect(find.text('若不删除，内容将保留，作者显示为「已注销用户」'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(_button('申请注销'));
    await tester.pumpAndSettle();
    expect(find.text('注销账号？'), findsOneWidget);
    expect(find.text('7 天内在当前设备重新登录可撤销。'), findsOneWidget);
    await tester.tap(_button('注销'));
    await tester.pumpAndSettle();

    final sent = env.adapter.sent('POST /user/cancellation').single;
    final body = sent.body! as Map<String, Object?>;
    expect(body['deletePostsAndComments'], false);
    expect(
      env.secure.values['lifecycle.recovery.${body['requestId']}'],
      body['recoveryCapability'],
    );
    expect(env.adapter.sent('POST /auth/logout'), hasLength(1));
    expect(locationOf(router), startsWith(Paths.login));
    expect(find.text('已申请注销，7 天内重新登录可以撤销'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('选了删除评论时确认对话框写明，请求带上选择', (tester) async {
    env.adapter.on('POST /user/cancellation', [_preparing()]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      token: _token,
      location: Paths.settingsDelete,
    );

    await tester.tap(find.text('同时删除我的评论和回复'));
    await tester.pump();
    expect(find.text('评论和回复会一起删除'), findsOneWidget);
    await tester.tap(_button('申请注销'));
    await tester.pumpAndSettle();
    expect(find.text('7 天内在当前设备重新登录可撤销。评论和回复将一并删除。'), findsOneWidget);
    await tester.tap(_button('注销'));
    await tester.pumpAndSettle();

    expect(
      env.adapter.sent('POST /user/cancellation').single.body,
      containsPair('deletePostsAndComments', true),
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('取消确认不发请求；申请失败留在本页，重试沿用同一份申请', (tester) async {
    env.adapter.on('POST /user/cancellation', [
      const FakeResponse.offline(),
      _preparing(),
    ]);
    final (_, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      token: _token,
      location: Paths.settingsDelete,
    );

    await tester.tap(_button('申请注销'));
    await tester.pumpAndSettle();
    await tester.tap(_button('取消'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /user/cancellation'), isEmpty);

    await tester.tap(_button('申请注销'));
    await tester.pumpAndSettle();
    await tester.tap(_button('注销'));
    await tester.pumpAndSettle();
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    expect(locationOf(router), Paths.settingsDelete);
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(_button('申请注销'));
    await tester.pumpAndSettle();
    await tester.tap(_button('注销'));
    await tester.pumpAndSettle();
    final bodies = [
      for (final r in env.adapter.sent('POST /user/cancellation')) r.body,
    ];
    expect(bodies, hasLength(2));
    expect(bodies.first, bodies.last);
    expect(locationOf(router), startsWith(Paths.login));
    await tester.pump(const Duration(seconds: 3));
  });
}
