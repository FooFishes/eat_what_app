import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter.on('GET /campus/list', [FakeAdapter.ok(campusListJson)]);
  });

  testWidgets('输入停下才搜；菜没有、店有时停在「店」栏，搜过的词记下来', (tester) async {
    env.adapter
      ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/search', [
        FakeAdapter.ok(pageJson([restaurantJson()])),
      ]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );

    await tester.enterText(find.byType(EditableText), '袁记');
    await tester.pump(const Duration(milliseconds: 100));
    expect(env.adapter.sent('GET /restaurant/search'), isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      env.adapter.sent('GET /foods/list').single.query,
      containsPair('keyword', '袁记'),
    );
    expect(find.text('袁记云饺'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(env.kv.values['cache.search.42'], '["袁记"]');
  });

  testWidgets('什么都没找到：写「没找到」，认证用户可以新建一家店', (tester) async {
    env.adapter
      ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
      ..on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.search,
    );

    await tester.enterText(find.byType(EditableText), '螺蛳粉');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('没找到「螺蛳粉」'), findsOneWidget);
    expect(find.text('新建一家店'), findsOneWidget);
  });
}
