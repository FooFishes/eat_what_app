import 'dart:async';

import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/features/auth/password_login_page.dart';
import 'package:eat/features/auth/phone_login_page.dart';
import 'package:eat/domain/models/cancellation.dart';
import 'package:eat/features/auth/restore_page.dart';
import 'package:eat/features/auth/restore_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

const _subject = '11111111-1111-4111-8111-111111111111';
const _request = '22222222-2222-4222-8222-222222222222';
const _capability = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
const _status = 'POST /user/cancellation/$_subject/$_request/status';
const _cancel = 'POST /user/cancellation/$_subject/$_request/cancel';

const _pending = PendingCancellation(
  subjectId: _subject,
  requestId: _request,
  phase: CancellationPhase.preparing,
);

Map<String, Object?> _phase(String phase) => FakeAdapter.ok({
  'requestId': _request,
  'phase': phase,
  'deadline': '2026-11-18T08:00:00Z',
  'complete': false,
});

Map<String, Object?> _grant(String operationId) => FakeAdapter.ok({
  'subjectId': _subject,
  'requestId': _request,
  'operationId': operationId,
  'bindingVersion': 1,
  'proofDigest': 'digest',
  'expiresAt': null,
});

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is EatButton && w.label == label);

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

/// 从登录页进入撤销页. [byPassword] 为 true 时停在密码登录页, 否则停在手机号登录页.
///
/// 后端没有注销接口, 登录流程不再进入撤销页. 测试按原来的入口开始撤销, 再打开撤销页.
Future<void> _openRestore(
  WidgetTester tester,
  ProviderContainer container,
  GoRouter router, {
  bool byPassword = true,
}) async {
  await tester.tap(find.bySemanticsLabel('同意隐私政策、用户协议和数据存放在境外'));
  await tester.pump();
  await tester.tap(find.text(byPassword ? '账号密码登录' : '验证码登录'));
  await tester.pumpAndSettle();
  unawaited(
    container
        .read(accountRestoreProvider.notifier)
        .begin(
          _pending,
          account: '13812345678',
          method: byPassword ? RestoreMethod.password : RestoreMethod.code,
        ),
  );
  unawaited(router.push(Paths.loginRestore));
  await tester.pumpAndSettle();
}

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /auth/captcha/config', [
        FakeAdapter.ok({'enabled': false, 'provider': 'tencent-cloud-intl'}),
      ])
      ..on(_status, [_phase('PREPARING')]);
  });

  testWidgets('从密码登录进入：用密码验证后撤销，回到登录重新登录', (tester) async {
    env.secure.values['lifecycle.recovery.$_request'] = _capability;
    env.adapter
      ..on('POST /user/cancellation/recover/password', [
        FakeAdapter.fail(30004),
        _grant('op-1'),
      ])
      ..on(_cancel, [_phase('ACTIVE')]);
    final (container, router) = await pumpApp(tester, env);

    await _openRestore(tester, container, router);
    expect(find.byType(RestorePage), findsOneWidget);
    expect(find.text('账号正在注销，将在 11 月 18 日彻底删除。'), findsOneWidget);
    expect(
      env.adapter.sent(_status).single.headers['X-Lifecycle-Recovery'],
      _capability,
    );
    // 账号沿用登录时填的, 密码要重新输入.
    expect(find.text('13812345678'), findsOneWidget);
    await expectAccessible(tester);

    await _enter(tester, '密码', 'wrong-1');
    await tester.tap(_button('撤销注销'));
    await tester.pumpAndSettle();
    expect(find.text('账号或密码错误'), findsOneWidget);

    await _enter(tester, '密码', 'secret-1');
    await tester.tap(_button('撤销注销'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /user/cancellation/recover/password').last.body,
      containsPair('password', 'secret-1'),
    );
    expect(env.adapter.sent(_cancel).single.body, {
      'credentialOperation': 'op-1',
    });
    expect(find.text('已撤销注销，请重新登录'), findsOneWidget);
    expect(find.byType(PasswordLoginPage), findsOneWidget);
    expect(find.byType(RestorePage), findsNothing);
    expect(env.secure.values, isNot(contains('lifecycle.recovery.$_request')));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('从验证码登录进入：默认用验证码验证，先发码才能撤销', (tester) async {
    env.secure.values['lifecycle.recovery.$_request'] = _capability;
    env.adapter
      ..on('POST /user/cancellation/recover/phone/challenge', [
        FakeAdapter.ok({
          'challengeId': 'c',
          'expiresAt': '2026-11-11T08:05:00Z',
        }),
      ])
      ..on('POST /user/cancellation/recover/phone/verify', [_grant('op-2')])
      ..on(_cancel, [_phase('ACTIVE')]);
    final (container, router) = await pumpApp(tester, env);
    await _openRestore(tester, container, router, byPassword: false);

    expect(find.byType(RestorePage), findsOneWidget);
    expect(find.text('验证码发到绑定的手机'), findsOneWidget);
    await _enter(tester, '验证码发到绑定的手机', '222222');
    expect(tester.widget<EatButton>(_button('撤销注销')).onPressed, isNull);

    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle();
    final challenge =
        env.adapter
                .sent('POST /user/cancellation/recover/phone/challenge')
                .single
                .body!
            as Map<String, Object?>;
    expect(challenge['recoveryCapability'], _capability);
    expect(find.textContaining('秒后重发'), findsOneWidget);

    await _enter(tester, '验证码发到绑定的手机', '222222');
    await tester.tap(_button('撤销注销'));
    await tester.pumpAndSettle();
    final verify =
        env.adapter
                .sent('POST /user/cancellation/recover/phone/verify')
                .single
                .body!
            as Map<String, Object?>;
    expect(verify['code'], '222222');
    expect(verify['operationId'], challenge['operationId']);
    expect(env.adapter.sent(_cancel).single.body, {
      'credentialOperation': 'op-2',
    });
    expect(find.byType(PhoneLoginPage), findsOneWidget);
    expect(find.text('已撤销注销，请重新登录'), findsOneWidget);
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('可以在验证码和密码之间切换', (tester) async {
    env.secure.values['lifecycle.recovery.$_request'] = _capability;
    final (container, router) = await pumpApp(tester, env);
    await _openRestore(tester, container, router);

    await tester.tap(find.text('改用验证码验证'));
    await tester.pumpAndSettle();
    expect(find.text('验证码发到绑定的手机'), findsOneWidget);
    await tester.tap(find.text('改用密码验证'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(EatFormField, '密码'), findsOneWidget);
  });

  testWidgets('申请不是在这台设备上提交的：只说明原因，不发撤销请求', (tester) async {
    final (container, router) = await pumpApp(tester, env);
    await _openRestore(tester, container, router);

    expect(find.byType(RestorePage), findsOneWidget);
    expect(find.textContaining('请在提交注销申请的设备上登录撤销'), findsOneWidget);
    expect(env.adapter.sent(_status), isEmpty);
    await tester.tap(_button('知道了'));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordLoginPage), findsOneWidget);
  });

  testWidgets('直接打开撤销页时回到登录页', (tester) async {
    final (_, router) = await pumpApp(
      tester,
      env,
      location: Paths.loginRestore,
    );

    expect(locationOf(router), Paths.login);
  });
}
