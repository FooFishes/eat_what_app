import 'dart:convert';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
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

/// 登录成功的响应. 后端目前不返回 `newUser`, [newUser] 为 true 时模拟后端补上该字段.
Map<String, Object?> _token({bool newUser = false}) => FakeAdapter.ok({
  'tokenName': 'satoken',
  'tokenValue': 'tk',
  'isLogin': true,
  if (newUser) 'newUser': true,
});

Map<String, Object?> _policy(String? version) => FakeAdapter.ok({
  'version': version,
  'privacyText': version == null ? null : '隐私政策正文',
  'crossBorderText': version == null ? null : '数据跨境说明正文',
  'publishedAt': version == null ? null : 1792763739329,
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
  await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
  await tester.pump();
  await tester.tap(find.text('手机注册 / 登录'));
  await tester.pumpAndSettle();
}

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /auth/captcha/config', [_captchaOff()])
      ..on('GET /auth/consent/policy', [_policy('v3')])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
  });

  testWidgets('没登录时进登录页；没勾协议时按钮照常可点，点了弹协议对话框', (tester) async {
    final (container, router) = await pumpApp(tester, env);

    expect(locationOf(router), Paths.login);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(_button(tester, '手机注册 / 登录').muted, isFalse);

    await tester.tap(find.text('手机注册 / 登录'));
    await tester.pumpAndSettle();
    expect(find.text('同意后继续'), findsOneWidget);
    await tester.tap(find.text('不同意'));
    await tester.pumpAndSettle();
    expect(find.text('同意后继续'), findsNothing);
    expect(locationOf(router), Paths.login);
    expect(container.read(loginAgreementProvider), isFalse);

    await tester.tap(find.text('手机注册 / 登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('同意并继续'));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneLoginPage), findsOneWidget);
    expect(container.read(loginAgreementProvider), isTrue);
  });

  testWidgets('已经勾了协议就不弹对话框，直接进手机号登录页', (tester) async {
    await pumpApp(tester, env);

    await _agreeAndOpenPhoneLogin(tester);
    expect(find.text('同意后继续'), findsNothing);
    expect(find.byType(PhoneLoginPage), findsOneWidget);
  });

  testWidgets('登录页点「账号密码登录」直接进密码登录页，「用验证码登录」换到手机号登录页', (tester) async {
    await pumpApp(tester, env);
    await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
    await tester.pump();

    await tester.tap(find.text('账号密码登录'));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordLoginPage), findsOneWidget);

    await tester.tap(find.text('用验证码登录'));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneLoginPage), findsOneWidget);
    expect(find.byType(PasswordLoginPage), findsNothing);
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
    expect(
      env.adapter.sent('POST /auth/phone/login').single.body,
      containsPair('policyVersion', 'v3'),
      reason: '勾选的协议随登录请求提交',
    );
    expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
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

  testWidgets('验证码发得太频繁时弹对话框，可以改用密码登录', (tester) async {
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

  testWidgets('限流带等待秒数时，对话框按秒数提示', (tester) async {
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

  testWidgets('验证码输错太多次被限流时，在验证码下面提示何时再试', (tester) async {
    env.adapter
      ..on('POST /auth/phone/code', [FakeAdapter.ok()])
      ..on('POST /auth/phone/login', [
        {
          'code': 10003,
          'msg': '请求频率过高',
          'data': {'retryAfterSeconds': 300},
        },
      ]);
    await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);
    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();

    await _enter(tester, '验证码', '000000');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(find.text('操作过于频繁，请 5 分钟后再试'), findsOneWidget);
    expect(find.text('发送太频繁，请 5 分钟后再试'), findsNothing);
  });

  testWidgets('还没发布隐私政策时，登录不带版本', (tester) async {
    env.adapter
      ..on('GET /auth/consent/policy', [_policy(null)])
      ..on('POST /auth/phone/code', [FakeAdapter.ok()])
      ..on('POST /auth/phone/login', [_token()]);
    final (container, _) = await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);
    await _enter(tester, '手机号', '13812345678');
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    await _enter(tester, '验证码', '246810');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    final body = env.adapter.sent('POST /auth/phone/login').single.body as Map;
    expect(body.containsKey('policyVersion'), isFalse);
    expect(container.read(sessionProvider), isA<SignedIn>());
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

  testWidgets('登录响应带 newUser 时进认证引导，「先逛逛」回到原来要去的页面', (tester) async {
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

  testWidgets('密码登录页常驻说明没设过密码的用验证码登录，「用验证码登录」回到手机号登录', (tester) async {
    env.adapter.on('POST /auth/login', [FakeAdapter.fail(30004)]);
    await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);
    await tester.tap(find.text('用密码登录'));
    await tester.pumpAndSettle();
    expect(find.text('没设过密码的用验证码登录'), findsOneWidget);

    await _enter(tester, '账号', '13812345678');
    await _enter(tester, '密码', 'whatever');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(find.text('账号或密码错误'), findsOneWidget);
    expect(find.text('没设过密码的用验证码登录'), findsOneWidget);

    await tester.tap(find.text('用验证码登录'));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneLoginPage), findsOneWidget);
  });

  testWidgets('密码错误次数过多后要求人机验证：过了验证带票据重新登录', (tester) async {
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
      ..on('POST /auth/login', [FakeAdapter.fail(30015), _token()]);
    final (_, router) = await pumpApp(tester, env, location: Paths.settings);
    await _agreeAndOpenPhoneLogin(tester);
    await tester.tap(find.text('用密码登录'));
    await tester.pumpAndSettle();
    await _enter(tester, '账号', 'chi_fan');
    await _enter(tester, '密码', 'secret-1');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(env.verifier.calls, 1);
    final logins = env.adapter.sent('POST /auth/login').toList();
    expect(logins, hasLength(2));
    expect(logins[0].headers.containsKey('X-Captcha-Ticket'), isFalse);
    expect(logins[1].headers['X-Captcha-Ticket'], 't-1');
    expect(logins[1].body, logins[0].body);
    expect(locationOf(router), Paths.settings);
  });

  testWidgets('要求人机验证时用户关掉验证：停在密码登录页，不提示失败', (tester) async {
    env.verifier.outcome = const CaptchaCancelled();
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
      ..on('POST /auth/login', [FakeAdapter.fail(30015)]);
    await pumpApp(tester, env);
    await _agreeAndOpenPhoneLogin(tester);
    await tester.tap(find.text('用密码登录'));
    await tester.pumpAndSettle();
    await _enter(tester, '账号', 'chi_fan');
    await _enter(tester, '密码', 'secret-1');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(find.byType(PasswordLoginPage), findsOneWidget);
    expect(env.adapter.sent('POST /auth/login'), hasLength(1));
    expect(find.text('人机验证未通过，请重试'), findsNothing);
    expect(find.text('操作失败，请重试'), findsNothing);
  });

  group('注销冷静期', () {
    Future<void> passwordLogin(WidgetTester tester) async {
      await _agreeAndOpenPhoneLogin(tester);
      await tester.tap(find.text('用密码登录'));
      await tester.pumpAndSettle();
      await _enter(tester, '账号', 'chi_fan');
      await _enter(tester, '密码', 'secret-1');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();
    }

    testWidgets('本机存着撤销凭据时随登录带上；登录的是申请注销的账号时删掉凭据', (tester) async {
      env.secure.values['account.deletion'] = jsonEncode({
        'userId': 42,
        'key': 'k-1',
      });
      env.adapter.on('POST /auth/login', [_token()]);
      final (container, _) = await pumpApp(tester, env);
      await passwordLogin(tester);

      expect(
        env.adapter.sent('POST /auth/login').single.body,
        containsPair('deletionKey', 'k-1'),
      );
      expect(container.read(sessionProvider), isA<SignedIn>());
      expect(env.secure.values['account.deletion'], isNull);
    });

    testWidgets('登录了别的账号时保留凭据', (tester) async {
      env.secure.values['account.deletion'] = jsonEncode({
        'userId': 7,
        'key': 'k-1',
      });
      env.adapter.on('POST /auth/login', [_token()]);
      await pumpApp(tester, env);
      await passwordLogin(tester);

      expect(env.secure.values['account.deletion'], isNotNull);
    });

    testWidgets('没有撤销凭据时返回 30017：提示账号注销中，不登录', (tester) async {
      env.adapter.on('POST /auth/login', [FakeAdapter.fail(30017)]);
      final (container, _) = await pumpApp(tester, env);
      await passwordLogin(tester);

      expect(
        env.adapter.sent('POST /auth/login').single.body,
        isNot(contains('deletionKey')),
      );
      expect(find.text('账号注销中，在申请注销的设备上重新登录可以撤销'), findsOneWidget);
      expect(container.read(sessionProvider), isA<SignedOut>());
    });
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

    testWidgets('已登录时收到不带原因的 30002 (账号已不存在)：按登录过期回登录页', (tester) async {
      env.adapter.on('GET /anything', [FakeAdapter.fail(30002)]);
      final (container, router) = await pumpApp(
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
      final failure = await request;
      expect(failure, isA<AppFailure>());
      expect((failure! as AppFailure).kind, FailureKind.sessionExpired);
      expect(
        (container.read(sessionProvider) as SignedOut).reason,
        SignOutReason.expired,
      );
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('登录已过期，请重新登录'), findsOneWidget);
      final query = Uri.parse(locationOf(router)).queryParameters;
      expect(query['expired'], '1');
      expect(env.secure.values['auth.tokenValue'], isNull);

      // 离开 "我的" 后, 页面 Provider 的缓存计时器仍未到期. 推进 10 分钟使这些计时器到期.
      await tester.pump(const Duration(minutes: 10));
    });
  });

  group('隐私政策同意', () {
    Future<void> openPasswordLogin(WidgetTester tester) async {
      await _agreeAndOpenPhoneLogin(tester);
      await tester.tap(find.text('用密码登录'));
      await tester.pumpAndSettle();
      await _enter(tester, '账号', 'zhang@mail.sdu.edu.cn');
      await _enter(tester, '密码', 'secret1');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();
    }

    testWidgets('密码登录时政策已更新：弹对话框，同意后带新版本用同一组账号密码重新登录', (tester) async {
      env.adapter
        ..on('GET /auth/consent/policy', [_policy('v3'), _policy('v4')])
        ..on('POST /auth/login', [FakeAdapter.fail(20009), _token()]);
      final (_, router) = await pumpApp(tester, env, location: Paths.settings);
      await openPasswordLogin(tester);

      expect(find.text('隐私政策已更新'), findsOneWidget);
      expect(env.adapter.sent('POST /auth/login'), hasLength(1));
      await tester.tap(find.text('同意'));
      await tester.pumpAndSettle();

      final logins = env.adapter.sent('POST /auth/login').toList();
      expect(logins, hasLength(2));
      expect(logins[0].body, containsPair('policyVersion', 'v3'));
      expect(logins[1].body, {
        ...logins[0].body! as Map,
        'policyVersion': 'v4',
      });
      expect(
        env.adapter.sent('POST /auth/consent/grant'),
        isEmpty,
        reason: '同意随登录请求提交',
      );
      expect(locationOf(router), Paths.settings);
    });

    testWidgets('不同意时停在登录页，不再登录', (tester) async {
      env.adapter.on('POST /auth/login', [FakeAdapter.fail(20009)]);
      await pumpApp(tester, env);
      await openPasswordLogin(tester);

      await tester.tap(find.text('不同意'));
      await tester.pumpAndSettle();
      expect(find.byType(PasswordLoginPage), findsOneWidget);
      expect(find.text('同意隐私政策后才能继续'), findsOneWidget);
      expect(find.text('zhang@mail.sdu.edu.cn'), findsOneWidget);
      expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
      expect(env.adapter.sent('POST /auth/login'), hasLength(1));
      expect(env.secure.values['auth.tokenValue'], isNull);
    });

    for (final code in [20005, 20009]) {
      testWidgets('验证码登录收到 $code：同意后用同一个验证码重试，不用重新获取', (tester) async {
        env.adapter
          ..on('POST /auth/phone/code', [FakeAdapter.ok()])
          ..on('POST /auth/phone/login', [FakeAdapter.fail(code), _token()]);
        final (container, _) = await pumpApp(tester, env);
        await _agreeAndOpenPhoneLogin(tester);
        await _enter(tester, '手机号', '13812345678');
        await tester.tap(find.text('获取验证码'));
        await tester.pumpAndSettle();
        await _enter(tester, '验证码', '246810');
        await tester.tap(find.text('登录'));
        await tester.pumpAndSettle();

        expect(find.text('隐私政策已更新'), findsOneWidget);
        await tester.tap(find.text('同意'));
        await tester.pumpAndSettle();

        final logins = env.adapter.sent('POST /auth/phone/login').toList();
        expect(logins, hasLength(2));
        expect(logins[1].body, {
          'mobile': '13812345678',
          'code': '246810',
          'device': 'APP',
          'policyVersion': 'v3',
        });
        expect(env.adapter.sent('POST /auth/phone/code'), hasLength(1));
        expect(env.adapter.sent('POST /auth/consent/grant'), isEmpty);
        expect(container.read(sessionProvider), isA<SignedIn>());
      });
    }

    testWidgets('已登录时政策更新：在当前页面弹出对话框，同意后提交同意，原请求完成', (tester) async {
      env.adapter
        ..on('GET /anything', [FakeAdapter.fail(20009), FakeAdapter.ok('A')])
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
      expect(find.text('隐私政策已更新'), findsOneWidget);
      await tester.tap(find.text('同意'));
      await tester.pumpAndSettle();
      expect(await request, 'A');
      expect(env.adapter.sent('POST /auth/consent/grant').single.body, {
        'policyVersion': 'v3',
      });
      expect(find.text('隐私政策已更新'), findsNothing);
    });
  });

  testWidgets('直接打开手机号登录页但还没勾协议，退回登录页', (tester) async {
    final (_, router) = await pumpApp(tester, env, location: Paths.loginPhone);

    expect(locationOf(router), Paths.login);
  });

  testWidgets('登录过期：回到登录页并提示，重新登录后回到原来的页面', (tester) async {
    env.adapter
      ..on('GET /anything', [FakeAdapter.fail(20001)])
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
    final button = find.widgetWithText(EatButton, '手机注册 / 登录');
    expect(intro.bottom, lessThan(tester.getRect(button).top));
    await tester.ensureVisible(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
    await tester.pump();
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(PhoneLoginPage), findsOneWidget);
  });
}
