import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';

import 'dart:ui' show CheckedState;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/fakes.dart';

const _channel = MethodChannel('you.v50to.eat/app_icon');

/// 名为 [label] 的选项是否选中.
bool _checked(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.text(label))
        .getSemanticsData()
        .flagsCollection
        .isChecked ==
    CheckedState.isTrue;

void main() {
  late String icon;
  late bool fail;
  late List<MethodCall> calls;

  setUp(() {
    icon = 'pig';
    fail = false;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          if (call.method == 'get') return icon;
          if (fail) throw PlatformException(code: 'failed');
          icon = call.arguments as String;
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null),
  );

  Future<void> open(WidgetTester tester, TestEnv env) async {
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.settingsPersonalize,
    );
    await tester.scrollUntilVisible(find.text('饭饭'), 100);
    await tester.pumpAndSettle();
  }

  testWidgets('App 图标：显示系统当前的图标，点另一个就换', (tester) async {
    final env = TestEnv();
    await open(tester, env);

    expect(find.text('App 图标'), findsOneWidget);
    expect(_checked(tester, '猪猪'), isTrue);
    expect(_checked(tester, '饭饭'), isFalse);

    await tester.tap(find.text('猪猪'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'set'), isEmpty);

    await tester.tap(find.text('饭饭'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'set').single.arguments, 'bun');
    expect(_checked(tester, '饭饭'), isTrue);
    expect(_checked(tester, '猪猪'), isFalse);
  });

  testWidgets('App 图标：换不成时退回原来的选项并提示', (tester) async {
    final env = TestEnv();
    fail = true;
    await open(tester, env);

    await tester.tap(find.text('饭饭'));
    await tester.pumpAndSettle();
    expect(find.text('更换失败，请重试'), findsOneWidget);
    expect(_checked(tester, '猪猪'), isTrue);
    expect(_checked(tester, '饭饭'), isFalse);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
