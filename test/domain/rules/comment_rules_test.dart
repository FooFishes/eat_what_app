import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Comment _reply(String gid, {String? to, String name = '阿哲', int minute = 0}) =>
    Comment(
      id: gid.hashCode,
      gid: gid,
      dishId: 1,
      isReply: true,
      rootGid: 'root',
      replyToGid: to,
      authorName: name,
      createdAt: DateTime(2026, 11, 1, 12, minute),
    );

void main() {
  group('能否发送', () {
    test('评论的文字和照片至少有一样，纯照片可以', () {
      expect(CommentRules.canSend(''), isFalse);
      expect(CommentRules.canSend('   '), isFalse);
      expect(CommentRules.canSend('好吃'), isTrue);
      expect(CommentRules.canSend('', photos: 1), isTrue);
      expect(CommentRules.canSend('好吃', photos: 4), isFalse);
    });

    test('按码点数到 200 字，首尾空白不算', () {
      expect(CommentRules.canSend('😋' * 200), isTrue);
      expect(CommentRules.canSend('😋' * 201), isFalse);
      expect(CommentRules.canSend('  ${'好' * 200}  '), isTrue);
      expect(CommentRules.length(' 😋好 '), 2);
    });

    test('回复只能写字', () {
      expect(CommentRules.canSend('同意', reply: true), isTrue);
      expect(CommentRules.canSend('', reply: true), isFalse);
      expect(CommentRules.canSend('同意', photos: 1, reply: true), isFalse);
    });
  });

  test('回复按时间正序排列', () {
    final ordered = CommentRules.chronological([
      _reply('c', minute: 30),
      _reply('a', minute: 10),
      _reply('b', minute: 20),
    ]);
    expect([for (final r in ordered) r.gid], ['a', 'b', 'c']);
  });

  test('回复别人的回复时找到被回复人；直接回复评论或找不到时没有', () {
    final first = _reply('a', name: '小林');
    final second = _reply('b', to: 'a');
    final direct = _reply('c', to: 'root');
    final orphan = _reply('d', to: 'gone');
    final siblings = [first, second, direct, orphan];
    expect(CommentRules.replyToName(second, siblings), '小林');
    expect(CommentRules.replyToName(first, siblings), isNull);
    expect(CommentRules.replyToName(direct, siblings), isNull);
    expect(CommentRules.replyToName(orphan, siblings), isNull);
  });
}
