import 'package:eat/core/network/auth_token.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/features/auth/login_page.dart';
import 'package:eat/features/settings/account_page.dart';
import 'package:eat/features/settings/settings_page.dart';
import 'package:eat/features/verify/verify_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

const _token = AuthToken(name: 'satoken', value: 'tk');

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (_) async => {
            'appName': '沙软今天吃什么',
            'packageName': 'you.v50to.eat',
            'version': '0.1.0',
            'buildNumber': '1',
          },
        );
  });

  testWidgets('从「我的」右上角进设置，显示昵称、认证状态和版本号', (tester) async {
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.me,
    );

    await tester.tap(find.bySemanticsLabel('设置'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('天凉被破王'), findsOneWidget);
    expect(find.text('未认证'), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);
    await expectAccessible(tester);
  });

  testWidgets('退出登录：确认后清掉登录信息，回到登录页，不记原页面', (tester) async {
    env.kv.values[PrivacyConsentStore.key] = '{"version":"2026-10"}';
    env.adapter.on('POST /auth/logout', [FakeAdapter.ok()]);
    final (_, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      token: _token,
      location: Paths.settings,
    );

    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();
    expect(find.text('退出登录？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(env.adapter.sent('POST /auth/logout'), isEmpty);

    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /auth/logout'), hasLength(1));
    expect(find.byType(LoginPage), findsOneWidget);
    expect(locationOf(router), Paths.login);
    expect(env.secure.values, isEmpty);
    expect(env.kv.values.containsKey(PrivacyConsentStore.key), isTrue);
  });

  testWidgets('账号与安全：手机号打码，认证状态能点进认证页', (tester) async {
    await pumpApp(
      tester,
      env,
      session: const SignedIn(
        user: CurrentUser(
          id: 1,
          nickname: '同学',
          phone: '13812345678',
          hasPassword: true,
          verified: true,
          verifyMethod: VerifyMethod.schoolEmail,
          banned: false,
        ),
      ),
      location: Paths.settingsAccount,
    );

    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.text('138 **** 5678'), findsOneWidget);
    expect(find.text('已认证，山大邮箱'), findsOneWidget);
    expect(find.text('修改密码'), findsOneWidget);
    expect(find.text('待接入'), findsNWidgets(3));
    expect(
      tester.getTopRight(find.text('未设置')).dx,
      tester.getTopRight(find.text('138 **** 5678')).dx,
    );
    await expectAccessible(tester);

    await tester.tap(find.text('学生认证'));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyPage), findsOneWidget);
  });

  testWidgets('没登录时打开设置，先去登录', (tester) async {
    final (_, router) = await pumpApp(
      tester,
      env,
      location: Paths.settingsAbout,
    );

    expect(
      Uri.parse(locationOf(router)).queryParameters['from'],
      Paths.settingsAbout,
    );
  });
}
