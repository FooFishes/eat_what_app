import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

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

    await tester.tap(find.text('我已完成，刷新状态'));
    await tester.pumpAndSettle();
    expect(find.text('认证未完成，请重新认证'), findsOneWidget);
  });
}

/// 已登录、停在认证页，打开网页换成假的。
Future<void> pumpAppWithBrowser(
  WidgetTester tester,
  TestEnv env,
  Browser browser,
) async => pumpApp(
  tester,
  env,
  session: const SignedIn(user: testUser),
  token: _token,
  location: Paths.verify,
  overrides: [browserProvider.overrideWithValue(browser)],
);
