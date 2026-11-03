import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

const _token = AuthToken(name: 'satoken', value: 'tk');

class _FakeBrowser implements Browser {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }

  @override
  Future<bool> openSso(Uri url) async {
    opened.add(url);
    return true;
  }

  int closed = 0;

  @override
  Future<void> closeSso() async => closed++;
}

/// 最上方页面的地址. push 打开的页面不改变 [locationOf] 读取的页面栈地址.
String _top(GoRouter router) => router.state.uri.toString();

Uri _callback(String query) =>
    Uri.parse('https://eat.v50to.you/app/auth/callback?$query');

void main() {
  late TestEnv env;
  late _FakeBrowser browser;

  setUp(() {
    env = TestEnv();
    browser = _FakeBrowser();
    env.adapter.on('GET /auth/captcha/config', [
      FakeAdapter.ok({'enabled': false, 'provider': 'tencent-cloud-intl'}),
    ]);
  });

  testWidgets('邮箱认证：只收山大邮箱，发出后回来刷新到已认证', (tester) async {
    env.adapter
      ..on('GET /auth/sendEmail', [FakeAdapter.ok()])
      ..on('GET /user/info', [
        FakeAdapter.ok(userInfoJson()),
        FakeAdapter.ok(userInfoJson(verified: true, method: 'school_email')),
      ]);
    await pumpAppWithBrowser(tester, env, browser);
    expect(find.text('现在 未认证', findRichText: true), findsOneWidget);
    await expectAccessible(tester);

    final field = find.descendant(
      of: find.widgetWithText(EatFormField, '邮箱'),
      matching: find.byType(EditableText),
    );
    await tester.enterText(field, 'me@qq.com');
    await tester.tap(find.text('发送认证链接'));
    await tester.pumpAndSettle();
    expect(find.text('请填写 @mail.sdu.edu.cn 或 @sdu.edu.cn 邮箱'), findsOneWidget);
    expect(env.adapter.sent('GET /auth/sendEmail'), isEmpty);

    await tester.enterText(field, '2021@mail.sdu.edu.cn');
    await tester.tap(find.text('发送认证链接'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('GET /auth/sendEmail').single.query, {
      'email': '2021@mail.sdu.edu.cn',
    });
    expect(find.textContaining('认证链接已发送至'), findsOneWidget);

    await tester.tap(find.text('我已完成，刷新状态'));
    await tester.pumpAndSettle();
    expect(find.text('已认证'), findsOneWidget);
    expect(find.text('山大邮箱'), findsWidgets);
  });

  testWidgets('统一认证：每次重新拿一次性地址，在应用内浏览器打开；回来还没认证就提示', (tester) async {
    env.adapter
      ..on('GET /auth/sdu', [
        FakeAdapter.ok({
          'url': 'https://pass.sdu.edu.cn/cas?state=s1',
          'expiresIn': 300,
        }),
      ])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
    await pumpAppWithBrowser(tester, env, browser);

    await tester.tap(find.text('山大统一认证'));
    await tester.pumpAndSettle();
    expect(
      browser.opened.single.toString(),
      'https://pass.sdu.edu.cn/cas?state=s1',
    );
    expect(env.adapter.sent('GET /auth/sdu').single.query, {'client': 'app'});

    await tester.tap(find.text('我已完成，刷新状态'));
    await tester.pumpAndSettle();
    expect(find.text('认证未完成，请重新认证'), findsOneWidget);
  });

  group('统一认证回跳', () {
    testWidgets('失败：从其他页面打开认证页，按业务码提示，不显示业务码', (tester) async {
      env.adapter.on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
      final (_, router) = await pumpAppWithBrowser(
        tester,
        env,
        browser,
        location: Paths.discover,
      );

      env.links.open(_callback('result=failure&code=30013'));
      await tester.pumpAndSettle();

      // 读取结果后从地址中移除, Web 刷新时不重复显示.
      expect(_top(router), Paths.verify);
      expect(find.text('该学号已认证其他账号'), findsOneWidget);
      expect(find.textContaining('30013'), findsNothing);
      expect(find.text('现在 未认证', findRichText: true), findsOneWidget);
      expect(env.adapter.sent('GET /user/info'), isNotEmpty);
      expect(browser.closed, 1);

      // 返回回到原来的页面.
      router.pop();
      await tester.pumpAndSettle();
      expect(_top(router), Paths.discover);
    });

    testWidgets('失败：链接失效和码表里没有的业务码，重复收到同样的结果也提示', (tester) async {
      env.adapter
        ..on('GET /user/info', [FakeAdapter.ok(userInfoJson())])
        ..on('GET /auth/sdu', [
          FakeAdapter.ok({
            'url': 'https://pass.sdu.edu.cn/cas',
            'expiresIn': 300,
          }),
        ]);
      await pumpAppWithBrowser(tester, env, browser);

      env.links.open(_callback('result=failure&code=30012'));
      await tester.pumpAndSettle();
      expect(find.text('认证链接已失效，请重新发起认证'), findsOneWidget);

      env.links.open(_callback('result=failure&code=40001'));
      await tester.pumpAndSettle();
      expect(find.text('认证没有完成，请重新认证'), findsOneWidget);
      expect(find.text('认证链接已失效，请重新发起认证'), findsNothing);

      // 重新发起后又收到同样的结果, 仍然提示.
      await tester.tap(find.text('山大统一认证'));
      await tester.pumpAndSettle();
      expect(find.text('认证没有完成，请重新认证'), findsNothing);
      env.links.open(_callback('result=failure&code=40001'));
      await tester.pumpAndSettle();
      expect(find.text('认证没有完成，请重新认证'), findsOneWidget);
    });

    testWidgets('成功：刷新到已认证；认证引导中保留引导参数', (tester) async {
      env.adapter.on('GET /user/info', [
        FakeAdapter.ok(userInfoJson()),
        FakeAdapter.ok(userInfoJson(verified: true, method: 'sso')),
      ]);
      final (_, router) = await pumpAppWithBrowser(
        tester,
        env,
        browser,
        location: '/verify?onboarding=1&from=%2Fme',
      );
      expect(find.text('先逛逛'), findsOneWidget);

      env.links.open(_callback('result=success&code=0'));
      await tester.pumpAndSettle();

      final location = Uri.parse(_top(router));
      expect(location.path, Paths.verify);
      expect(location.queryParameters, {'onboarding': '1', 'from': '/me'});
      expect(find.text('已认证'), findsOneWidget);
      expect(find.text('去看看今天吃什么'), findsOneWidget);
    });

    testWidgets('成功但账号还没认证：提示稍后刷新', (tester) async {
      env.adapter.on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
      await pumpAppWithBrowser(tester, env, browser);

      env.links.open(_callback('result=success&code=0'));
      await tester.pumpAndSettle();

      expect(find.text('认证结果尚未同步，请稍后刷新状态'), findsOneWidget);
      expect(find.text('我已完成，刷新状态'), findsOneWidget);
    });

    testWidgets('不在白名单的链接忽略', (tester) async {
      env.adapter.on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
      final (_, router) = await pumpAppWithBrowser(
        tester,
        env,
        browser,
        location: Paths.discover,
      );

      env.links
        ..open(
          Uri.parse('https://evil.example/app/auth/callback?result=success'),
        )
        ..open(Uri.parse('https://eat.v50to.you/dishes/1'));
      await tester.pumpAndSettle();

      expect(_top(router), Paths.discover);
      expect(browser.closed, 0);
    });

    testWidgets('Web：地址栏打开回跳地址时转到认证页', (tester) async {
      env.adapter.on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
      final (_, router) = await pumpAppWithBrowser(
        tester,
        env,
        browser,
        location: '/app/auth/callback?result=failure&code=30012',
      );

      expect(_top(router), Paths.verify);
      expect(find.text('认证链接已失效，请重新发起认证'), findsOneWidget);
    });
  });
}

/// 以已登录状态打开认证页, 并用 [browser] 替换打开网页的实现.
Future<(ProviderContainer, GoRouter)> pumpAppWithBrowser(
  WidgetTester tester,
  TestEnv env,
  Browser browser, {
  String location = Paths.verify,
}) => pumpApp(
  tester,
  env,
  session: const SignedIn(user: testUser),
  token: _token,
  location: location,
  overrides: [browserProvider.overrideWithValue(browser)],
);
