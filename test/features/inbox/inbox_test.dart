import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/comment_fixtures.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';
import '../../support/topic_json.dart';

const _likeId = 101;
const _followId = 102;
const _announceId = 103;
const _caseId = 104;
const _replyId = 105;

/// 他人资料 `/user/userInfo` 的响应数据: 对方关注了我.
Map<String, Object?> _profile({bool followedByMe = false}) => {
  'id': 9,
  'displayName': '阿哲',
  'avatar': null,
  'signature': '',
  'fansCount': 1,
  'followingsCount': 1,
  'fansVisible': true,
  'followingsVisible': true,
  'isFollowingMe': true,
  'isFollowingHim': followedByMe,
  'blocked': false,
};

Map<String, Object?> _caseCard({int id = _caseId, int caseId = 5}) =>
    noticeCardJson(
      id: id,
      column: 'SYSTEM',
      kind: 'case_result',
      domain: 'report',
      targetId: caseId,
      actors: const [],
      data: {
        'type': 'case_result',
        'caseId': caseId,
        'kind': 'REPORT',
        'outcome': 'ACCEPTED',
        'reasonCode': 'ADVERTISING',
        'reply': '',
      },
    );

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter.on('GET /notification/cards/unread/count', [
      FakeAdapter.ok({'cards': 2, 'members': 13}),
    ]);
  });

  testWidgets('写未读行数；同类消息合并成「等 n 人」；点一行算读过并进对应的菜', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(
              id: _likeId,
              members: 12,
              unread: 3,
              actors: [actorJson(6, 'Momo'), actorJson(5, '小林')],
            ),
            noticeCardJson(
              id: _followId,
              column: 'FOLLOWS',
              kind: 'follow',
              domain: 'users',
              unread: 0,
              latestAt: DateTime.now().subtract(const Duration(days: 30)),
              actors: [actorJson(9, '阿哲')],
            ),
          ]),
        ),
      ])
      ..on('GET /user/userInfo', [FakeAdapter.ok(_profile())])
      ..on('POST /notification/cards/$_likeId/read', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    expect(find.textContaining('2 条未读', findRichText: true), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('更早'), findsOneWidget);
    expect(
      find.textContaining('Momo 等 12 人 赞了你上传的菜', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(UnreadDot), findsOneWidget);
    expect(find.text('回关'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.textContaining('赞了你上传的菜', findRichText: true));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /notification/cards/$_likeId/read'),
      hasLength(1),
    );
    expect(env.adapter.sent('GET /foods/detail/1'), hasLength(1));
    await unmountApp(tester, container);
  });

  testWidgets('关注消息点「回关」后变「已互关」', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(
              id: _followId,
              column: 'FOLLOWS',
              kind: 'follow',
              domain: 'users',
              actors: [actorJson(9, '阿哲')],
            ),
          ]),
        ),
      ])
      ..on('GET /user/userInfo', [
        FakeAdapter.ok(_profile()),
        FakeAdapter.ok(_profile(followedByMe: true)),
      ])
      ..on('POST /user/follow', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    await tester.tap(find.text('回关'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /user/follow').single.query,
      containsPair('userId', 9),
    );
    expect(find.text('已互关'), findsOneWidget);
    expect(
      env.adapter.sent('POST /notification/cards/$_followId/read'),
      isEmpty,
      reason: '回关是独立的按钮，不算点了这一行',
    );
    await unmountApp(tester, container);
  });

  testWidgets('回关时被对方屏蔽：提示无法关注，按钮恢复', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(
              id: _followId,
              column: 'FOLLOWS',
              kind: 'follow',
              domain: 'users',
              actors: [actorJson(9, '阿哲')],
            ),
          ]),
        ),
      ])
      ..on('GET /user/userInfo', [FakeAdapter.ok(_profile())])
      ..on('POST /user/follow', [FakeAdapter.fail(40002)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    await tester.tap(find.text('回关'));
    await tester.pumpAndSettle();
    expect(find.text('无法关注对方'), findsOneWidget);
    expect(find.text('回关'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('「系统」分栏：公告显示标题和内容，点了只标已读；处理结果点链接进我的反馈详情', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(
              id: _announceId,
              column: 'SYSTEM',
              kind: 'announcement',
              domain: 'announcements',
              targetId: 9,
              actors: const [],
              data: {
                'type': 'announcement',
                'level': 'NORMAL',
                'title': '食堂二楼周末停业',
                'content': '周六周日暂停营业。',
              },
            ),
            _caseCard(),
          ]),
        ),
      ])
      ..on('POST /notification/cards/$_announceId/read', [FakeAdapter.ok()])
      ..on('POST /notification/cards/$_caseId/read', [FakeAdapter.ok()])
      ..on('GET /feedback/mine/5', [
        FakeAdapter.ok({
          'id': 5,
          'kind': 'REPORT',
          'status': 'CLOSED',
          'target': {'type': 'FOOD', 'id': 1},
          'reason': 'ADVERTISING',
          'text': '',
          'screenshots': const [],
          'outcome': 'ACCEPTED',
          'reply': '',
          'createdAt': 0,
          'closedAt': 0,
        }),
      ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    // 切换分栏触发的请求在当前帧之后发出. 单独调用 pumpAndSettle 时, 断言执行前该请求尚未发出.
    await tester.tap(find.text('系统'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('GET /notification/cards').map((r) => r.query['column']),
      ['ALL', 'SYSTEM'],
    );
    expect(find.text('食堂二楼周末停业'), findsOneWidget);
    expect(find.text('周六周日暂停营业。'), findsOneWidget);
    expect(find.text('你举报的内容已处理'), findsOneWidget);
    await expectAccessible(tester);

    final handle = tester.ensureSemantics();
    final announceRow = tester.getSemantics(find.text('食堂二楼周末停业'));
    expect(
      announceRow.hintOverrides?.onTapHint,
      '标为已读',
      reason: '不跳转的行读作「标为已读」',
    );
    handle.dispose();

    await tester.tap(find.text('食堂二楼周末停业'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /notification/cards/$_announceId/read'),
      hasLength(1),
    );
    expect(find.text('食堂二楼周末停业'), findsOneWidget, reason: '不跳转，留在消息页');

    await tester.tap(find.text('你举报的内容已处理'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /notification/cards/$_caseId/read'),
      hasLength(1),
    );
    expect(
      router.state.uri.toString(),
      Paths.inbox,
      reason: '有操作链接的系统消息点整行只标已读',
    );

    await tester.tap(find.text('查看处理详情'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /notification/cards/$_caseId/read'),
      hasLength(1),
      reason: '已读过的消息不再请求',
    );
    expect(router.state.uri.toString(), Paths.myFeedbackCase(5));
    expect(env.adapter.sent('GET /feedback/mine/5'), hasLength(1));
    await unmountApp(tester, container);
  });

  testWidgets('处理结果关于评论时也进我的反馈详情', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(pageJson([_caseCard()])),
      ])
      ..on('POST /notification/cards/$_caseId/read', [FakeAdapter.ok()])
      ..on('GET /feedback/mine/5', [
        FakeAdapter.ok({
          'id': 5,
          'kind': 'REPORT',
          'target': {'type': 'COMMENT', 'id': 300},
        }),
      ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    await tester.tap(find.text('查看处理详情'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), Paths.myFeedbackCase(5));
    expect(
      env.adapter.sent('POST /notification/cards/$_caseId/read'),
      hasLength(1),
      reason: '点链接也算读过',
    );
    await unmountApp(tester, container);
  });

  testWidgets('新设备登录把设备名和提醒放进详情块；点详情块进登录设备', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(
              id: _caseId,
              column: 'SYSTEM',
              kind: 'new_device_login',
              domain: 'sessions',
              actors: const [],
              data: {
                'type': 'new_device_login',
                'deviceName': 'iPad Pro 12-Inch 3',
                'device': 'IOS',
              },
            ),
          ]),
        ),
      ])
      ..on('POST /notification/cards/$_caseId/read', [FakeAdapter.ok()]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    expect(find.text('iPad Pro 12-Inch 3'), findsOneWidget);
    expect(find.text('不是本人登录时，可以让它下线'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('iPad Pro 12-Inch 3'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), Paths.settingsDevices);
    expect(
      env.adapter.sent('POST /notification/cards/$_caseId/read'),
      hasLength(1),
    );
    await unmountApp(tester, container);
  });

  testWidgets('评论消息点进菜品详情；回复消息进菜品详情并滚到根评论，没有菜 id 的只标已读', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(id: _likeId, column: 'COMMENTS', kind: 'comment'),
            noticeCardJson(
              id: _followId,
              column: 'COMMENTS',
              kind: 'reply',
              domain: 'comments',
              targetId: 300,
              actors: [actorJson(9, '阿哲')],
            ),
            noticeCardJson(
              id: _replyId,
              column: 'COMMENTS',
              kind: 'reply',
              domain: 'comments',
              targetId: 301,
              actors: [actorJson(10, '小周')],
              data: {'foodId': 7},
            ),
          ]),
        ),
      ])
      ..on('POST /notification/cards/$_likeId/read', [FakeAdapter.ok()])
      ..on('POST /notification/cards/$_followId/read', [FakeAdapter.ok()])
      ..on('POST /notification/cards/$_replyId/read', [FakeAdapter.ok()]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    await tester.tap(find.textContaining('阿哲', findRichText: true));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /notification/cards/$_followId/read'),
      hasLength(1),
    );
    expect(locationOf(router), Paths.inbox);

    await tester.tap(find.textContaining('评论了你上传的菜', findRichText: true));
    await tester.pumpAndSettle();
    final page = tester.widget<DishPage>(find.byType(DishPage));
    expect(page.dishId, 1);
    expect(page.focusComment, isNull);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('小周', findRichText: true));
    await tester.pumpAndSettle();
    final reply = tester.widget<DishPage>(find.byType(DishPage));
    expect(reply.dishId, 7);
    expect(reply.focusComment, 301);
    await unmountApp(tester, container);
  });

  testWidgets('评论赞的消息先读评论再进菜品详情，回复滚到根评论', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(
              id: _likeId,
              kind: 'comment_like',
              domain: 'comments',
              targetId: 302,
            ),
          ]),
        ),
      ])
      ..on('POST /notification/cards/$_likeId/read', [FakeAdapter.ok()])
      ..on('GET /comments/302', [
        FakeAdapter.ok(commentJson(id: 302, foodId: 7, root: 300)),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    await tester.tap(find.textContaining('赞了你的评论', findRichText: true));
    await tester.tap(find.textContaining('赞了你的评论', findRichText: true));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('GET /comments/302'),
      hasLength(1),
      reason: '读取期间再点不重复请求',
    );
    final page = tester.widget<DishPage>(find.byType(DishPage));
    expect(page.dishId, 7);
    expect(page.focusComment, 300);
    await unmountApp(tester, container);
  });

  testWidgets('评论赞的评论已删除或不可见：提示后留在消息页', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(
              id: _likeId,
              kind: 'comment_like',
              domain: 'comments',
              targetId: 302,
            ),
          ]),
        ),
      ])
      ..on('POST /notification/cards/$_likeId/read', [FakeAdapter.ok()])
      ..on('GET /comments/302', [FakeAdapter.fail(10001)]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    await tester.tap(find.textContaining('赞了你的评论', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('这条评论已删除或不可见'), findsOneWidget);
    expect(locationOf(router), Paths.inbox);
    expect(find.byType(DishPage), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('「全部已读」只请求一次，带当前分栏', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(pageJson([noticeCardJson(id: _likeId)])),
      ])
      ..on('POST /notification/cards/read-all', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    env.adapter.on('GET /notification/cards/unread/count', [
      FakeAdapter.ok({'cards': 0, 'members': 0}),
    ]);
    await tester.tap(find.text('全部已读'));
    await tester.pumpAndSettle();
    final sent = env.adapter.sent('POST /notification/cards/read-all');
    expect(sent.single.query, {'column': 'ALL'});
    expect(env.adapter.sent('POST /notification/cards/$_likeId/read'), isEmpty);
    expect(find.byType(UnreadDot), findsNothing);
    expect(find.textContaining('2 条未读', findRichText: true), findsNothing);
    await unmountApp(tester, container);
  });
}
