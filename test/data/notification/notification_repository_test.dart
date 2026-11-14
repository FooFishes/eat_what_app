import 'package:eat/data/notification/notification_api.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/topic_json.dart';

void main() {
  test('按分栏请求消息卡片，数字 id、合并的人数、互动者和已读状态都带上', () async {
    final env = TestEnv();
    env.adapter.on('GET /notification/cards', [
      FakeAdapter.ok(
        pageJson([
          noticeCardJson(
            id: 123,
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
    expect(notice.id, 123);
    expect(notice.kind, NoticeKind.like);
    expect(notice.targetDomain, 'foods');
    expect(notice.memberCount, 12);
    expect(notice.read, isTrue);
    expect(notice.actors.map((a) => a.name), ['Momo', '小林']);
    final query = env.adapter.sent('GET /notification/cards').single.query;
    expect(query, containsPair('column', 'LIKES_AND_FAVORITES'));
    expect(query, containsPair('page', 2));
  });

  test('评论赞和公告是认识的类型；系统消息按 data 的 type 解析处理结果和公告', () async {
    final env = TestEnv();
    env.adapter.on('GET /notification/cards', [
      FakeAdapter.ok(
        pageJson([
          noticeCardJson(id: 1, kind: 'comment_like', domain: 'comments'),
          noticeCardJson(
            id: 2,
            column: 'SYSTEM',
            kind: 'case_result',
            domain: 'catalog_error',
            targetId: 5,
            actors: const [],
            data: {
              'type': 'case_result',
              'caseId': 5,
              'kind': 'CATALOG_ERROR',
              'outcome': 'ACCEPTED',
              'reasonCode': 'WRONG_NAME',
              'reply': '已修正',
            },
          ),
          noticeCardJson(
            id: 3,
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
          noticeCardJson(id: 4, kind: 'topic_included', actors: const []),
        ]),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(notificationRepositoryProvider)
        .list(NoticeColumn.system);
    final [like, result, announcement, unknown] = page.items;
    expect(like.kind, NoticeKind.commentLike);
    expect(
      result.detail,
      isA<CaseResultDetail>()
          .having((d) => d.caseId, 'caseId', 5)
          .having((d) => d.kind, 'kind', CaseKind.catalogError)
          .having((d) => d.reply, 'reply', '已修正'),
    );
    expect(announcement.kind, NoticeKind.announcement);
    expect(
      announcement.detail,
      isA<AnnouncementDetail>()
          .having((d) => d.title, 'title', '食堂二楼周末停业')
          .having((d) => d.content, 'content', '周六周日暂停营业。'),
    );
    expect(unknown.kind, NoticeKind.other);
  });

  test('解析封禁、新设备登录和内容被删除的系统消息', () async {
    final env = TestEnv();
    final until = DateTime(2026, 11, 30);
    env.adapter.on('GET /notification/cards', [
      FakeAdapter.ok(
        pageJson([
          noticeCardJson(
            id: 1,
            column: 'SYSTEM',
            kind: 'account_banned',
            domain: 'bans',
            actors: const [],
            data: {
              'type': 'account_banned',
              'reason': '刷赞',
              'banUntil': until.millisecondsSinceEpoch,
            },
          ),
          noticeCardJson(
            id: 2,
            column: 'SYSTEM',
            kind: 'new_device_login',
            domain: 'sessions',
            actors: const [],
            data: {
              'type': 'new_device_login',
              'device': 'ANDROID',
              'deviceName': 'Pixel 8',
              'loginAt': 1,
            },
          ),
          noticeCardJson(
            id: 3,
            column: 'SYSTEM',
            kind: 'content_removed',
            domain: 'comments',
            actors: const [],
            data: {
              'type': 'content_removed',
              'contentType': 'comment',
              'contentId': 7,
              'title': '汤很鲜',
              'reason': null,
            },
          ),
        ]),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(notificationRepositoryProvider)
        .list(NoticeColumn.system);
    final [banned, device, removed] = page.items;
    expect(banned.kind, NoticeKind.accountBanned);
    expect(
      banned.detail,
      isA<BanDetail>()
          .having((d) => d.reason, 'reason', '刷赞')
          .having((d) => d.until, 'until', until),
    );
    expect(device.kind, NoticeKind.newDeviceLogin);
    expect(
      device.detail,
      isA<NewDeviceDetail>()
          .having((d) => d.deviceName, 'deviceName', 'Pixel 8')
          .having((d) => d.platform, 'platform', 'ANDROID'),
    );
    expect(removed.kind, NoticeKind.contentRemoved);
    expect(
      removed.detail,
      isA<ContentRemovedDetail>()
          .having((d) => d.comment, 'comment', isTrue)
          .having((d) => d.title, 'title', '汤很鲜')
          .having((d) => d.reason, 'reason', isNull),
    );
  });

  test('未读数取有未读的行数；标记已读用数字卡片 id', () async {
    final env = TestEnv();
    env.adapter
      ..on('GET /notification/cards/unread/count', [
        FakeAdapter.ok({'cards': 3, 'members': 15}),
      ])
      ..on('POST /notification/cards/42/read', [FakeAdapter.ok()]);
    final container = await env.container();
    final repository = container.read(notificationRepositoryProvider);

    expect(await repository.unreadCount(), 3);
    await repository.read(42);
    expect(env.adapter.sent('POST /notification/cards/42/read'), hasLength(1));
  });

  test('全部已读只请求一次，按分栏带 column', () async {
    final env = TestEnv();
    env.adapter.on('POST /notification/cards/read-all', [
      FakeAdapter.ok(),
      FakeAdapter.ok(),
    ]);
    final container = await env.container();
    final repository = container.read(notificationRepositoryProvider);

    await repository.readAll(NoticeColumn.all);
    await repository.readAll(NoticeColumn.system);
    final sent = env.adapter.sent('POST /notification/cards/read-all');
    expect([for (final r in sent) r.query['column']], ['ALL', 'SYSTEM']);
  });
}
