import 'package:eat/data/notification/notification_api.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/topic_json.dart';

void main() {
  test('按分栏请求消息卡片，合并的人数、互动者和已读状态都带上', () async {
    final env = TestEnv();
    env.adapter.on('GET /notification/cards', [
      FakeAdapter.ok(
        pageJson([
          noticeCardJson(
            members: 12,
            unread: 0,
            actors: [actorJson(6, 'Momo'), actorJson(5, '小林')],
          ),
        ]),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(notificationRepositoryProvider)
        .list(NoticeColumn.likes, page: 2);
    final notice = page.items.single;
    expect(notice.kind, NoticeKind.like);
    expect(notice.targetDomain, 'foods');
    expect(notice.memberCount, 12);
    expect(notice.read, isTrue);
    expect(notice.actors.map((a) => a.name), ['Momo', '小林']);
    final query = env.adapter.sent('GET /notification/cards').single.query;
    expect(query, containsPair('column', 'LIKES_AND_FAVORITES'));
    expect(query, containsPair('page', 2));
  });

  test('系统消息按 detail 的 type 解析出专题收录和处理结果', () async {
    final env = TestEnv();
    env.adapter.on('GET /notification/cards', [
      FakeAdapter.ok(
        pageJson([
          noticeCardJson(
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
            id: '6f1c1c9e-0000-4000-8000-000000000002',
            column: 'SYSTEM',
            kind: 'case_result',
            domain: 'catalog_error',
            targetId: 5,
            actors: const [],
            detail: {
              'type': 'case_result',
              'caseId': 5,
              'outcome': 'ACCEPTED',
              'reasonCode': 'WRONG_NAME',
              'kind': 'CATALOG_ERROR',
              'reply': '已修正',
            },
          ),
        ]),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(notificationRepositoryProvider)
        .list(NoticeColumn.system);
    final [topic, result] = page.items;
    expect(
      topic.detail,
      isA<TopicIncludedDetail>()
          .having((d) => d.topicId, 'topicId', 7)
          .having((d) => d.dishName, 'dishName', '玉米鲜肉饺子'),
    );
    expect(
      result.detail,
      isA<CaseResultDetail>()
          .having((d) => d.kind, 'kind', CaseKind.catalogError)
          .having((d) => d.reply, 'reply', '已修正'),
    );
  });

  test('专题撤下时专题 id 为空', () async {
    final env = TestEnv();
    env.adapter.on('GET /notification/cards', [
      FakeAdapter.ok(
        pageJson([
          noticeCardJson(
            kind: 'topic_included',
            domain: 'topics',
            actors: const [],
            detail: {
              'type': 'topic_included',
              'foodId': null,
              'foodName': '菜品已不可用',
              'topicId': null,
              'topicName': '专题已不可用',
              'foodUnavailable': true,
              'topicUnavailable': true,
            },
          ),
        ]),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(notificationRepositoryProvider)
        .list(NoticeColumn.all);
    final detail = page.items.single.detail! as TopicIncludedDetail;
    expect(detail.topicId, isNull);
    expect(detail.dishId, isNull);
  });

  test('未读数取有未读的行数；标记已读用卡片 id', () async {
    final env = TestEnv();
    env.adapter
      ..on('GET /notification/cards/unread/count', [
        FakeAdapter.ok({'cards': 3, 'members': 15}),
      ])
      ..on('POST /notification/cards/abc/read', [FakeAdapter.ok()]);
    final container = await env.container();
    final repository = container.read(notificationRepositoryProvider);

    expect(await repository.unreadCount(), 3);
    await repository.read('abc');
    expect(env.adapter.sent('POST /notification/cards/abc/read'), hasLength(1));
  });

  test('全部已读标记旧版通知，并逐行标记已加载的未读卡片', () async {
    final env = TestEnv();
    env.adapter
      ..on('POST /notification/read/all', [FakeAdapter.ok()])
      ..on('POST /notification/cards/a/read', [FakeAdapter.ok()])
      ..on('POST /notification/cards/b/read', [FakeAdapter.ok()]);
    final container = await env.container();

    await container.read(notificationRepositoryProvider).readAll(['a', 'b']);
    expect(env.adapter.sent('POST /notification/read/all'), hasLength(1));
    expect(env.adapter.sent('POST /notification/cards/a/read'), hasLength(1));
    expect(env.adapter.sent('POST /notification/cards/b/read'), hasLength(1));
  });
}
