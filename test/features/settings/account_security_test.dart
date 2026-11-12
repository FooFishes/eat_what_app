import 'package:clock/clock.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/features/settings/phone_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
);

/// 文字为 [label] 的 [EatButton]. 页面标题与按钮同名时, 按文字查找会同时命中标题.
Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is EatButton && w.label == label);

Map<String, Object?> get _captchaOff => FakeAdapter.ok({'enabled': false});

Future<void> _type(WidgetTester tester, String label, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.widgetWithText(EatFormField, label),
      matching: find.byType(EditableText),
    ),
    text,
  );
  await tester.pump();
}

/// 点 [label] 输入框右侧的 "获取验证码".
Future<void> _sendCode(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.widgetWithText(EatFormField, label),
      matching: _button('获取验证码'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  testWidgets('登录设备：这台排最前，显示登录时间，可以让一台下线', (tester) async {
    // 页面按 clock 计算相对时间. testWidgets 的 clock 是模拟时钟, 与 DateTime.now() 不同步.
    final signedIn = clock.now().toUtc().subtract(const Duration(minutes: 10));
    env.adapter
      ..on('GET /auth/sessions', [
        FakeAdapter.ok({
          'devices': [
            {
              'sessionId': 's-web',
              'device': 'WEB',
              'issuedAt': signedIn.toIso8601String(),
              'expiresAt': '2026-12-01T10:00:00Z',
              'current': false,
            },
            {
              'sessionId': 's-me',
              'device': 'IOS',
              'issuedAt': null,
              'expiresAt': '2026-12-01T10:00:00Z',
              'current': true,
            },
          ],
          'nextCursor': null,
        }),
      ])
      ..on('DELETE /auth/sessions/s-web', [FakeAdapter.ok()]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _user),
      location: Paths.settingsDevices,
    );

    expect(find.text('当前设备'), findsOneWidget);
    expect(find.text('10 分钟前登录'), findsOneWidget);
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

  testWidgets('要下线的设备已经不在了：照样从列表移除', (tester) async {
    env.adapter
      ..on('GET /auth/sessions', [
        FakeAdapter.ok({
          'devices': [
            {'sessionId': 's-me', 'device': 'ANDROID', 'current': true},
            {'sessionId': 's-web', 'device': 'WEB', 'current': false},
          ],
          'nextCursor': null,
        }),
      ])
      ..on('DELETE /auth/sessions/s-web', [FakeAdapter.fail(40001)]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _user),
      location: Paths.settingsDevices,
    );

    await tester.tap(_button('下线'));
    await tester.pumpAndSettle();
    expect(find.text('网页版'), findsNothing);
    expect(find.text('操作失败，请重试'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('让其他设备都下线：本机会话不变，只刷新列表', (tester) async {
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
      ..on('POST /auth/sessions/revoke-others', [FakeAdapter.ok()]);
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
    await tester.pumpAndSettle();
    final revoke = env.adapter.sent('POST /auth/sessions/revoke-others').single;
    expect(revoke.body, isNull);
    expect(revoke.headers['satoken'], 'Bearer old');
    expect(env.adapter.sent('GET /auth/sessions'), hasLength(2));
    expect(env.secure.values['auth.tokenValue'], 'old');
    expect(container.read(sessionProvider), isA<SignedIn>());
    expect(find.text('其他设备已下线'), findsOneWidget);
    expect(find.text('仅当前设备登录'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('通知：各栏目的开关读自服务端，开关只带栏目，采用返回的开关表', (tester) async {
    env.adapter
      ..on('GET /push/settings', [
        FakeAdapter.ok({
          'categories': {'COMMENTS': true, 'FOLLOWS': false},
        }),
      ])
      ..on('POST /push/settings/enable', [
        FakeAdapter.ok({
          'categories': {
            'COMMENTS': true,
            'LIKES_AND_FAVORITES': true,
            'FOLLOWS': true,
            'SYSTEM': false,
          },
        }),
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
    final body = env.adapter.sent('POST /push/settings/enable').single.body;
    expect(body, {'category': 'FOLLOWS'});
    expect(on('关注'), isTrue);
    expect(on('系统消息'), isFalse);
  });

  group('换绑手机', () {
    setUp(() {
      env.adapter
        ..on('GET /auth/captcha/config', [_captchaOff])
        ..on('POST /user/mobile/change/old-code', [FakeAdapter.ok()])
        ..on('GET /user/info', [FakeAdapter.ok(userInfoJson(verified: true))]);
    });

    Future<ProviderContainer> openPhone(WidgetTester tester) async {
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
      return container;
    }

    /// 第一步: 给当前号码发码并填好, 进入第二步.
    Future<void> verifyOld(
      WidgetTester tester, [
      String code = '111111',
    ]) async {
      await _sendCode(tester, '验证码');
      await _type(tester, '验证码', code);
      await tester.tap(_button('下一步'));
      await tester.pumpAndSettle();
    }

    testWidgets('先验证当前号码，再验证新号码，提交后本机保持登录', (tester) async {
      env.adapter
        ..on('POST /user/mobile/change/new-code', [FakeAdapter.ok()])
        ..on('POST /user/mobile/change/commit', [FakeAdapter.ok()]);
      final container = await openPhone(tester);
      expect(find.text('先验证现在绑定的手机'), findsOneWidget);
      expect(find.text('验证码发到 138 **** 5678'), findsOneWidget);
      await expectAccessible(tester);

      await verifyOld(tester);
      expect(
        env.adapter.sent('POST /user/mobile/change/old-code'),
        hasLength(1),
      );
      expect(find.text('新手机号'), findsOneWidget);

      await _type(tester, '新手机号', '13900001111');
      await _sendCode(tester, '新手机验证码');
      expect(
        env.adapter.sent('POST /user/mobile/change/new-code').single.body,
        {'oldCode': '111111', 'mobile': '13900001111'},
      );

      await _type(tester, '新手机验证码', '222222');
      await tester.tap(_button('换绑'));
      await tester.pumpAndSettle();
      expect(env.adapter.sent('POST /user/mobile/change/commit').single.body, {
        'mobile': '13900001111',
        'code': '222222',
      });
      expect(env.secure.values['auth.tokenValue'], 'old');
      expect(container.read(sessionProvider), isA<SignedIn>());
      expect(find.byType(PhonePage), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await unmountApp(tester, container);
    });

    testWidgets('当前号码的验证码不对：回到第一步提示', (tester) async {
      env.adapter.on('POST /user/mobile/change/new-code', [
        FakeAdapter.fail(30005),
      ]);
      final container = await openPhone(tester);
      await verifyOld(tester, '000000');

      await _type(tester, '新手机号', '13900001111');
      await _sendCode(tester, '新手机验证码');
      expect(find.text('先验证现在绑定的手机'), findsOneWidget);
      expect(find.text('验证码错误，请重新输入'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('新号码已注册其他账号：在新号码下提示', (tester) async {
      env.adapter.on('POST /user/mobile/change/new-code', [
        FakeAdapter.fail(40001),
      ]);
      final container = await openPhone(tester);
      await verifyOld(tester);

      await _type(tester, '新手机号', '13900001111');
      await _sendCode(tester, '新手机验证码');
      expect(find.text('这个号码已注册其他账号'), findsOneWidget);
      expect(find.text('新手机号'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('已验证过当前号码后重发不再带旧验证码；校验过期时回到第一步', (tester) async {
      env.adapter.on('POST /user/mobile/change/new-code', [
        FakeAdapter.ok(),
        FakeAdapter.fail(10002),
      ]);
      final container = await openPhone(tester);
      await verifyOld(tester);

      await _type(tester, '新手机号', '13900001111');
      await _sendCode(tester, '新手机验证码');
      await _type(tester, '新手机号', '13900002222');
      await tester.pump(const Duration(seconds: 61));
      await _sendCode(tester, '新手机验证码');
      final sends = env.adapter.sent('POST /user/mobile/change/new-code');
      expect(sends.last.body, {'mobile': '13900002222'});
      expect(find.text('请重新验证当前手机号'), findsOneWidget);
      expect(find.text('先验证现在绑定的手机'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('提交时当前号码的校验过期：回到第一步；新验证码不对就地提示', (tester) async {
      env.adapter
        ..on('POST /user/mobile/change/new-code', [FakeAdapter.ok()])
        ..on('POST /user/mobile/change/commit', [
          FakeAdapter.fail(30005),
          FakeAdapter.fail(40002),
        ]);
      final container = await openPhone(tester);
      await verifyOld(tester);
      await _type(tester, '新手机号', '13900001111');
      await _sendCode(tester, '新手机验证码');
      await _type(tester, '新手机验证码', '222222');

      await tester.tap(_button('换绑'));
      await tester.pumpAndSettle();
      expect(find.text('验证码错误，请重新输入'), findsOneWidget);
      expect(find.text('新手机号'), findsOneWidget);

      await tester.tap(_button('换绑'));
      await tester.pumpAndSettle();
      expect(find.text('先验证现在绑定的手机'), findsOneWidget);
      expect(find.text('请重新验证当前手机号'), findsOneWidget);
      await unmountApp(tester, container);
    });
  });

  testWidgets('没有手机号时绑定手机：发码和提交都只用新号码', (tester) async {
    env.adapter
      ..on('GET /auth/captcha/config', [_captchaOff])
      ..on('POST /user/getCode', [FakeAdapter.ok()])
      ..on('POST /user/bindMobile', [FakeAdapter.ok()])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson(verified: true))]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(
        user: CurrentUser(
          id: 42,
          nickname: '天凉被破王',
          hasPassword: true,
          verified: true,
        ),
      ),
      token: _token,
      location: Paths.settingsAccount,
    );
    expect(find.text('未绑定'), findsOneWidget);
    await tester.tap(find.text('手机号'));
    await tester.pumpAndSettle();
    expect(find.text('绑定手机'), findsWidgets);

    await _type(tester, '手机号', '13900001111');
    await _sendCode(tester, '验证码');
    expect(env.adapter.sent('POST /user/getCode').single.body, {
      'mobile': '13900001111',
    });
    await _type(tester, '验证码', '333333');
    await tester.tap(_button('绑定'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /user/bindMobile').single.body, {
      'mobile': '13900001111',
      'code': '333333',
    });
    expect(env.adapter.sent('POST /user/mobile/change/old-code'), isEmpty);
    expect(find.byType(PhonePage), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });
}
