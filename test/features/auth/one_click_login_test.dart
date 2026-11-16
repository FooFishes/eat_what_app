import 'dart:async';
import 'dart:convert';

import 'package:eat/core/platform/number_auth/number_auth.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/features/auth/login_page.dart';
import 'package:eat/features/auth/phone_login_page.dart';
import 'package:eat/features/discover/discover_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/fakes.dart';

Map<String, Object?> _token() =>
    FakeAdapter.ok({'tokenName': 'satoken', 'tokenValue': 'tk'});

Map<String, Object?> _policy(String version) => FakeAdapter.ok({
  'version': version,
  'privacyText': '隐私政策正文',
  'crossBorderText': '数据跨境说明正文',
  'publishedAt': 1792763739329,
});

const _config = 'GET /auth/phone/one-click/config';
const _login = 'POST /auth/phone/one-click/login';

Future<void> _agree(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和个人信息出境说明'));
  await tester.pumpAndSettle();
}

Future<void> _tapPhone(WidgetTester tester) async {
  await tester.tap(find.text('手机注册 / 登录'));
  await tester.pumpAndSettle();
}

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.numberAuth.supported = true;
    env.adapter
      ..on(_config, [
        FakeAdapter.ok({'enabled': true}),
      ])
      ..on('GET /auth/consent/policy', [_policy('v3')])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
  });

  testWidgets('勾选协议前不碰号码认证 SDK，勾选后才准备', (tester) async {
    await pumpApp(tester, env);
    expect(env.adapter.sent(_config), isEmpty);
    expect(env.numberAuth.prepares, 0);

    await _agree(tester);
    expect(env.adapter.sent(_config), hasLength(1));
    expect(env.numberAuth.prepares, 1);
  });

  testWidgets('没勾协议就点按钮：在协议对话框里同意后才准备，接着拉起授权页', (tester) async {
    env.adapter.on(_login, [_token()]);
    final (_, router) = await pumpApp(tester, env);

    await _tapPhone(tester);
    expect(env.numberAuth.prepares, 0);
    await tester.tap(find.text('同意并继续'));
    await tester.pumpAndSettle();

    expect(env.numberAuth.prepares, 1);
    expect(env.numberAuth.requests, 1);
    expect(locationOf(router), Paths.discover);
  });

  testWidgets('一键登录：凭证和政策版本交给服务端，登录后进发现页并记下协议同意，授权页关闭', (tester) async {
    env.adapter.on(_login, [_token()]);
    final (container, router) = await pumpApp(tester, env);
    await _agree(tester);
    await _tapPhone(tester);

    expect(env.adapter.sent(_login).single.body, {
      'accessToken': 'ac-1',
      'policyVersion': 'v3',
      'installId': testInstallId,
    });
    expect(container.read(sessionProvider), isA<SignedIn>());
    expect(locationOf(router), Paths.discover);
    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(env.secure.values['auth.tokenValue'], 'tk');
    expect(env.kv.values[PrivacyConsentStore.key], isNotNull);
    expect(env.numberAuth.open, isFalse);
    expect(env.adapter.sent('POST /auth/phone/code'), isEmpty);
  });

  testWidgets('用户关掉授权页：留在登录页，不发登录请求', (tester) async {
    env.numberAuth.outcomes = [const NumberAuthCancelled()];
    final (_, router) = await pumpApp(tester, env);
    await _agree(tester);
    await _tapPhone(tester);

    expect(locationOf(router), Paths.login);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(env.adapter.sent(_login), isEmpty);
  });

  testWidgets('授权页点「其他号码登录」：去验证码登录页', (tester) async {
    env.numberAuth.outcomes = [const NumberAuthSwitched()];
    await pumpApp(tester, env);
    await _agree(tester);
    await _tapPhone(tester);

    expect(find.byType(PhoneLoginPage), findsOneWidget);
    expect(env.adapter.sent(_login), isEmpty);
  });

  group('一键登录不可用时直接去验证码登录页，不提示', () {
    Future<void> expectCodeLogin(WidgetTester tester) async {
      await pumpApp(tester, env);
      await _agree(tester);
      await _tapPhone(tester);

      expect(find.byType(PhoneLoginPage), findsOneWidget);
      expect(find.byType(EatDialog), findsNothing);
      expect(env.adapter.sent(_login), isEmpty);
    }

    testWidgets('这个构建不支持（Web，没配方案密钥）：不问服务端，不碰 SDK', (tester) async {
      env.numberAuth.supported = false;
      await expectCodeLogin(tester);

      expect(env.adapter.sent(_config), isEmpty);
      expect(env.numberAuth.prepares, 0);
    });

    testWidgets('服务端没开：不碰 SDK', (tester) async {
      env.adapter.on(_config, [
        FakeAdapter.ok({'enabled': false}),
      ]);
      await expectCodeLogin(tester);

      expect(env.numberAuth.prepares, 0);
      expect(env.numberAuth.requests, 0);
    });

    testWidgets('问不到服务端', (tester) async {
      env.adapter.on(_config, [const FakeResponse.offline()]);
      await expectCodeLogin(tester);

      expect(env.numberAuth.prepares, 0);
    });

    testWidgets('没有 SIM 卡或没开蜂窝网络', (tester) async {
      env.numberAuth.available = false;
      await expectCodeLogin(tester);

      expect(env.numberAuth.requests, 0);
    });

    testWidgets('授权页没拉起来或取凭证失败', (tester) async {
      env.numberAuth.outcomes = [const NumberAuthFailed()];
      await expectCodeLogin(tester);

      expect(env.numberAuth.requests, 1);
    });
  });

  testWidgets('这次不可用后会重新准备，回到登录页再点就能拉起授权页', (tester) async {
    env.numberAuth.available = false;
    env.adapter.on(_login, [_token()]);
    final (_, router) = await pumpApp(tester, env);
    await _agree(tester);
    await _tapPhone(tester);
    expect(find.byType(PhoneLoginPage), findsOneWidget);
    expect(env.numberAuth.prepares, 2, reason: '改用验证码登录的同时在后台重新准备');

    env.numberAuth.available = true;
    router.go(Paths.login);
    await tester.pumpAndSettle();
    await _tapPhone(tester);
    expect(find.byType(PhoneLoginPage), findsOneWidget, reason: '后台那次准备仍然失败');

    router.go(Paths.login);
    await tester.pumpAndSettle();
    await _tapPhone(tester);
    expect(env.numberAuth.requests, 1);
    expect(locationOf(router), Paths.discover);
    expect(env.adapter.sent(_config), hasLength(1), reason: '服务端的开关只问一次');
  });

  group('授权后登录失败', () {
    testWidgets('凭证无效：关掉授权页，对话框里点「重试」重新拉起授权页，用新凭证登录', (tester) async {
      env.numberAuth.outcomes = [
        const NumberAuthGranted('ac-1'),
        const NumberAuthGranted('ac-2'),
      ];
      env.adapter.on(_login, [FakeAdapter.fail(20002), _token()]);
      final (_, router) = await pumpApp(tester, env);
      await _agree(tester);
      await _tapPhone(tester);

      expect(env.numberAuth.open, isFalse);
      expect(find.text('本机号码验证失败，请重试'), findsOneWidget);
      expect(locationOf(router), Paths.login);

      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(env.numberAuth.requests, 2);
      expect(
        env.adapter.sent(_login).map((r) => (r.body as Map)['accessToken']),
        ['ac-1', 'ac-2'],
      );
      expect(locationOf(router), Paths.discover);
    });

    testWidgets('网络不通：对话框里点「用验证码登录」去验证码登录页', (tester) async {
      env.adapter.on(_login, [const FakeResponse.offline()]);
      await pumpApp(tester, env);
      await _agree(tester);
      await _tapPhone(tester);

      expect(env.numberAuth.open, isFalse);
      expect(find.byType(EatDialog), findsOneWidget);
      await tester.tap(find.text('用验证码登录'));
      await tester.pumpAndSettle();
      expect(find.byType(PhoneLoginPage), findsOneWidget);
    });

    testWidgets('服务端在登录时才说没开：不提示，去验证码登录页，之后不再尝试', (tester) async {
      env.adapter.on(_login, [FakeAdapter.fail(20007)]);
      final (_, router) = await pumpApp(tester, env);
      await _agree(tester);
      await _tapPhone(tester);

      expect(find.byType(PhoneLoginPage), findsOneWidget);
      expect(find.byType(EatDialog), findsNothing);

      router.go(Paths.login);
      await tester.pumpAndSettle();
      await _tapPhone(tester);
      expect(find.byType(PhoneLoginPage), findsOneWidget);
      expect(env.numberAuth.requests, 1);
    });
  });

  group('政策更新', () {
    for (final code in [20005, 20009]) {
      testWidgets('服务端返回 $code：先关授权页再弹同意对话框，同意后用同一个凭证重试', (tester) async {
        env.adapter
          ..on('GET /auth/consent/policy', [_policy('v3'), _policy('v4')])
          ..on(_login, [FakeAdapter.fail(code), _token()]);
        final (_, router) = await pumpApp(tester, env);
        await _agree(tester);
        await _tapPhone(tester);

        expect(env.numberAuth.open, isFalse);
        expect(locationOf(router), Paths.login);
        await tester.tap(find.text('同意'));
        await tester.pumpAndSettle();

        expect(env.adapter.sent(_login).map((r) => r.body), [
          {
            'accessToken': 'ac-1',
            'policyVersion': 'v3',
            'installId': testInstallId,
          },
          {
            'accessToken': 'ac-1',
            'policyVersion': 'v4',
            'installId': testInstallId,
          },
        ]);
        expect(env.numberAuth.requests, 1);
        expect(locationOf(router), Paths.discover);
      });
    }

    testWidgets('不同意：留在登录页，提示同意后才能继续，不重试', (tester) async {
      env.adapter.on(_login, [FakeAdapter.fail(20009)]);
      final (container, router) = await pumpApp(tester, env);
      await _agree(tester);
      await _tapPhone(tester);

      await tester.tap(find.text('不同意'));
      await tester.pump();
      expect(find.text('同意隐私政策后才能继续'), findsOneWidget);
      expect(env.adapter.sent(_login), hasLength(1));
      expect(locationOf(router), Paths.login);
      expect(container.read(sessionProvider), isA<SignedOut>());
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });

  group('账号在注销冷静期内 (30017)', () {
    setUp(() => env.adapter.on(_login, [FakeAdapter.fail(30017)]));

    testWidgets('本机存着撤销凭据：去验证码登录页，提示用验证码登录可以撤销', (tester) async {
      env.secure.values['account.deletion'] = jsonEncode({
        'userId': 42,
        'key': 'k-1',
      });
      await pumpApp(tester, env);
      await _agree(tester);
      await _tapPhone(tester);

      expect(env.numberAuth.open, isFalse);
      expect(find.byType(PhoneLoginPage), findsOneWidget);
      expect(find.text('账号注销中，用验证码登录可以撤销'), findsOneWidget);
    });

    testWidgets('本机没有撤销凭据：留在登录页，说明要在申请注销的设备上登录', (tester) async {
      final (container, router) = await pumpApp(tester, env);
      await _agree(tester);
      await _tapPhone(tester);

      expect(env.numberAuth.open, isFalse);
      expect(find.text('账号注销中，在申请注销的设备上重新登录可以撤销'), findsOneWidget);
      expect(find.text('重试'), findsNothing);
      await tester.tap(find.text('知道了'));
      await tester.pumpAndSettle();
      expect(locationOf(router), Paths.login);
      expect(container.read(sessionProvider), isA<SignedOut>());
    });
  });

  testWidgets('登录进行中按钮显示加载，重复点击不会再拉起授权页', (tester) async {
    final hold = Completer<void>();
    env.numberAuth
      ..outcomes = [const NumberAuthCancelled()]
      ..hold = hold;
    await pumpApp(tester, env);
    await _agree(tester);
    final button = find.byWidgetPredicate(
      (widget) => widget is EatButton && widget.icon == EatIcons.phone,
    );

    await tester.tap(find.text('手机注册 / 登录'));
    await tester.pump();
    expect(tester.widget<EatButton>(button).loading, isTrue);
    await tester.tap(button);
    await tester.pump();
    expect(env.numberAuth.requests, 1);

    hold.complete();
    await tester.pump();
    await tester.pump();
    expect(tester.widget<EatButton>(button).loading, isFalse);
    expect(env.numberAuth.requests, 1);
  });

  test('没配方案密钥的构建不支持一键登录，各个方法都按不可用返回', () async {
    const numberAuth = UnsupportedNumberAuth();

    expect(numberAuth.supported, isFalse);
    expect(await numberAuth.prepare(), isFalse);
    expect(await numberAuth.requestToken(), isA<NumberAuthFailed>());
    await numberAuth.closeAuthPage();
  });
}
