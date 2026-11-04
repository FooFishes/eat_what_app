import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/features/auth/auth_providers.dart';
import 'package:eat/features/auth/login_page.dart';
import 'package:eat/features/auth/password_login_page.dart';
import 'package:eat/features/auth/phone_login_page.dart';
import 'package:eat/features/discover/discover_page.dart';
import 'package:eat/features/verify/verify_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

Map<String, Object?> _captchaOff() =>
    FakeAdapter.ok({'enabled': false, 'provider': 'tencent-cloud-intl'});

Map<String, Object?> _token({bool newUser = false}) => FakeAdapter.ok({
  'tokenName': 'satoken',
  'tokenValue': 'tk',
  'newUser': newUser,
});

EatButton _button(WidgetTester tester, String label) =>
    tester.widget<EatButton>(
      find.ancestor(of: find.text(label), matching: find.byType(EatButton)),
    );

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.widgetWithText(EatFormField, label),
      matching: find.byType(EditableText),
    ),
    text,
  );
  await tester.pump();
}

Future<void> _agreeAndOpenPhoneLogin(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('同意隐私政策和用户协议'));
  await tester.pump();
  await tester.tap(find.text('手机号登录'));
  await tester.pumpAndSettle();
}

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /auth/captcha/config', [_captchaOff()])
      ..on('GET /auth/consent/policy', [
        FakeAdapter.ok({'version': 'cb-v3', 'url': null}),
      ])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
  });

  testWidgets('没登录时进登录页；没勾协议时按钮是灰的，点了提示先勾选，抽屉高度不变', (tester) async {
    final (_, router) = await pumpApp(tester, env);

    expect(locationOf(router), Paths.login);
    expect(find.byType(LoginPage), findsOneWidget);
    bool hintShown() =>
        tester
            .widget<AnimatedOpacity>(
              find.ancestor(
                of: find.text('请先勾选同意协议'),
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity ==
        1;
    expect(hintShown(), isFalse);
    expect(_button(tester, '手机号登录').muted, isTrue);
    final buttonTop = tester.getTopLeft(find.text('手机号登录')).dy;

    await tester.tap(find.text('手机号登录'));
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.login);
    expect(hintShown(), isTrue);
    expect(tester.getTopLeft(find.text('手机号登录')).dy, buttonTop);

    await tester.tap(find.bySemanticsLabel('同意隐私政策和用户协议'));
    await tester.pump();
    expect(hintShown(), isFalse);
    expect(_button(tester, '手机号登录').muted, isFalse);
    await tester.tap(find.text('手机号登录'));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneLoginPage), findsOneWidget);
  });

  testWidgets('验证码登录：过人机验证发码，60 秒倒计时，登录后进发现页并记下协议同意', (tester) async {
    env.adapter
      ..on('POST /auth/phone/code', [FakeAdapter.ok()])
      ..on('POST /auth/phone/login', [_token()]);
    final (_, router) = await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);
    expect(find.byType(PhoneLoginPage), findsOneWidget);
    await expectAccessible(tester);

    await _enter(tester, '手机号', '1381234567');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    expect(find.text('请输入正确的手机号'), findsOneWidget);
    expect(env.adapter.sent('POST /auth/phone/code'), isEmpty);

    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /auth/phone/code').single.body, {
      'mobile': '13812345678',
    });
    expect(find.textContaining('秒后重发'), findsOneWidget);
    expect(find.text('获取验证码'), findsNothing);
    expect(_button(tester, '登录').onPressed, isNull);

    await _enter(tester, '验证码', '246810');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.discover);
    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(env.secure.values['auth.tokenValue'], 'tk');
    expect(env.kv.values[PrivacyConsentStore.key], contains('2026-10'));
  });

  testWidgets('人机验证打开时，票据随发码请求一起发出', (tester) async {
    env.adapter
      ..on('GET /auth/captcha/config', [
        FakeAdapter.ok({
          'enabled': true,
          'provider': 'tencent-cloud-intl',
          'appId': '1',
          'scriptUrl': 'https://captcha.test/sdk.js',
          'aidEncrypted': 'QUJD',
          'aidEncryptedType': 'cbc',
          'expiresAt': 1,
        }),
      ])
      ..on('POST /auth/phone/code', [FakeAdapter.ok()]);
    await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);

    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    expect(env.verifier.calls, 1);
    final headers = env.adapter.sent('POST /auth/phone/code').single.headers;
    expect(headers['X-Captcha-Ticket'], 't-1');
    expect(headers['X-Captcha-Randstr'], 'r-1');
  });

  testWidgets('验证码发得太频繁时弹面板，可以改用密码登录', (tester) async {
    env.adapter.on('POST /auth/phone/code', [FakeAdapter.fail(10003)]);
    await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);

    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    expect(find.text('发送太频繁，请稍后再试'), findsOneWidget);

    await tester.tap(find.text('用密码登录').last);
    await tester.pumpAndSettle();
    expect(find.byType(PasswordLoginPage), findsOneWidget);
  });

  testWidgets('限流带等待秒数时，面板按秒数提示', (tester) async {
    env.adapter.on('POST /auth/phone/code', [
      {
        'code': 10003,
        'msg': '请求频率过高',
        'data': {'retryAfterSeconds': 45},
      },
    ]);
    await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);

    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    expect(find.text('发送太频繁，请 45 秒后再试'), findsOneWidget);
  });

  testWidgets('发码后账号授权已变化时，提示重新获取验证码', (tester) async {
    env.adapter
      ..on('POST /auth/phone/code', [FakeAdapter.ok()])
      ..on('POST /auth/phone/login', [FakeAdapter.fail(20010)]);
    await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);
    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();

    await _enter(tester, '验证码', '000000');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(find.text('验证码已失效，请重新获取'), findsOneWidget);
    expect(find.text('登录已过期，请重新登录'), findsNothing);
  });

  testWidgets('验证码不对时在验证码下面提示，不清空', (tester) async {
    env.adapter
      ..on('POST /auth/phone/code', [FakeAdapter.ok()])
      ..on('POST /auth/phone/login', [FakeAdapter.fail(30005)]);
    await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);
    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();

    await _enter(tester, '验证码', '000000');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(find.text('验证码错误，请重新输入'), findsOneWidget);
    expect(find.text('000000'), findsOneWidget);
  });

  testWidgets('新号码注册后进认证引导，「先逛逛」回到原来要去的页面', (tester) async {
    env.adapter
      ..on('POST /auth/phone/code', [FakeAdapter.ok()])
      ..on('POST /auth/phone/login', [_token(newUser: true)]);
    final (_, router) = await pumpApp(tester, env, location: Paths.me);
    expect(Uri.parse(locationOf(router)).queryParameters['from'], Paths.me);
    await _agreeAndOpenPhoneLogin(tester);
    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    await _enter(tester, '验证码', '246810');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyPage), findsOneWidget);
    expect(Uri.parse(locationOf(router)).path, Paths.verify);
    expect(find.bySemanticsLabel('返回'), findsNothing);
    await tester.tap(find.text('先逛逛'));
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.me);
  });

  testWidgets('密码登录：账号或密码不对时就地提示，账号不清空；对了回到原页面', (tester) async {
    env.adapter.on('POST /auth/login', [FakeAdapter.fail(30004), _token()]);
    final (_, router) = await pumpApp(tester, env, location: Paths.settings);
    await _agreeAndOpenPhoneLogin(tester);
    await tester.tap(find.text('用密码登录'));
    await tester.pumpAndSettle();
    await expectAccessible(tester);

    await _enter(tester, '账号', 'chi_fan');
    await _enter(tester, '密码', 'wrong-1');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(find.text('账号或密码错误'), findsOneWidget);
    expect(find.text('chi_fan'), findsOneWidget);

    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.settings);
  });

  testWidgets('没设过密码时提示改用验证码登录，「用验证码登录」回到手机号登录', (tester) async {
    env.adapter.on('POST /auth/login', [FakeAdapter.fail(30010)]);
    await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);
    await tester.tap(find.text('用密码登录'));
    await tester.pumpAndSettle();

    await _enter(tester, '账号', '13812345678');
    await _enter(tester, '密码', 'whatever');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(find.text('该号码未设置密码，请使用验证码登录'), findsOneWidget);

    await tester.tap(find.text('用验证码登录'));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneLoginPage), findsOneWidget);
  });

  group('封禁', () {
    Future<void> passwordLogin(WidgetTester tester) async {
      await _agreeAndOpenPhoneLogin(tester);
      await tester.tap(find.text('用密码登录'));
      await tester.pumpAndSettle();
      await _enter(tester, '账号', 'chi_fan');
      await _enter(tester, '密码', 'secret-1');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();
    }

    testWidgets('登录返回 30002 时提示账号已被封禁，不显示业务码', (tester) async {
      env.adapter.on('POST /auth/login', [FakeAdapter.fail(30002, '用户被禁用')]);
      final (container, _) = await pumpApp(tester, env);
      await passwordLogin(tester);

      expect(find.text('账号已被封禁'), findsOneWidget);
      expect(find.textContaining('30002'), findsNothing);
      expect(find.textContaining('用户被禁用'), findsNothing);
      expect(container.read(sessionProvider), isA<SignedOut>());
    });

    testWidgets('拿到受限会话时照常登录，账号状态按用户信息的封禁和期限', (tester) async {
      env.adapter
        ..on('POST /auth/login', [
          FakeAdapter.ok({
            'tokenName': 'satoken',
            'tokenValue': 'rbs1_restricted',
            'isLogin': true,
            'tag': 'restricted',
            'restricted': true,
            'newUser': false,
          }),
        ])
        ..on('GET /user/info', [
          FakeAdapter.ok({
            ...userInfoJson(banned: true),
            'banUntil': DateTime.utc(2026, 11, 30, 4).millisecondsSinceEpoch,
          }),
        ]);
      final (container, router) = await pumpApp(
        tester,
        env,
        location: Paths.settings,
      );
      await passwordLogin(tester);

      expect(locationOf(router), Paths.settings);
      expect(
        env.adapter.sent('GET /user/info').last.headers['satoken'],
        'Bearer rbs1_restricted',
      );
      final status = container.read(accountStatusProvider);
      expect(status, isA<BannedStatus>());
      status as BannedStatus;
      expect(status.reason, '多次发布不是实拍的照片');
      expect(status.until, DateTime.utc(2026, 11, 30, 4).toLocal());
    });

    testWidgets('受限会话还没取到用户信息时也按封禁中处理', (tester) async {
      env.adapter
        ..on('POST /auth/login', [
          FakeAdapter.ok({
            'tokenName': 'satoken',
            'tokenValue': 'rbs1_restricted',
            'restricted': true,
          }),
        ])
        ..on('GET /user/info', [const FakeResponse.offline()]);
      final (container, _) = await pumpApp(tester, env);
      await passwordLogin(tester);

      expect(container.read(sessionProvider), isA<SignedIn>());
      expect(container.read(accountStatusProvider), isA<BannedStatus>());
    });

    testWidgets('受限会话在解封后收到 30002，回到登录页重新登录', (tester) async {
      env.adapter.on('GET /anything', [FakeAdapter.fail(30002)]);
      final (container, router) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: testUser, restricted: true),
        token: const AuthToken(name: 'satoken', value: 'rbs1_restricted'),
        location: Paths.me,
      );

      final request = container
          .read(apiClientProvider)
          .get('/anything')
          .then<Object?>((value) => value, onError: (Object e) => e);
      await tester.pumpAndSettle();
      final failure = await request;
      expect(failure, isA<AppFailure>());
      expect((failure! as AppFailure).kind, FailureKind.sessionExpired);
      expect(container.read(sessionProvider), isA<SignedOut>());
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('登录已过期，请重新登录'), findsOneWidget);
      expect(Uri.parse(locationOf(router)).queryParameters['from'], Paths.me);

      // 离开 "我的" 后, 页面 Provider 的缓存计时器仍未到期. 推进 10 分钟使这些计时器到期.
      await tester.pump(const Duration(minutes: 10));
    });
  });

  group('跨站同步同意', () {
    Map<String, Object?> consentRequired([String? proof]) => {
      'code': 20005,
      'msg': '需要跨境同步同意',
      'data': {'consentProof': ?proof},
    };

    Future<void> openPasswordLogin(WidgetTester tester) async {
      await _agreeAndOpenPhoneLogin(tester);
      await tester.tap(find.text('用密码登录'));
      await tester.pumpAndSettle();
      await _enter(tester, '账号', 'zhang@mail.sdu.edu.cn');
      await _enter(tester, '密码', 'secret1');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();
    }

    testWidgets('密码登录：弹出同意面板，同意后提交同意并自动重新登录', (tester) async {
      env.adapter
        ..on('POST /auth/login', [consentRequired('proof-1'), _token()])
        ..on('POST /auth/consent/grant', [FakeAdapter.ok()]);
      final (_, router) = await pumpApp(tester, env, location: Paths.settings);
      await openPasswordLogin(tester);

      expect(find.text('同意跨站同步后继续'), findsOneWidget);
      expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
      await tester.tap(find.text('同意'));
      await tester.pumpAndSettle();

      expect(env.adapter.sent('POST /auth/consent/grant').single.body, {
        'policyVersion': 'cb-v3',
        'proof': 'proof-1',
      });
      final logins = env.adapter.sent('POST /auth/login').toList();
      expect(logins, hasLength(2));
      expect(logins[1].body, logins[0].body);
      expect(locationOf(router), Paths.settings);
    });

    testWidgets('不同意时停在登录页，不提交同意也不登录', (tester) async {
      env.adapter.on('POST /auth/login', [consentRequired('proof-1')]);
      await pumpApp(tester, env);
      await openPasswordLogin(tester);

      await tester.tap(find.text('不同意'));
      await tester.pumpAndSettle();
      expect(find.byType(PasswordLoginPage), findsOneWidget);
      expect(find.text('需要同意跨站同步后才能继续'), findsOneWidget);
      expect(find.text('zhang@mail.sdu.edu.cn'), findsOneWidget);
      expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
      expect(env.adapter.sent('POST /auth/login'), hasLength(1));
      expect(env.secure.values['auth.tokenValue'], isNull);
    });

    testWidgets('验证码登录：同意后清空验证码，要求重新获取；再登录时带上同意', (tester) async {
      env.adapter
        ..on('POST /auth/phone/code', [FakeAdapter.ok()])
        ..on('POST /auth/phone/login', [
          consentRequired(),
          _token(newUser: true),
        ]);
      await pumpApp(tester, env);
      await _agreeAndOpenPhoneLogin(tester);
      await _enter(tester, '手机号', '13812345678');
      await tester.tap(find.text('获取验证码'));
      await tester.pumpAndSettle();
      await _enter(tester, '验证码', '246810');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('同意'));
      await tester.pumpAndSettle();
      expect(find.byType(PhoneLoginPage), findsOneWidget);
      expect(find.text('验证码已失效，请重新获取'), findsOneWidget);
      expect(find.text('246810'), findsNothing);
      expect(
        env.adapter.sent('POST /auth/consent/grant'),
        isEmpty,
        reason: '新号码没有临时凭证，同意随注册请求提交',
      );
      expect(
        (env.adapter.sent('POST /auth/phone/login').single.body as Map)
            .containsKey('crossBorderConsent'),
        isFalse,
      );

      await tester.pump(resendInterval);
      await tester.tap(find.text('获取验证码'));
      await tester.pumpAndSettle();
      await _enter(tester, '验证码', '135790');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();
      final retry = env.adapter.sent('POST /auth/phone/login').last.body as Map;
      expect(retry['crossBorderConsent'], isTrue);
      expect(retry['consentPolicyVersion'], 'cb-v3');
      expect(find.byType(VerifyPage), findsOneWidget);
    });

    testWidgets('已有账号验证码登录要求同意时，同意后用凭证提交同意', (tester) async {
      env.adapter
        ..on('POST /auth/phone/code', [FakeAdapter.ok()])
        ..on('POST /auth/phone/login', [consentRequired('proof-2')])
        ..on('POST /auth/consent/grant', [FakeAdapter.ok()]);
      await pumpApp(tester, env);
      await _agreeAndOpenPhoneLogin(tester);
      await _enter(tester, '手机号', '13812345678');
      await tester.tap(find.text('获取验证码'));
      await tester.pumpAndSettle();
      await _enter(tester, '验证码', '246810');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('同意'));
      await tester.pumpAndSettle();
      expect(env.adapter.sent('POST /auth/consent/grant').single.body, {
        'policyVersion': 'cb-v3',
        'proof': 'proof-2',
      });
      expect(env.adapter.sent('POST /auth/phone/login'), hasLength(1));
      expect(find.text('验证码已失效，请重新获取'), findsOneWidget);
    });

    testWidgets('已登录时要求同意：在当前页面弹出面板，同意后原请求完成', (tester) async {
      env.adapter
        ..on('GET /anything', [FakeAdapter.fail(20005), FakeAdapter.ok('A')])
        ..on('POST /auth/consent/grant', [FakeAdapter.ok()]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: testUser),
        token: const AuthToken(name: 'satoken', value: 'tk'),
        location: Paths.me,
      );

      final request = container
          .read(apiClientProvider)
          .get('/anything')
          .then<Object?>((value) => value, onError: (Object e) => e);
      await tester.pumpAndSettle();
      expect(find.text('同意跨站同步后继续'), findsOneWidget);
      await tester.tap(find.text('同意'));
      await tester.pumpAndSettle();
      expect(await request, 'A');
      expect(find.text('同意跨站同步后继续'), findsNothing);
    });
  });

  testWidgets('直接打开手机号登录页但还没勾协议，退回登录页', (tester) async {
    final (_, router) = await pumpApp(tester, env, location: Paths.loginPhone);

    expect(locationOf(router), Paths.login);
  });

  testWidgets('登录过期：回到登录页并提示，重新登录后回到原来的页面', (tester) async {
    env.adapter
      ..on('GET /anything', [FakeAdapter.fail(20003)])
      ..on('POST /auth/phone/code', [FakeAdapter.ok()])
      ..on('POST /auth/phone/login', [_token()]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      token: const AuthToken(name: 'satoken', value: 'old'),
      location: Paths.me,
    );

    // 请求在 pump 推进模拟时间后才完成.
    // 先注册错误处理再 pump, 否则请求失败会被报告为未处理的异常.
    final request = container
        .read(apiClientProvider)
        .get('/anything')
        .then<Object?>((value) => value, onError: (Object e) => e);
    await tester.pumpAndSettle();
    expect(await request, isA<AppFailure>());
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('登录已过期，请重新登录'), findsOneWidget);
    expect(Uri.parse(locationOf(router)).queryParameters['from'], Paths.me);

    await _agreeAndOpenPhoneLogin(tester);
    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    await _enter(tester, '验证码', '246810');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(locationOf(router), Paths.me);
  });

  testWidgets('已登录再去登录页，直接回发现页', (tester) async {
    final (_, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.login,
    );

    expect(locationOf(router), Paths.discover);
  });

  testWidgets('系统字号 2 倍时登录各页不溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, env);
    expect(tester.takeException(), isNull);
    await _agreeAndOpenPhoneLogin(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('用密码登录'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('矮屏加大字号时登录页的品牌字和抽屉不重叠，可以滚到按钮', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, env, size: const Size(320, 480));
    expect(tester.takeException(), isNull);

    final intro = tester.getRect(find.textContaining('是啊'));
    final button = find.widgetWithText(EatButton, '手机号登录');
    expect(intro.bottom, lessThan(tester.getRect(button).top));
    await tester.ensureVisible(find.bySemanticsLabel('同意隐私政策和用户协议'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('同意隐私政策和用户协议'));
    await tester.pump();
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(PhoneLoginPage), findsOneWidget);
  });

  testWidgets('宽屏时登录页的抽屉居中，最宽 480', (tester) async {
    await pumpApp(tester, env, size: const Size(1280, 800));

    final button = tester.getRect(find.widgetWithText(EatButton, '手机号登录'));
    expect(button.width, 480 - 40);
    expect(button.center.dx, 640);
    expect(tester.takeException(), isNull);
  });
}
