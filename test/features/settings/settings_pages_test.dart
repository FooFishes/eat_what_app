import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/features/settings/feedback_page.dart';
import 'package:eat/features/settings/password_page.dart';
import 'package:eat/features/settings/privacy_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

const _token = AuthToken(name: 'satoken', value: 'tk');

const _withPassword = CurrentUser(
  id: 42,
  nickname: '天凉被破王',
  phone: '13812345678',
  hasPassword: true,
  verified: true,
);

/// 文字为 [label] 的 [EatButton]. 页面标题与按钮同名时, 按文字查找会同时命中标题.
Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is EatButton && w.label == label);

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

  testWidgets('设置页列出隐私和通知，隐私开关读自己的设置，改了就保存；个性化推荐待接入', (tester) async {
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({
          'displayName': '天凉被破王',
          'fansVisible': false,
          'followingsVisible': true,
        }),
      ])
      ..on('POST /user/changePrivacy', [FakeAdapter.ok()]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.settings,
    );

    expect(find.text('通知'), findsOneWidget);
    await tester.tap(find.text('隐私'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyPage), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('公开我的关注列表'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /user/changePrivacy').single.body, {
      'following': false,
      'follower': false,
    });

    final personalized = find.widgetWithText(EatSwitch, '个性化推荐');
    expect(tester.widget<EatSwitch>(personalized).pending, isTrue);
    expect(
      find.descendant(of: personalized, matching: find.text('待接入')),
      findsOneWidget,
    );
    await tester.tap(find.text('个性化推荐'));
    await tester.pumpAndSettle();
    expect(tester.widget<EatSwitch>(personalized).value, isTrue);
    expect(env.adapter.sent('GET /user/recommendation-settings'), isEmpty);
    expect(env.adapter.sent('PUT /user/recommendation-settings'), isEmpty);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('屏蔽的人：解除屏蔽后从列表里去掉', (tester) async {
    env.adapter
      ..on('GET /user/blocks', [
        FakeAdapter.ok(
          pageJson([
            {'userId': 9, 'displayName': '阿哲'},
            {'userId': 10, 'displayName': null},
          ]),
        ),
      ])
      ..on('DELETE /user/blocks/9', [
        FakeAdapter.ok({'blocked': false}),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.settingsBlocked,
    );

    expect(find.text('已注销用户'), findsOneWidget);
    await expectAccessible(tester);
    await tester.tap(find.text('解除屏蔽').first);
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE /user/blocks/9'), hasLength(1));
    expect(find.text('阿哲'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('设置用户名：验证手机后提交，本机保持登录，刷新账号后返回', (tester) async {
    env.adapter
      ..on('GET /auth/captcha/config', [
        FakeAdapter.ok({'enabled': false}),
      ])
      ..on('POST /auth/password/code', [FakeAdapter.ok()])
      ..on('POST /auth/checkUsername', [FakeAdapter.ok()])
      ..on('POST /auth/username/set', [FakeAdapter.ok()])
      ..on('GET /user/info', [
        FakeAdapter.ok({
          ...userInfoJson(hasPassword: true),
          'userName': 'zhe_01',
          'hasUsername': true,
        }),
      ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      token: _token,
      location: Paths.settingsAccount,
    );

    await tester.tap(find.text('设置用户名'));
    await tester.pumpAndSettle();
    await expectAccessible(tester);
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'zhe_01');
    await tester.pump();
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /auth/password/code'), hasLength(1));
    await tester.enterText(fields.at(1), '123456');
    await tester.pump();
    await tester.enterText(fields.at(2), 'secret1');
    await tester.pump();
    await tester.tap(_button('设置用户名'));
    await tester.pumpAndSettle();

    final check = env.adapter.sent('POST /auth/checkUsername').single;
    expect(check.body, {'userName': 'zhe_01'});
    expect(check.query, isEmpty);
    expect(env.adapter.sent('POST /auth/username/set').single.body, {
      'userName': 'zhe_01',
      'code': '123456',
      'newPassword': 'secret1',
    });
    expect(find.text('用户名和密码已设置，其他设备需要重新登录'), findsOneWidget);
    expect(locationOf(router), Paths.settingsAccount);
    expect(find.text('zhe_01'), findsOneWidget);
    expect(env.secure.values['auth.tokenValue'], 'tk');
    expect(container.read(sessionProvider), isA<SignedIn>());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('设置用户名：用户名被占用时提示在输入框下', (tester) async {
    env.adapter.on('POST /auth/checkUsername', [FakeAdapter.fail(30003)]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _withPassword),
      location: Paths.settingsUsername,
    );

    expect(find.text('密码，选填'), findsNothing);
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'zhe');
    await tester.pump();
    await tester.enterText(fields.at(1), '123456');
    await tester.pump();
    await tester.tap(_button('设置用户名'));
    await tester.pumpAndSettle();
    expect(find.text('用户名已被占用，换一个试试'), findsOneWidget);
    expect(env.adapter.sent('POST /auth/username/set'), isEmpty);
  });

  testWidgets('修改密码：旧密码错了提示在输入框下，改对后返回', (tester) async {
    env.adapter
      ..on('POST /auth/changePassword', [
        FakeAdapter.fail(30004),
        FakeAdapter.ok(),
      ])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson(hasPassword: true))]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _withPassword),
      location: Paths.settingsAccount,
    );

    await tester.tap(find.text('修改密码'));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordPage), findsOneWidget);
    await expectAccessible(tester);
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'old-pass');
    await tester.pump();
    await tester.enterText(fields.at(1), 'new-pass');
    await tester.pump();
    await tester.enterText(fields.at(2), 'new-pazz');
    await tester.pump();
    await tester.tap(_button('修改密码'));
    await tester.pumpAndSettle();
    expect(find.text('两次输入的密码不一致'), findsOneWidget);
    expect(env.adapter.sent('POST /auth/changePassword'), isEmpty);

    await tester.enterText(fields.at(2), 'new-pass');
    await tester.pump();
    await tester.tap(_button('修改密码'));
    await tester.pumpAndSettle();
    expect(find.text('旧密码错误，请重新输入'), findsOneWidget);

    await tester.tap(_button('修改密码'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /auth/changePassword').last.body, {
      'oldPassword': 'old-pass',
      'newPassword': 'new-pass',
    });
    expect(find.byType(PasswordPage), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('反馈：截图先上传，再带着菜提交；重试时截图不重复上传，成功后返回', (tester) async {
    env.photos.next = [
      PickedPhoto(bytes: transparentImage, width: 1, height: 1),
    ];
    env.adapter
      ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
      ..on('POST /upload/presign', [
        FakeAdapter.ok({
          'putUrl': 'https://oss.test/put/fb',
          'key': 'feedback/42/a.jpg',
          'expireAt': 0,
        }),
      ])
      ..on('PUT https://oss.test/put/fb', [<String, Object?>{}])
      ..on('POST /upload/complete', [
        FakeAdapter.ok({'key': 'feedback/42/a.jpg'}),
      ])
      ..on('POST /feedback/messages', [
        const FakeResponse.offline(),
        FakeAdapter.ok({
          'id': 5,
          'kind': 'FEEDBACK',
          'status': 'OPEN',
          'duplicate': false,
          'createdAt': 1,
        }),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.feedback(dishId: 1),
    );

    expect(find.byType(FeedbackPage), findsOneWidget);
    expect(find.text('关于 鲜虾蟹籽云吞'), findsOneWidget);
    expect(find.text('待接入'), findsNothing);
    expect(find.text('提交'), findsOneWidget);
    await expectAccessible(tester);

    await tester.enterText(find.byType(EditableText), '找不到想要的口味词');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('添加截图'));
    await tester.pumpAndSettle();
    await tester.tap(_button('提交'));
    await tester.pumpAndSettle();
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    expect(find.byType(FeedbackPage), findsOneWidget);

    await tester.tap(_button('提交'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /upload/presign').single.body,
      containsPair('biz', 'feedback'),
    );
    final sent = env.adapter.sent('POST /feedback/messages').toList();
    expect(sent, hasLength(2));
    expect(sent.last.body, {
      'text': '找不到想要的口味词',
      'screenshotKeys': ['feedback/42/a.jpg'],
      'context': {'type': 'FOOD', 'id': 1},
    });
    expect(sent.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(find.byType(FeedbackPage), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });
}
