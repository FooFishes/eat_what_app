import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

/// 修改记录接口的一条记录.
Map<String, Object?> _revision(
  int id, {
  String action = 'edit',
  int? editorId = 9,
  String? editorName = '小林',
  List<String> fields = const ['price'],
}) => {
  'id': id,
  'action': action,
  'editor': {'id': editorId, 'displayName': editorName, 'avatar': null},
  'restoredFrom': null,
  'changes': [
    for (final field in fields) {'field': field, 'from': null, 'to': null},
  ],
  'createdAt': 1792763739329,
};

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
      ..on('GET /foods/1/history', [
        FakeAdapter.ok(
          pageJson([
            _revision(3, fields: ['price', 'pictures', 'unknown']),
            _revision(2, editorId: null, editorName: null, fields: ['tags']),
            _revision(1, action: 'create', fields: ['name', 'category']),
          ]),
        ),
      ]);
  });

  Finder dialogButton(String label) =>
      find.descendant(of: find.byType(EatDialog), matching: find.text(label));

  testWidgets('每条写编辑者、做了什么；第一条是当前版本，其余可以恢复', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const Guest(),
      location: Paths.dishHistory(1),
    );

    expect(find.text('修改记录'), findsOneWidget);
    expect(find.text('修改了价格、照片'), findsOneWidget);
    expect(find.text('已注销用户'), findsOneWidget);
    expect(find.text('修改了口味'), findsOneWidget);
    expect(find.text('新建了这道菜'), findsOneWidget);
    expect(find.text('当前版本'), findsOneWidget);
    expect(find.text('恢复'), findsNWidgets(2));
    await expectAccessible(tester);
    await unmountApp(tester, container);
  });

  testWidgets('恢复前二次确认，成功后刷新记录和详情', (tester) async {
    env.adapter.on('POST /foods/1/history/2/restore', [
      FakeAdapter.ok({'id': 1, 'revisionId': 4}),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dishHistory(1),
    );
    final listed = env.adapter.sent('GET /foods/1/history').length;

    await tester.tap(find.text('恢复').first);
    await tester.pumpAndSettle();
    expect(find.text('恢复到这个版本？'), findsOneWidget);
    await tester.tap(dialogButton('先不恢复'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /foods/1/history/2/restore'), isEmpty);

    await tester.tap(find.text('恢复').first);
    await tester.pumpAndSettle();
    await tester.tap(dialogButton('恢复'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /foods/1/history/2/restore'), hasLength(1));
    expect(find.text('已恢复'), findsOneWidget);
    expect(
      env.adapter.sent('GET /foods/1/history').length,
      greaterThan(listed),
    );
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('恢复的版本和当前一样时提示「已经是这个版本」', (tester) async {
    env.adapter.on('POST /foods/1/history/2/restore', [
      FakeAdapter.fail(40002),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dishHistory(1),
    );

    await tester.tap(find.text('恢复').first);
    await tester.pumpAndSettle();
    await tester.tap(dialogButton('恢复'));
    await tester.pumpAndSettle();
    expect(find.text('已经是这个版本'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点「恢复」弹拦截，不发请求', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.dishHistory(1),
    );

    await tester.tap(find.text('恢复').first);
    await tester.pumpAndSettle();
    expect(find.text('认证后才能编辑'), findsOneWidget);
    expect(find.text('恢复到这个版本？'), findsNothing);
    expect(
      env.adapter.requests.where((r) => r.path.endsWith('/restore')),
      isEmpty,
    );
    await unmountApp(tester, container);
  });
}
