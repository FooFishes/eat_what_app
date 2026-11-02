import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/comment/comment_repository.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/comment_fixtures.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;
  late CommentRepository repo;

  setUp(() async {
    env = TestEnv();
    final container = await env.container();
    repo = container.read(commentRepositoryProvider);
  });

  test('评论列表带排序和分页参数，带回总条数，照片按位置排好', () async {
    env.adapter.on('GET /foods/1/comments', [
      FakeAdapter.ok(
        commentPageJson(
          [
            {
              ...commentJson(id: 11),
              'images': [
                {'slot': 1, 'url': 'https://img.test/b.jpg'},
                {'slot': 0, 'url': 'https://img.test/a.jpg'},
                {'slot': 2, 'url': ''},
              ],
            },
            {...commentJson(id: 12), 'gid': null},
          ],
          total: 23,
          hasNext: true,
        ),
      ),
    ]);

    final page = await repo.comments(1, sort: CommentSort.newest, page: 2);

    final query = env.adapter.sent('GET /foods/1/comments').single.query;
    expect(query, {'sort': 'NEWEST', 'page': 2, 'pageSize': 20});
    expect(page.total, 23);
    expect(page.page.hasNext, isTrue);
    final comment = page.page.items.single;
    expect(comment.id, 11);
    expect(comment.authorName, '安安');
    expect(comment.isReply, isFalse);
    expect(comment.rootGid, 'g-11');
    expect(comment.images, [
      'https://img.test/a.jpg',
      'https://img.test/b.jpg',
    ]);
  });

  test('回复带所属评论和被回复的那条', () async {
    env.adapter.on('GET /comments/11/replies', [
      FakeAdapter.ok(commentPageJson([replyJson(id: 21, replyTo: 'g-20')])),
    ]);

    final reply = (await repo.replies(11)).page.items.single;

    expect(reply.isReply, isTrue);
    expect(reply.rootGid, 'g-11');
    expect(reply.replyToGid, 'g-20');
  });

  test('发表评论带幂等键，文字去掉首尾空白，进入审核时标为待审', () async {
    env.adapter.on('POST /foods/1/comments', [FakeAdapter.ok(acceptedJson())]);

    final posted = await repo.create(
      1,
      text: '  加了辣油更好吃 ',
      pictureKeys: ['comments/a.jpg'],
      idempotencyKey: 'key-1',
    );

    final sent = env.adapter.sent('POST /foods/1/comments').single;
    expect(sent.headers['Idempotency-Key'], 'key-1');
    expect(sent.body, {
      'text': '加了辣油更好吃',
      'pictureKeys': ['comments/a.jpg'],
    });
    expect(posted.id, 99);
    expect(posted.pending, isTrue);
  });

  test('回复只带文字和被回复的那条；直接公开时不算待审', () async {
    env.adapter.on('POST /foods/1/comments/11/replies', [
      FakeAdapter.ok(acceptedJson(id: 30, status: 'APPROVED')),
    ]);

    final posted = await repo.reply(
      1,
      11,
      text: '同意',
      replyToId: 21,
      idempotencyKey: 'key-2',
    );

    final sent = env.adapter.sent('POST /foods/1/comments/11/replies').single;
    expect(sent.body, {'text': '同意', 'replyToId': 21});
    expect(sent.headers['Idempotency-Key'], 'key-2');
    expect(posted.pending, isFalse);
  });

  test('赞和取消赞分别用 PUT 和 DELETE，带幂等键，返回服务端计数', () async {
    env.adapter
      ..on('PUT /comments/11/like', [
        FakeAdapter.ok({'commentId': 11, 'liked': true, 'likesCount': 4}),
      ])
      ..on('DELETE /comments/11/like', [
        FakeAdapter.ok({'commentId': 11, 'liked': false, 'likesCount': 3}),
      ]);

    final liked = await repo.setLiked(11, liked: true, idempotencyKey: 'a');
    final unliked = await repo.setLiked(11, liked: false, idempotencyKey: 'b');

    expect((liked.liked, liked.likes), (true, 4));
    expect((unliked.liked, unliked.likes), (false, 3));
    expect(
      env.adapter
          .sent('PUT /comments/11/like')
          .single
          .headers['Idempotency-Key'],
      'a',
    );
    expect(
      env.adapter
          .sent('DELETE /comments/11/like')
          .single
          .headers['Idempotency-Key'],
      'b',
    );
  });

  test('删除带幂等键；失败时抛出原因', () async {
    env.adapter.on('DELETE /comments/11', [
      FakeAdapter.ok({'id': 11, 'state': 'DELETED'}),
      FakeAdapter.fail(20004),
    ]);

    await repo.delete(11, idempotencyKey: 'del-1');
    expect(
      env.adapter.sent('DELETE /comments/11').single.headers['Idempotency-Key'],
      'del-1',
    );
    await expectLater(
      repo.delete(11, idempotencyKey: 'del-2'),
      throwsA(
        isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.forbidden),
      ),
    );
  });

  test('我的评论带审核状态和未通过的原因', () async {
    env.adapter.on('GET /comments/submissions/my', [
      FakeAdapter.ok(
        commentPageJson([
          submissionJson(id: 11, status: 'PENDING'),
          submissionJson(
            id: 12,
            kind: 'REPLY',
            status: 'REJECTED',
            reason: '不是这道菜的实拍',
          ),
          submissionJson(id: 13, status: 'DELETED', text: null),
        ]),
      ),
    ]);

    final mine = (await repo.mine()).items;

    expect(
      [for (final c in mine) c.status],
      [CommentStatus.pending, CommentStatus.rejected, CommentStatus.deleted],
    );
    expect(mine[1].isReply, isTrue);
    expect(mine[1].reason, '不是这道菜的实拍');
    expect(mine[2].text, '');
  });

  test('图库只留下有地址的照片', () async {
    env.adapter.on('GET /foods/1/gallery', [
      FakeAdapter.ok(
        commentPageJson([
          {
            'commentId': 11,
            'commentGid': 'g-11',
            'createdAt': commentEpoch,
            'image': {'slot': 0, 'url': 'https://img.test/a.jpg'},
          },
          {
            'commentId': 12,
            'commentGid': 'g-12',
            'createdAt': commentEpoch,
            'image': {'slot': 0, 'url': ''},
          },
        ]),
      ),
    ]);

    final photos = await repo.gallery(1);

    expect(photos.single.commentId, 11);
    expect(photos.single.url, 'https://img.test/a.jpg');
  });
}
