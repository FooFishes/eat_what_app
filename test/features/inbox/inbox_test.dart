import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/features/topic/topic_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';
import '../../support/topic_json.dart';

const _likeId = '6f1c1c9e-0000-4000-8000-000000000001';
const _followId = '6f1c1c9e-0000-4000-8000-000000000002';
const _topicId = '6f1c1c9e-0000-4000-8000-000000000003';
const _caseId = '6f1c1c9e-0000-4000-8000-000000000004';

/// 他人资料 `/user/userInfo` 的响应数据: 对方关注了我.
Map<String, Object?> _profile({bool followedByMe = false}) => {
  'displayName': '阿哲',
  'avatar': null,
  'earnedLikes': 0,
  'fansCount': 1,
  'followingsCount': 1,
  'fansVisible': true,
  'followingsVisible': true,
  'isFollowingMe': true,
  'isFollowingHim': followedByMe,
  'uploadedRestaurantsCount': 0,
  'uploadedFoodsCount': 0,
};

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

    expect(find.text('2 条未读'), findsOneWidget);
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

  testWidgets('「系统」分栏：不跳转的处理结果点了只标已读；专题收录点进专题页', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(
              id: _topicId,
              column: 'SYSTEM',
              kind: 'topic_included',
              domain: 'topics',
              targetId: 7,
              actors: const [],
              detail: {
                'type': 'topic_included',
                'foodId': 1,
                'foodName': '玉米鲜肉饺子',
                'topicId': 7,
                'topicName': '期末续命餐',
                'foodUnavailable': false,
                'topicUnavailable': false,
              },
            ),
            noticeCardJson(
              id: _caseId,
              column: 'SYSTEM',
              kind: 'case_result',
              domain: 'report',
              targetId: 5,
              actors: const [],
              detail: {
                'type': 'case_result',
                'caseId': 5,
                'outcome': 'ACCEPTED',
                'reasonCode': 'ADVERTISING',
                'kind': 'REPORT',
                'reply': '',
              },
            ),
          ]),
        ),
      ])
      ..on('POST /notification/cards/$_topicId/read', [FakeAdapter.ok()])
      ..on('POST /notification/cards/$_caseId/read', [FakeAdapter.ok()])
      ..on('GET /topics/7', [FakeAdapter.ok(topicDetailJson())]);
    final (container, _) = await pumpApp(
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
    expect(find.text('你举报的内容已处理'), findsOneWidget);
    await expectAccessible(tester);

    final handle = tester.ensureSemantics();
    final caseRow = tester.getSemantics(find.text('你举报的内容已处理'));
    expect(caseRow.hintOverrides?.onTapHint, '标为已读', reason: '不跳转的行读作「标为已读」');
    expect(caseRow.getSemanticsData().flagsCollection.isButton, isFalse);
    final topicRow = tester.getSemantics(
      find.text('你上传的「玉米鲜肉饺子」已被收录到专题「期末续命餐」'),
    );
    expect(topicRow.hintOverrides, isNull, reason: '会跳转的行使用平台默认的说法');

    await tester.tap(find.text('你举报的内容已处理'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /notification/cards/$_caseId/read'),
      hasLength(1),
    );
    expect(find.text('你举报的内容已处理'), findsOneWidget, reason: '不跳转，留在消息页');
    expect(find.byType(UnreadDot), findsOneWidget, reason: '只剩专题收录那一行未读');
    handle.dispose();

    await tester.tap(find.text('你上传的「玉米鲜肉饺子」已被收录到专题「期末续命餐」'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /notification/cards/$_topicId/read'),
      hasLength(1),
    );
    expect(tester.widget<TopicPage>(find.byType(TopicPage)).topicId, 7);
    await unmountApp(tester, container);
  });

  testWidgets('评论消息点进菜品详情并滚到那一条评论', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(
          pageJson([
            noticeCardJson(
              id: _likeId,
              column: 'COMMENTS',
              kind: 'comment',
              detail: {
                'type': 'comment',
                'foodId': 1,
                'commentId': 300,
                'replyId': null,
                'unavailable': false,
              },
            ),
          ]),
        ),
      ])
      ..on('POST /notification/cards/$_likeId/read', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.inbox,
    );

    await tester.tap(find.textContaining('评论了你上传的菜', findRichText: true));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /notification/cards/$_likeId/read'),
      hasLength(1),
    );
    final page = tester.widget<DishPage>(find.byType(DishPage));
    expect(page.dishId, 1);
    expect(page.focusComment, 300);
    await unmountApp(tester, container);
  });

  testWidgets('「全部已读」标记旧版通知和已加载的未读行', (tester) async {
    env.adapter
      ..on('GET /notification/cards', [
        FakeAdapter.ok(pageJson([noticeCardJson(id: _likeId)])),
      ])
      ..on('POST /notification/read/all', [FakeAdapter.ok()])
      ..on('POST /notification/cards/$_likeId/read', [FakeAdapter.ok()]);
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
    expect(env.adapter.sent('POST /notification/read/all'), hasLength(1));
    expect(
      env.adapter.sent('POST /notification/cards/$_likeId/read'),
      hasLength(1),
    );
    expect(find.byType(UnreadDot), findsNothing);
    expect(find.text('2 条未读'), findsNothing);
    await unmountApp(tester, container);
  });
}
