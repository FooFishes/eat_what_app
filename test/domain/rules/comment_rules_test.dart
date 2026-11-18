import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('表情回应', () {
    const yummy = ReactionCount(reaction: CommentReaction.yummy, count: 2);
    const myHeart = ReactionCount(
      reaction: CommentReaction.heart,
      count: 1,
      selected: true,
    );

    test('选上一种：这一种加一人并标为自己选的，按回应的顺序排', () {
      final after = CommentRules.toggleReaction([
        yummy,
      ], CommentReaction.thumbsUp);
      expect(after.map((r) => (r.reaction, r.count, r.selected)), [
        (CommentReaction.thumbsUp, 1, true),
        (CommentReaction.yummy, 2, false),
      ]);
    });

    test('换一种：原来那种少一人，没人了就去掉', () {
      final after = CommentRules.toggleReaction([
        myHeart,
        yummy,
      ], CommentReaction.yummy);
      expect(after.map((r) => (r.reaction, r.count, r.selected)), [
        (CommentReaction.yummy, 3, true),
      ]);
    });

    test('点自己选的那种是取消', () {
      final after = CommentRules.toggleReaction([
        myHeart,
        yummy,
      ], CommentReaction.heart);
      expect(after.map((r) => (r.reaction, r.count, r.selected)), [
        (CommentReaction.yummy, 2, false),
      ]);
    });
  });
}
