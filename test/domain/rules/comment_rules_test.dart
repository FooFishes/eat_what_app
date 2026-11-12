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
}
