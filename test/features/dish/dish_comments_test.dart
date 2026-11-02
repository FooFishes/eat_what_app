import 'package:eat/design/widgets/photo_viewer.dart';
import 'package:eat/features/comments/comments_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/comment_fixtures.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  final scrollable = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
      ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())])
      ..on('GET /foods/1/comments', [
        FakeAdapter.ok(
          commentPageJson(
            [
              for (var i = 0; i < 5; i++)
                commentJson(
                  id: 11 + i,
                  author: '同学$i',
                  text: '第 $i 条评论',
                  likes: 9 - i,
                ),
            ],
            total: 23,
            hasNext: true,
          ),
        ),
        FakeAdapter.ok(commentPageJson(const [], page: 2, total: 23)),
      ]);
    for (var i = 0; i < 5; i++) {
      env.adapter.on('GET /comments/${11 + i}/replies', [
        FakeAdapter.ok(commentPageJson(const [])),
      ]);
    }
  });

  testWidgets('「吃过的人说」显示总条数和最有用的 3 条，「看全部」进全部评论', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    await tester.scrollUntilVisible(
      find.text('看全部 23 条'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('23'), findsOneWidget);
    expect(find.text('第 0 条评论'), findsOneWidget);
    expect(find.text('第 2 条评论'), findsOneWidget);
    expect(find.text('第 3 条评论'), findsNothing);
    final sort = env.adapter.sent('GET /foods/1/comments').first.query['sort'];
    expect(sort, 'MOST_USEFUL');
    await expectAccessible(tester);

    await tester.ensureVisible(find.text('看全部 23 条'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('看全部 23 条'));
    await tester.pumpAndSettle();
    expect(find.byType(CommentsPage), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('一条评论都没有时写「吃过的话，说两句」', (tester) async {
    env.adapter.on('GET /foods/1/comments', [
      FakeAdapter.ok(commentPageJson(const [])),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    await tester.scrollUntilVisible(
      find.text('吃过的话，说两句'),
      200,
      scrollable: scrollable,
    );
    expect(find.textContaining('看全部'), findsNothing);
    await expectAccessible(tester);
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点「写一条」弹拦截面板；认证后进写评论', (tester) async {
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.dish(1),
    );

    await tester.scrollUntilVisible(
      find.text('写一条'),
      200,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.text('写一条'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写一条'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能评论'), findsOneWidget);
    expect(locationOf(router), Paths.dish(1));
    await unmountApp(tester, container);
  });

  testWidgets('从消息跳来时滚到那条评论', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1, comment: 13),
    );

    expect(find.text('第 2 条评论').hitTestable(), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('看大图：先是上传者的照片，接着是评论里的照片', (tester) async {
    env.adapter.on('GET /foods/1/gallery', [
      FakeAdapter.ok(
        commentPageJson([
          {
            'commentId': 12,
            'commentGid': 'g-12',
            'createdAt': commentEpoch,
            'image': {'slot': 0, 'url': 'https://img.test/c/12.jpg'},
          },
        ]),
      ),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );

    await tester.tap(find.bySemanticsLabel('看大图'));
    await tester.pumpAndSettle();
    final viewer = tester.widget<PhotoViewer>(find.byType(PhotoViewer));
    expect(
      [for (final p in viewer.photos) p.url],
      ['https://img.test/foods/1.jpg', 'https://img.test/c/12.jpg'],
    );
    expect([for (final p in viewer.photos) p.credit], ['小林', '同学1']);
    expect(find.textContaining('小林 拍的'), findsOneWidget);
    await unmountApp(tester, container);
  });
}
