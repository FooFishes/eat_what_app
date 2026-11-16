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

  test('评论列表带排序和分页参数，带回总条数、作者、赞过没有和回复数，时间读毫秒', () async {
    env.adapter.on('GET /foods/1/comments', [
      FakeAdapter.ok(
        commentPageJson(
          [
            commentJson(
              id: 11,
              authorId: 7,
              liked: true,
              replies: 4,
              images: ['https://img.test/a.jpg', ''],
            ),
            {...commentJson(id: 12), 'author': null},
            {
              ...commentJson(id: 13),
              'author': authorJson('老饕', id: 8, title: '老吃家'),
            },
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
    expect(page.page.items.map((c) => c.id), [11, 13]);
    final comment = page.page.items.first;
    expect(comment.id, 11);
    expect((comment.authorId, comment.authorName), (7, '安安'));
    expect(comment.authorTitle, isNull);
    expect(page.page.items.last.authorTitle, '老吃家');
    expect(comment.isReply, isFalse);
    expect(comment.liked, isTrue);
    expect(comment.replyCount, 4);
    expect(comment.createdAt.isUtc, isFalse);
    expect(
      comment.createdAt.toUtc(),
      commentEpoch.subtract(const Duration(hours: 1)),
    );
    expect(comment.images, ['https://img.test/a.jpg']);
  });

  test('"最有用" 按 HOT 请求', () async {
    env.adapter.on('GET /foods/1/comments', [
      FakeAdapter.ok(commentPageJson(const [])),
    ]);

    await repo.comments(1, sort: CommentSort.mostUseful);

    expect(
      env.adapter.sent('GET /foods/1/comments').single.query['sort'],
      'HOT',
    );
  });

  test('回复带所属评论和被回复的人；游客的赞过没有为空', () async {
    env.adapter.on('GET /comments/11/replies', [
      FakeAdapter.ok(
        commentPageJson([replyJson(id: 21, replyTo: '小林', liked: null)]),
      ),
    ]);

    final reply = (await repo.replies(11)).page.items.single;

    expect(reply.isReply, isTrue);
    expect(reply.rootId, 11);
    expect(reply.replyToName, '小林');
    expect(reply.liked, isNull);
  });

  test('发表评论不带幂等键，文字去掉首尾空白，返回新评论的 id', () async {
    env.adapter.on('POST /foods/1/comments', [FakeAdapter.ok(createdJson())]);

    final posted = await repo.create(
      1,
      text: '  加了辣油更好吃 ',
      pictureKeys: ['comments/a.jpg'],
    );

    final sent = env.adapter.sent('POST /foods/1/comments').single;
    expect(sent.headers.containsKey('Idempotency-Key'), isFalse);
    expect(sent.body, {
      'text': '加了辣油更好吃',
      'pictureKeys': ['comments/a.jpg'],
    });
    expect(posted.id, 99);
  });

  test('回复只带文字和被回复的那条', () async {
    env.adapter.on('POST /foods/1/comments/11/replies', [
      FakeAdapter.ok(createdJson(id: 30)),
    ]);

    final posted = await repo.reply(1, 11, text: '同意', replyToId: 21);

    final sent = env.adapter.sent('POST /foods/1/comments/11/replies').single;
    expect(sent.body, {'text': '同意', 'replyToId': 21});
    expect(posted.id, 30);
  });

  test('赞和取消赞分别用 PUT 和 DELETE，接口返回 null 也算成功', () async {
    env.adapter
      ..on('PUT /comments/11/like', [FakeAdapter.ok(null)])
      ..on('DELETE /comments/11/like', [FakeAdapter.ok(null)]);

    await repo.setLiked(11, liked: true);
    await repo.setLiked(11, liked: false);

    expect(env.adapter.sent('PUT /comments/11/like'), hasLength(1));
    expect(env.adapter.sent('DELETE /comments/11/like'), hasLength(1));
  });

  test('删除失败时抛出原因', () async {
    env.adapter.on('DELETE /comments/11', [
      FakeAdapter.ok(null),
      FakeAdapter.fail(20004),
    ]);

    await repo.delete(11);
    await expectLater(
      repo.delete(11),
      throwsA(
        isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.forbidden),
      ),
    );
  });

  test('我的评论读 /comments/my，回复带所属评论，照片数取地址条数', () async {
    env.adapter.on('GET /comments/my', [
      FakeAdapter.ok(
        commentPageJson([
          commentJson(id: 11, images: ['https://img.test/a.jpg']),
          replyJson(id: 12, root: 11),
        ]),
      ),
    ]);

    final mine = (await repo.mine()).items;

    expect([for (final c in mine) c.id], [11, 12]);
    expect((mine[0].isReply, mine[0].imageCount), (false, 1));
    expect((mine[1].isReply, mine[1].rootId), (true, 11));
  });

  test('图库只留下有地址的照片，并带拍摄者', () async {
    env.adapter.on('GET /foods/1/gallery', [
      FakeAdapter.ok(
        commentPageJson([
          {
            'commentId': 11,
            'slot': 0,
            'url': 'https://img.test/a.jpg',
            'author': authorJson('安安'),
            'createdAt': commentTime(),
          },
          {
            'commentId': 12,
            'slot': 0,
            'url': '',
            'author': authorJson('阿哲'),
            'createdAt': commentTime(),
          },
        ]),
      ),
    ]);

    final photos = await repo.gallery(1);

    expect(photos.single.commentId, 11);
    expect(photos.single.url, 'https://img.test/a.jpg');
    expect(photos.single.authorName, '安安');
  });
}
