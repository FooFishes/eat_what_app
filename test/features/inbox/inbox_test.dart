import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

Map<String, Object?> _notice(int id, String type, {bool read = false}) => {
  'id': id,
  'actorId': 5,
  'actorName': '小林',
  'actorAvatar': null,
  'type': type,
  'targetType': type == 'follow' ? 'user' : 'food',
  'targetId': 1,
  'data': '{"foodName":"番茄牛腩饭"}',
  'read': read,
  'createdAt': DateTime.now().millisecondsSinceEpoch,
};

void main() {
  testWidgets('写未读数；点一条算读过并进对应的菜；「全部已读」', (tester) async {
    final env = TestEnv();
    env.adapter
      ..on('GET /notification/unread/count', [FakeAdapter.ok(1)])
      ..on('GET /notification/list', [
        FakeAdapter.ok(
          pageJson([_notice(1, 'like'), _notice(2, 'follow', read: true)]),
        ),
      ])
      ..on('POST /notification/read/1', [FakeAdapter.ok()])
      ..on('POST /notification/read/all', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    expect(find.text('1 条未读'), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
    expect(
      find.textContaining('赞了你上传的番茄牛腩饭', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(UnreadDot), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.textContaining('赞了你上传的', findRichText: true));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /notification/read/1'), hasLength(1));
    expect(env.adapter.sent('GET /foods/detail/1'), hasLength(1));
    await unmountApp(tester, container);
  });
}
