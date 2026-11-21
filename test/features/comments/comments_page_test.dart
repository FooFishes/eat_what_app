import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/like_heart.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../../support/app.dart';
import '../../support/comment_fixtures.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

final replies = [
  replyJson(id: 21, author: '阿哲', text: '同意，加个炸蛋更香', ageMinutes: 20),
  replyJson(id: 22, author: 'Momo', text: '汤底够酸', ageMinutes: 10),
  replyJson(
    id: 23,
    replyTo: '阿哲',
    author: '天凉被破王',
    text: '炸蛋要早点说',
    ageMinutes: 5,
  ),
];

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
          commentPageJson(replies.take(2).toList(), total: 3, hasNext: true),
        ),
        FakeAdapter.ok(commentPageJson(replies, total: 3)),
      ]);
  });

  testWidgets('先露出最早的 2 条回复，回复别人的回复写成「A ▸ B」，展开看全部', (tester) async {
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
    // 回复挂在评论下面, 和评论的正文对齐.
    final rootText = tester.getRect(find.text('酸笋给得很大方'));
    final replyText = tester.getRect(find.text('同意，加个炸蛋更香'));
    expect(replyText.left, greaterThan(rootText.left - 1));
    expect(replyText.top, greaterThan(rootText.bottom));

    await tester.tap(find.text('展开 1 条回复'));
    await tester.pumpAndSettle();
    expect(find.textContaining('阿哲'), findsNWidgets(2));
    expect(find.textContaining('炸蛋要早点说'), findsOneWidget);
    await unmountApp(tester, container);
  });

  group('回复分页', () {
    List<Map<String, dynamic>> sentReplies() => [
      for (final r in env.adapter.sent('GET /comments/11/replies')) r.query,
    ];

    testWidgets('起初只取预览的 2 条；展开时重新取第 1 页的 20 条换掉预览', (tester) async {
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );
      expect(sentReplies(), [
        {'page': 1, 'pageSize': 2},
      ]);

      await tester.tap(find.text('展开 1 条回复'));
      await tester.pumpAndSettle();
      expect(sentReplies(), [
        {'page': 1, 'pageSize': 2},
        {'page': 1, 'pageSize': 20},
      ]);
      expect(find.textContaining('同意，加个炸蛋更香'), findsOneWidget);
      expect(find.textContaining('炸蛋要早点说'), findsOneWidget);
      expect(find.text('收起'), findsOneWidget);

      await tester.tap(find.text('收起'));
      await tester.pumpAndSettle();
      expect(find.textContaining('炸蛋要早点说'), findsNothing);
      expect(find.text('展开 1 条回复'), findsOneWidget);
      await tester.tap(find.text('展开 1 条回复'));
      await tester.pumpAndSettle();
      expect(find.textContaining('炸蛋要早点说'), findsOneWidget);
      expect(sentReplies(), hasLength(2), reason: '收起再展开不重新请求');
      await unmountApp(tester, container);
    });

    testWidgets('展开后的「展开更多」取第 2 页追加', (tester) async {
      env.adapter.on('GET /comments/11/replies', [
        FakeAdapter.ok(
          commentPageJson(replies.take(2).toList(), total: 23, hasNext: true),
        ),
        FakeAdapter.ok(
          commentPageJson(replies.take(2).toList(), total: 23, hasNext: true),
        ),
        FakeAdapter.ok(commentPageJson([replies[2]], page: 2, total: 23)),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );

      await tester.tap(find.text('展开 21 条回复'));
      await tester.pumpAndSettle();
      expect(find.text('展开更多'), findsOneWidget);
      await tester.tap(find.text('展开更多'));
      await tester.pumpAndSettle();
      expect(sentReplies(), [
        {'page': 1, 'pageSize': 2},
        {'page': 1, 'pageSize': 20},
        {'page': 2, 'pageSize': 20},
      ]);
      expect(find.textContaining('同意，加个炸蛋更香'), findsOneWidget);
      expect(find.textContaining('炸蛋要早点说'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('展开时加载失败，预览留着，按钮变成重试', (tester) async {
      env.adapter.on('GET /comments/11/replies', [
        FakeAdapter.ok(
          commentPageJson(replies.take(2).toList(), total: 3, hasNext: true),
        ),
        const FakeResponse.offline(),
        FakeAdapter.ok(commentPageJson(replies, total: 3)),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );

      await tester.tap(find.text('展开 1 条回复'));
      await tester.pumpAndSettle();
      expect(find.textContaining('同意，加个炸蛋更香'), findsOneWidget);
      expect(find.textContaining('汤底够酸'), findsOneWidget);
      expect(find.text('加载失败，重试'), findsOneWidget);

      await tester.tap(find.text('加载失败，重试'));
      await tester.pumpAndSettle();
      expect(find.textContaining('炸蛋要早点说'), findsOneWidget);
      expect(find.text('收起'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('展开着发回复，重新取完整的第 1 页，新回复留在眼前', (tester) async {
      env.adapter
        ..on('POST /foods/1/comments/11/replies', [
          FakeAdapter.ok(createdJson(id: 30)),
        ])
        ..on('GET /comments/11/replies', [
          FakeAdapter.ok(
            commentPageJson(replies.take(2).toList(), total: 3, hasNext: true),
          ),
          FakeAdapter.ok(commentPageJson(replies, total: 3)),
          FakeAdapter.ok(
            commentPageJson([
              ...replies,
              replyJson(id: 30, author: '小鱼', text: '我也觉得'),
            ], total: 4),
          ),
        ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );
      await tester.tap(find.text('展开 1 条回复'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('酸笋给得很大方'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '我也觉得');
      await tester.pump();
      await tester.tap(find.text('发送'));
      await tester.pumpAndSettle();

      expect(sentReplies().last, {'page': 1, 'pageSize': 20});
      expect(find.textContaining('我也觉得'), findsOneWidget);
      expect(find.textContaining('炸蛋要早点说'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });
  });

  testWidgets('点正文是回复，长按打开「更多」的菜单', (tester) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.comments(1),
    );

    await tester.tap(find.text('酸笋给得很大方'));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsOneWidget);
    await tester.tapAt(const Offset(5, 200));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsNothing);

    await tester.longPress(find.text('酸笋给得很大方'));
    await tester.pumpAndSettle();
    expect(find.text('这条评论'), findsOneWidget);
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
    await settle(tester);
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
    env.adapter.on('PUT /comments/12/like', [FakeAdapter.fail(10001, '评论不存在')]);
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

    await tester.tap(find.bySemanticsLabel('回复').first);
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
    env.adapter.on('POST /feedback/reports', [
      FakeAdapter.fail(10001, '评论不存在'),
    ]);
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

  group('表情回应', () {
    setUp(() {
      env.adapter.on('GET /foods/1/comments', [
        FakeAdapter.ok(
          commentPageJson([
            commentJson(
              id: 11,
              replies: 1,
              reactions: [
                reactionJson('HEART', 1, selected: true),
                reactionJson('YUMMY', 2),
              ],
            ),
          ]),
        ),
      ]);
      env.adapter.on('GET /comments/11/replies', [
        FakeAdapter.ok(commentPageJson([replyJson(id: 21)])),
      ]);
    });

    testWidgets('有人回应过的显示成「表情 人数」；点别的一种换过去，计数以接口返回为准', (tester) async {
      env.adapter.on('PUT /comments/11/reactions/YUMMY', [
        FakeAdapter.ok([reactionJson('YUMMY', 3, selected: true)]),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );

      expect(find.bySemanticsLabel('爱心，1'), findsOneWidget);
      expect(find.bySemanticsLabel('好吃，2'), findsOneWidget);
      await expectAccessible(tester);

      await tester.ensureVisible(find.bySemanticsLabel('好吃，2'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('好吃，2'));
      await tester.pumpAndSettle();
      expect(
        env.adapter.sent('PUT /comments/11/reactions/YUMMY'),
        hasLength(1),
      );
      expect(find.bySemanticsLabel('好吃，3'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^爱心')), findsNothing);
      await unmountApp(tester, container);
    });

    testWidgets('点自己选过的那种是取消；失败时恢复并提示', (tester) async {
      env.adapter.on('DELETE /comments/11/reactions/HEART', [
        FakeAdapter.fail(10002, '无法回应这条评论'),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );

      await tester.tap(find.bySemanticsLabel('爱心，1'));
      await tester.pumpAndSettle();
      expect(
        env.adapter.sent('DELETE /comments/11/reactions/HEART'),
        hasLength(1),
      );
      expect(find.bySemanticsLabel('爱心，1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('「回应」从按钮展开成卡片，选一种卡片就收回；回复也有「回应」', (tester) async {
      env.adapter
        ..on('PUT /comments/11/reactions/SURPRISED', [
          FakeAdapter.ok([
            reactionJson('SURPRISED', 1, selected: true),
            reactionJson('YUMMY', 2),
          ]),
        ])
        ..on('PUT /comments/21/reactions/LAUGH', [
          FakeAdapter.ok([reactionJson('LAUGH', 1, selected: true)]),
        ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );

      await tester.tap(find.text('回应').first);
      await tester.pumpAndSettle();
      expect(find.text('回应这条评论'), findsOneWidget);
      await expectAccessible(tester);
      await tester.tap(find.bySemanticsLabel('惊讶，0'));
      await tester.pumpAndSettle();
      expect(find.text('回应这条评论'), findsNothing, reason: '选完卡片收回');
      expect(
        env.adapter.sent('PUT /comments/11/reactions/SURPRISED'),
        hasLength(1),
      );
      expect(find.bySemanticsLabel('惊讶，1'), findsOneWidget);

      await tester.tap(find.text('回应').last);
      await tester.pumpAndSettle();
      expect(find.text('回应这条回复'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('笑哭，0'));
      await tester.pumpAndSettle();
      expect(find.text('回应这条回复'), findsNothing);
      expect(
        env.adapter.sent('PUT /comments/21/reactions/LAUGH'),
        hasLength(1),
      );
      expect(find.bySemanticsLabel('笑哭，1'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('在卡片里取消自己选过的那种，卡片也收回；失败时照样恢复并提示', (tester) async {
      env.adapter.on('DELETE /comments/11/reactions/HEART', [
        FakeAdapter.fail(10002, '无法回应这条评论'),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );

      await tester.tap(find.text('回应').first);
      await tester.pumpAndSettle();
      expect(find.text('回应这条评论'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('爱心，1').last);
      await tester.pumpAndSettle();
      expect(find.text('回应这条评论'), findsNothing);
      expect(
        env.adapter.sent('DELETE /comments/11/reactions/HEART'),
        hasLength(1),
      );
      expect(find.text('无法回应这条评论'), findsOneWidget);
      expect(find.bySemanticsLabel('爱心，1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('点在卡片外面或右上角关闭，什么都不选', (tester) async {
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );

      await tester.tap(find.text('回应').first);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('关闭'));
      await tester.pumpAndSettle();
      expect(find.text('回应这条评论'), findsNothing);

      await tester.tap(find.text('回应').first);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('回应这条评论'), findsNothing);
      expect(
        env.adapter.requests.where((r) => r.route.contains('/reactions/')),
        isEmpty,
      );
      await unmountApp(tester, container);
    });

    testWidgets('没认证时点「回应」弹拦截对话框，不发请求', (tester) async {
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: testUser),
        location: Paths.comments(1),
      );

      await tester.tap(find.text('回应').first);
      await tester.pumpAndSettle();
      expect(find.text('认证后才能回应'), findsOneWidget);
      expect(find.text('回应这条评论'), findsNothing);
      await unmountApp(tester, container);
    });
    testWidgets('回应胶囊排在正文下面、时间和赞上面，挨得紧，每个都完整露出', (tester) async {
      const labels = ['大拇指，1', '爱心，2', '笑哭，3', '惊讶，4', '难过，5', '好吃，6'];
      env.adapter.on('GET /foods/1/comments', [
        FakeAdapter.ok(
          commentPageJson([
            commentJson(
              id: 11,
              reactions: [
                reactionJson('THUMBS_UP', 1),
                reactionJson('HEART', 2),
                reactionJson('LAUGH', 3),
                reactionJson('SURPRISED', 4),
                reactionJson('SAD', 5),
                reactionJson('YUMMY', 6),
              ],
            ),
          ]),
        ),
      ]);
      const screen = Size(375, 812);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
        size: screen,
      );

      final text = tester.getRect(find.text('酸笋给得很大方'));
      final react = tester.getRect(find.text('回应').first);
      final heart = tester.getRect(find.byType(LikeHeart).first);
      final capsules = [for (final label in labels) _capsule(tester, label)];
      for (final (i, capsule) in capsules.indexed) {
        final label = labels[i];
        expect(capsule.top, greaterThanOrEqualTo(text.bottom), reason: label);
        expect(capsule.bottom, lessThanOrEqualTo(react.top), reason: label);
        expect(capsule.bottom, lessThanOrEqualTo(heart.top), reason: label);
        expect(capsule.left, greaterThanOrEqualTo(0), reason: label);
        expect(capsule.right, lessThanOrEqualTo(screen.width), reason: label);
      }

      final runs = <(double, double)>{
        for (final c in capsules) (c.top, c.bottom),
      }.toList()..sort((a, b) => a.$1.compareTo(b.$1));
      expect(runs.length, greaterThan(1), reason: '放不下时折行');
      const tight = EatSpace.s8;
      expect(runs.first.$1 - text.bottom, inInclusiveRange(0, tight));
      expect(react.top - runs.last.$2, inInclusiveRange(0, tight));
      for (var i = 1; i < runs.length; i++) {
        expect(runs[i].$1 - runs[i - 1].$2, inInclusiveRange(0, tight));
      }
      await unmountApp(tester, container);
    });

    testWidgets('胶囊看得见的边外面几 px 也能点中，不会点到下面的「回应」', (tester) async {
      List<Map<String, Object?>> reactions(
        int yummy, {
        bool selected = false,
      }) => [
        reactionJson('THUMBS_UP', 1),
        reactionJson('SAD', 1),
        reactionJson('YUMMY', yummy, selected: selected),
      ];
      env.adapter
        ..on('GET /foods/1/comments', [
          FakeAdapter.ok(
            commentPageJson([commentJson(id: 11, reactions: reactions(2))]),
          ),
        ])
        ..on('PUT /comments/11/reactions/YUMMY', [
          FakeAdapter.ok(reactions(3, selected: true)),
        ])
        ..on('DELETE /comments/11/reactions/YUMMY', [
          FakeAdapter.ok(reactions(2)),
        ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );

      // 第三个胶囊正好压在「回应」上面.
      final below = _capsule(tester, '好吃，2');
      final react = tester.getRect(find.text('回应').first);
      expect(below.left, lessThan(react.right));
      expect(below.right, greaterThan(react.left));
      await tester.tapAt(Offset(below.center.dx, below.bottom + 3));
      await tester.pumpAndSettle();
      expect(
        env.adapter.sent('PUT /comments/11/reactions/YUMMY'),
        hasLength(1),
      );
      expect(find.text('回应这条评论'), findsNothing);

      final above = _capsule(tester, '好吃，3');
      await tester.tapAt(Offset(above.center.dx, above.top - 3));
      await tester.pumpAndSettle();
      expect(
        env.adapter.sent('DELETE /comments/11/reactions/YUMMY'),
        hasLength(1),
      );
      expect(find.byType(EditableText), findsNothing, reason: '没点到正文');
      await unmountApp(tester, container);
    });

    testWidgets('有胶囊时「回应」、赞和正文照常能点', (tester) async {
      env.adapter.on('PUT /comments/11/like', [FakeAdapter.ok(null)]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
      );

      await tester.tap(find.text('回应').first);
      await tester.pumpAndSettle();
      expect(find.text('回应这条评论'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('关闭'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LikeHeart).first);
      await tester.pumpAndSettle();
      expect(env.adapter.sent('PUT /comments/11/like'), hasLength(1));

      await tester.tap(find.text('酸笋给得很大方'));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);
      expect(
        env.adapter.requests.where((r) => r.route.contains('/reactions/')),
        isEmpty,
      );
      await unmountApp(tester, container);
    });

    testWidgets('窄屏大字号下跨年的日期截断，不溢出', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      env.adapter.on('GET /foods/1/comments', [
        FakeAdapter.ok(
          commentPageJson([
            commentJson(
              id: 11,
              ageMinutes: 400 * 24 * 60,
              reactions: [reactionJson('HEART', 1), reactionJson('YUMMY', 2)],
            ),
          ]),
        ),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.comments(1),
        size: const Size(320, 640),
      );

      expect(find.textContaining(' 年 '), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmountApp(tester, container);
    });
  });
}

/// 回应胶囊看得见的那一截, 它的点击区比这高.
Rect _capsule(WidgetTester tester, String label) => tester.getRect(
  find
      .descendant(
        of: find.bySemanticsLabel(label),
        matching: find.byType(DecoratedBox),
      )
      .first,
);
