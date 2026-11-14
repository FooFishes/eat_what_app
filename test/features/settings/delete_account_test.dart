import 'dart:convert';

import 'package:eat/core/network/auth_token.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

const _token = AuthToken(name: 'satoken', value: 'tk');

/// 文字为 [label] 的 [EatButton]. 页面标题与按钮同名时, 按文字查找会同时命中标题.
Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is EatButton && w.label == label);

Map<String, Object?> _requested() => FakeAdapter.ok({
  'deleteAt': DateTime(2026, 11, 21).millisecondsSinceEpoch,
  'deletionKey': 'k-1',
});

/// 没有绑定手机号, 只能用密码确认的账号.
const _noPhone = CurrentUser(
  id: 42,
  nickname: '天凉被破王',
  hasPassword: true,
  verified: true,
);

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('POST /auth/logout', [FakeAdapter.ok()])
      ..on('GET /auth/captcha/config', [
        FakeAdapter.ok({'enabled': false}),
      ])
      ..on('POST /auth/account/delete/code', [FakeAdapter.ok()]);
  });

  Future<void> enterCode(WidgetTester tester) async {
    await tester.ensureVisible(find.text('获取验证码'));
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '123456');
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.ensureVisible(_button('申请注销'));
    await tester.tap(_button('申请注销'));
    await tester.pumpAndSettle();
    await tester.tap(_button('注销'));
    await tester.pumpAndSettle();
  }

  testWidgets('有手机号时用验证码确认；默认保留评论；提交后存下撤销凭据并退出登录', (tester) async {
    env.adapter.on('POST /auth/account/delete', [_requested()]);
    final (_, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      token: _token,
      location: Paths.settingsDelete,
    );

    expect(find.text('若不删除，内容将保留，作者显示为「已注销用户」'), findsOneWidget);
    expect(
      tester.widget<EatButton>(_button('申请注销')).onPressed,
      isNull,
      reason: '没填验证码时不能提交',
    );
    await expectAccessible(tester);

    await enterCode(tester);
    expect(env.adapter.sent('POST /auth/account/delete/code'), hasLength(1));
    await tester.ensureVisible(_button('申请注销'));
    await tester.tap(_button('申请注销'));
    await tester.pumpAndSettle();
    expect(find.text('注销账号？'), findsOneWidget);
    expect(find.text('7 天内在这台设备上重新登录即撤销。'), findsOneWidget);
    await tester.tap(_button('注销'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('POST /auth/account/delete').single.body, {
      'code': '123456',
      'deleteComments': false,
    });
    expect(jsonDecode(env.secure.values['account.deletion']!), {
      'userId': 42,
      'key': 'k-1',
    });
    expect(env.adapter.sent('POST /auth/logout'), hasLength(1));
    expect(locationOf(router), startsWith(Paths.login));
    expect(find.text('已申请注销，7 天内在这台设备上登录可以撤销'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('没有手机号时用密码确认；选了删除评论时确认对话框写明，请求带上选择', (tester) async {
    env.adapter.on('POST /auth/account/delete', [_requested()]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: _noPhone),
      token: _token,
      location: Paths.settingsDelete,
    );

    expect(find.text('获取验证码'), findsNothing);
    await tester.tap(find.text('同时删除我的评论和回复'));
    await tester.pump();
    expect(find.text('评论和回复会一起删除'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'secret-1');
    await tester.pump();
    await tester.ensureVisible(_button('申请注销'));
    await tester.tap(_button('申请注销'));
    await tester.pumpAndSettle();
    expect(find.text('7 天内在这台设备上重新登录即撤销。评论和回复将一并删除。'), findsOneWidget);
    await tester.tap(_button('注销'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('POST /auth/account/delete').single.body, {
      'password': 'secret-1',
      'deleteComments': true,
    });
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('取消确认不发请求；验证码错了提示在输入框下，留在本页', (tester) async {
    env.adapter.on('POST /auth/account/delete', [FakeAdapter.fail(30005)]);
    final (_, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      token: _token,
      location: Paths.settingsDelete,
    );

    await enterCode(tester);
    await tester.ensureVisible(_button('申请注销'));
    await tester.tap(_button('申请注销'));
    await tester.pumpAndSettle();
    await tester.tap(_button('取消'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /auth/account/delete'), isEmpty);

    await confirm(tester);
    expect(find.text('验证码错误，请重新输入'), findsOneWidget);
    expect(locationOf(router), Paths.settingsDelete);
    expect(env.secure.values['account.deletion'], isNull);
    expect(env.adapter.sent('POST /auth/logout'), isEmpty);
  });
}
