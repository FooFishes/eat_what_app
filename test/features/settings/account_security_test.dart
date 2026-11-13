import 'package:eat/core/network/auth_token.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/features/auth/login_page.dart';
import 'package:eat/features/settings/phone_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

const _token = AuthToken(name: 'satoken', value: 'old');

const _user = CurrentUser(
  id: 42,
  nickname: '天凉被破王',
  phone: '13812345678',
  hasPassword: true,
  verified: true,
  banned: false,
);

/// 文字为 [label] 的 [EatButton]. 页面标题与按钮同名时, 按文字查找会同时命中标题.
Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is EatButton && w.label == label);

/// 换发会话的结果样例.
Map<String, Object?> _outcome(String status) => {
  'commandId': 'c-1',
  'status': status,
  'tokenName': 'satoken',
  'tokenValue': 'new',
  'loginId': '42',
  'device': 'IOS',
  'expiresInSeconds': 3600,
  'restricted': false,
};

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  testWidgets('登录设备：这台排最前，可以让一台下线', (tester) async {
    env.adapter
      ..on('GET /auth/sessions', [
        FakeAdapter.ok({
          'devices': [
            {
              'sessionId': 's-web',
              'device': 'WEB',
              'issuedAt': '2026-11-01T10:00:00Z',
              'lastSeenAt': '2026-11-01T12:00:00Z',
              'expiresAt': '2026-12-01T10:00:00Z',
              'current': false,
            },
            {
              'sessionId': 's-me',
              'device': 'IOS',
              'issuedAt': null,
              'lastSeenAt': null,
              'expiresAt': '2026-12-01T10:00:00Z',
              'current': true,
            },
          ],
          'nextCursor': null,
        }),
      ])
      ..on('DELETE /auth/sessions/s-web', [
        FakeAdapter.ok({'commandId': null, 'status': 'PENDING'}),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _user),
      location: Paths.settingsDevices,
    );

    expect(find.text('当前设备'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('iPhone')).dy,
      lessThan(tester.getTopLeft(find.text('网页版')).dy),
    );
    expect(find.text('待接入'), findsNothing);
    await expectAccessible(tester);

    await tester.tap(_button('下线'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE /auth/sessions/s-web'), hasLength(1));
    expect(find.text('网页版'), findsNothing);
    expect(find.text('仅当前设备登录'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('让其他设备都下线：本机换成新会话，不用重新登录', (tester) async {
    env.adapter
      ..on('GET /auth/sessions', [
        FakeAdapter.ok({
          'devices': [
            {'sessionId': 's-me', 'device': 'IOS', 'current': true},
            {'sessionId': 's-web', 'device': 'WEB', 'current': false},
          ],
          'nextCursor': null,
        }),
        FakeAdapter.ok({
          'devices': [
            {'sessionId': 's-me', 'device': 'IOS', 'current': true},
          ],
          'nextCursor': null,
        }),
      ])
      ..on('POST /auth/sessions/revoke-others', [
        FakeAdapter.ok({'commandId': 'c-1', 'status': 'PENDING'}),
      ])
      ..onPattern(RegExp(r'^POST /auth/sessions/[^/]+/resume$'), [
        FakeAdapter.ok(_outcome('COMMITTED')),
        FakeAdapter.ok(_outcome('READY')),
      ])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson(verified: true))]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _user),
      token: _token,
      location: Paths.settingsDevices,
    );

    await tester.tap(_button('下线其他设备'));
    await tester.pumpAndSettle();
    await tester.tap(_button('全部下线'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final revoke = env.adapter.sent('POST /auth/sessions/revoke-others').single;
    final body = revoke.body! as Map<String, dynamic>;
    final commandId = body['commandId'] as String;
    expect(body['recoveryCapability'], hasLength(43));
    expect(revoke.headers['satoken'], 'Bearer old');

    final resumes = env.adapter.sent('POST /auth/sessions/$commandId/resume');
    expect(resumes, hasLength(2));
    expect(
      resumes.first.headers['X-Recovery-Capability'],
      body['recoveryCapability'],
    );
    expect(env.secure.values['auth.tokenValue'], 'new');
    expect(container.read(sessionProvider), isA<SignedIn>());
    expect(find.text('其他设备已下线'), findsOneWidget);
    expect(find.text('仅当前设备登录'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('通知：各栏目的开关读自服务端，开启时回传版本信息', (tester) async {
    env.adapter
      ..on('GET /push/settings', [
        FakeAdapter.ok([
          {
            'category': 'COMMENTS',
            'enabled': true,
            'revision': 3,
            'closeFrontier': null,
          },
          {
            'category': 'FOLLOWS',
            'enabled': false,
            'revision': 5,
            'closeFrontier': 'f-1',
          },
        ]),
      ])
      ..on('POST /push/settings/enable', [
        FakeAdapter.ok({'state': 'ENABLED'}),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _user),
      location: Paths.settingsNotify,
    );

    bool on(String label) =>
        tester.widget<EatSwitch>(find.widgetWithText(EatSwitch, label)).value;
    expect(on('评论和回复'), isTrue);
    expect(on('关注'), isFalse);
    expect(on('系统消息'), isTrue);
    expect(find.text('待接入'), findsNothing);
    await expectAccessible(tester);

    await tester.tap(find.text('关注'));
    await tester.pumpAndSettle();
    final body =
        env.adapter.sent('POST /push/settings/enable').single.body!
            as Map<String, dynamic>;
    expect(body['operation'], 'ENABLE');
    expect(body['category'], 'FOLLOWS');
    expect(body['expectedPreferenceRevision'], 5);
    expect(body['observedCloseFrontier'], 'f-1');
    expect(body['commandId'], isA<String>());
  });

  testWidgets('换绑手机：验证新号码和旧手机，提交后本机换成新会话', (tester) async {
    env.adapter
      ..on('GET /auth/captcha/config', [
        FakeAdapter.ok({'enabled': false}),
      ])
      ..on('POST /user/mobile/commands', [
        FakeAdapter.ok({
          'commandId': 'm-1',
          'expiresAt': '2026-11-02T12:00:00Z',
          'oldProofRequired': true,
        }),
      ])
      ..on('POST /user/mobile/commands/m-1/codes', [
        FakeAdapter.ok({
          'challengeId': 'ch',
          'expiresAt': '2026-11-02T12:00:00Z',
          'attempted': true,
        }),
      ])
      ..on('POST /user/mobile/commands/m-1/commit', [
        FakeAdapter.ok({
          'commandId': 'm-1',
          'credentialPropagation': 'APPLIED',
          'currentDevice': 'READY',
          'replacement': _outcome('READY'),
        }),
      ])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson(verified: true))]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _user),
      token: _token,
      location: Paths.settingsAccount,
    );

    await tester.tap(find.text('手机号'));
    await tester.pumpAndSettle();
    expect(find.byType(PhonePage), findsOneWidget);
    await expectAccessible(tester);

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), '13900001111');
    await tester.pump();
    await tester.tap(_button('获取验证码'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /user/mobile/commands').single.body, {
      'commandId': isA<String>(),
      'mobile': '13900001111',
    });
    expect(
      env.adapter.sent('POST /user/mobile/commands/m-1/codes').single.body,
      {'type': 'NEW_PHONE'},
    );
    expect(find.text('确认是你本人'), findsOneWidget);

    await tester.enterText(fields.at(1), '111111');
    await tester.pump();
    await tester.tap(_button('获取验证码'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /user/mobile/commands/m-1/codes').last.body, {
      'type': 'OLD_PHONE',
    });
    await tester.enterText(fields.at(2), '222222');
    await tester.pump();
    await tester.tap(_button('换绑'));
    await tester.pumpAndSettle();

    final commit =
        env.adapter.sent('POST /user/mobile/commands/m-1/commit').single.body!
            as Map<String, dynamic>;
    expect(commit['newCode'], '111111');
    expect(commit['oldCode'], '222222');
    expect(commit.containsKey('password'), isFalse);
    expect(commit['recoveryCapability'], hasLength(43));
    expect(env.secure.values['auth.tokenValue'], 'new');
    expect(find.byType(PhonePage), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('换绑手机后没能取回新会话：回到登录页', (tester) async {
    env.adapter
      ..on('GET /auth/captcha/config', [
        FakeAdapter.ok({'enabled': false}),
      ])
      ..on('POST /user/mobile/commands', [
        FakeAdapter.ok({'commandId': 'm-1', 'oldProofRequired': false}),
      ])
      ..on('POST /user/mobile/commands/m-1/codes', [FakeAdapter.ok({})])
      ..on('POST /user/mobile/commands/m-1/commit', [
        FakeAdapter.ok({
          'commandId': 'm-1',
          'credentialPropagation': 'PENDING',
          'currentDevice': 'REAUTHENTICATION_REQUIRED',
          'replacement': null,
        }),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _user),
      token: _token,
      location: Paths.settingsPhone,
    );

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), '13900001111');
    await tester.pump();
    await tester.tap(_button('获取验证码'));
    await tester.pumpAndSettle();
    expect(find.text('确认是你本人'), findsNothing);
    await tester.enterText(fields.at(1), '111111');
    await tester.pump();
    await tester.tap(_button('换绑'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(env.secure.values.keys, isNot(contains('auth.tokenValue')));
    await tester.pump(const Duration(seconds: 2));
  });
}
