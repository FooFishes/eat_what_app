import 'package:eat/features/comments/write_comment_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/comment_fixtures.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
      ..on('GET /foods/1/comments', [
        FakeAdapter.ok(
          commentPageJson([
            commentJson(
              id: 11,
              author: '安安',
              text: '酸笋给得很大方',
              likes: 3,
              liked: true,
              replies: 3,
            ),
            commentJson(
              id: 12,
              author: 'Momo',
              authorId: verifiedUser.id,
              text: '中辣已经很够了',
              likes: 1,
            ),
          ], total: 2),
        ),
      ])
      ..on('GET /comments/11/replies', [
        FakeAdapter.ok(
          commentPageJson([
            replyJson(id: 21, author: '阿哲', text: '同意，加个炸蛋更香', ageMinutes: 20),
            replyJson(id: 22, author: 'Momo', text: '汤底够酸', ageMinutes: 10),
            replyJson(
              id: 23,
              replyTo: '阿哲',
              author: '天凉被破王',
              text: '炸蛋要早点说',
              ageMinutes: 5,
            ),
          ], total: 3),
        ),
      ]);
  });

  testWidgets('先露出最早的 2 条回复，回复别人的回复写「回复 某某」，展开看全部', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    expect(find.textContaining('吃过的人说'), findsOneWidget);
    expect(find.text('酸笋给得很大方'), findsOneWidget);
    expect(find.text('中辣已经很够了'), findsOneWidget);
    expect(find.textContaining('同意，加个炸蛋更香'), findsOneWidget);
    expect(find.textContaining('汤底够酸'), findsOneWidget);
    expect(find.textContaining('炸蛋要早点说'), findsNothing);
    expect(find.text('展开 1 条回复'), findsOneWidget);
    await expectAccessible(tester);
    // 回复的文字另起一行, 占满回复区的宽度, 不和右边的赞, "更多" 挤在一起.
    final replyText = tester.getRect(find.text('同意，加个炸蛋更香'));
    final more = tester.getRect(find.bySemanticsLabel('更多').at(1));
    expect(replyText.top, greaterThanOrEqualTo(more.bottom - 1));
    expect(replyText.left, lessThan(more.left));

    await tester.tap(find.text('展开 1 条回复'));
    await tester.pumpAndSettle();
    expect(find.textContaining('回复 阿哲'), findsOneWidget);
    expect(find.textContaining('炸蛋要早点说'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('回复数为 0 的评论不请求回复，也不逐条查询赞', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    expect(env.adapter.sent('GET /comments/11/replies'), hasLength(1));
    expect(env.adapter.sent('GET /comments/12/replies'), isEmpty);
    expect(env.adapter.sent('GET /comments/11/like'), isEmpty);
    expect(env.adapter.sent('GET /comments/my'), isEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('切到「最新」按最新排序重新请求', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.text('最新'));
    await tester.pumpAndSettle();
    final sorts = [
      for (final r in env.adapter.sent('GET /foods/1/comments'))
        r.query['sort'],
    ];
    expect(sorts, ['HOT', 'NEWEST']);
    await unmountApp(tester, container);
  });

  testWidgets('滑到底加载下一页', (tester) async {
    env.adapter.on('GET /foods/1/comments', [
      FakeAdapter.ok(
        commentPageJson(
          [commentJson(id: 12, text: '第一页')],
          total: 2,
          hasNext: true,
        ),
      ),
      FakeAdapter.ok(
        commentPageJson([commentJson(id: 13, text: '第二页')], page: 2, total: 2),
      ),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    expect(find.text('第二页'), findsOneWidget);
    final pages = [
      for (final r in env.adapter.sent('GET /foods/1/comments'))
        r.query['page'],
    ];
    expect(pages, [1, 2]);
    await tester.pump(const Duration(seconds: 1));
    await unmountApp(tester, container);
  });

  testWidgets('认证后给评论点赞：接口不返回计数，保留加一后的数', (tester) async {
    env.adapter.on('PUT /comments/12/like', [FakeAdapter.ok(null)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.bySemanticsLabel('赞，1'));
    await tester.pumpAndSettle();
    final sent = env.adapter.sent('PUT /comments/12/like').single;
    expect(sent.headers.containsKey('Idempotency-Key'), isFalse);
    expect(find.bySemanticsLabel('赞，2'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('列表标着赞过的评论，点一下是取消赞', (tester) async {
    env.adapter.on('DELETE /comments/11/like', [FakeAdapter.ok(null)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.bySemanticsLabel('赞，3'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE /comments/11/like'), hasLength(1));
    expect(env.adapter.sent('PUT /comments/11/like'), isEmpty);
    expect(find.bySemanticsLabel('赞，2'), findsWidgets);
    await unmountApp(tester, container);
  });

  testWidgets('点赞时评论已删除：提示并从列表中去掉', (tester) async {
    env.adapter.on('PUT /comments/12/like', [FakeAdapter.fail(10001)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.bySemanticsLabel('赞，1'));
    await tester.pumpAndSettle();
    expect(find.text('这条评论已删除'), findsOneWidget);
    expect(find.text('中辣已经很够了'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点赞和回复都弹拦截对话框，不发请求', (tester) async {
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.bySemanticsLabel('赞，1'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能点赞'), findsOneWidget);
    await tester.tap(find.text('先逛逛'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('回复').first);
    await tester.pumpAndSettle();
    expect(find.text('认证后才能回复'), findsOneWidget);
    expect(env.adapter.sent('PUT /comments/12/like'), isEmpty);
    expect(locationOf(router), Paths.comments(1));
    await unmountApp(tester, container);
  });

  testWidgets('自己的评论能删除：确认后从列表中去掉', (tester) async {
    env.adapter.on('DELETE /comments/12', [FakeAdapter.ok(null)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.bySemanticsLabel('更多').last);
    await tester.pumpAndSettle();
    expect(find.text('举报'), findsNothing);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这条评论？'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('DELETE /comments/12'), hasLength(1));
    expect(find.text('中辣已经很够了'), findsNothing);
    expect(find.text('已删除'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('别人的评论在「更多」里是举报', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.bySemanticsLabel('更多').first);
    await tester.pumpAndSettle();
    expect(find.text('删除'), findsNothing);
    await tester.tap(find.text('举报'));
    await tester.pumpAndSettle();
    expect(find.text('举报这条评论'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('举报时评论已删除：关闭面板，提示并从列表中去掉', (tester) async {
    env.adapter.on('POST /feedback/reports', [FakeAdapter.fail(10001)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.bySemanticsLabel('更多').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('举报'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('广告'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();
    expect(find.text('举报这条评论'), findsNothing);
    expect(find.text('这条评论已删除'), findsOneWidget);
    expect(find.text('酸笋给得很大方'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('底部输入栏进入写评论，相机按钮先选照片', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.text('吃过的话，说两句'));
    await tester.pumpAndSettle();
    final plain = tester.widget<WriteCommentPage>(
      find.byType(WriteCommentPage),
    );
    expect((plain.dishId, plain.rootId, plain.pickOnOpen), (1, null, false));
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('带照片写一条'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<WriteCommentPage>(find.byType(WriteCommentPage)).pickOnOpen,
      isTrue,
    );
    expect(find.text('从相册选'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('没有评论时说明下一步', (tester) async {
    env.adapter.on('GET /foods/1/comments', [
      FakeAdapter.ok(commentPageJson(const [])),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    expect(find.text('还没有人说过'), findsOneWidget);
    await expectAccessible(tester);
    await unmountApp(tester, container);
  });
}
