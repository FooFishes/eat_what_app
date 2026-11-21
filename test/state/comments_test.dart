import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/state/comments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('只有服务端说评论不存在时才当作已删除，内容被拦不算', () {
    AppFailure invalid(String msg) =>
        AppFailure.fromCode(BizCodes.paramInvalid, serverMessage: msg);

    expect(isCommentGone(invalid('评论不存在')), isTrue);
    expect(isCommentGone(invalid('被回复的评论不存在')), isTrue);
    expect(isCommentGone(invalid('这条评论已删除或不可见')), isTrue);
    expect(isCommentGone(invalid('评论里不能放链接和联系方式')), isFalse);
    expect(isCommentGone(invalid('评论不能超过 200 个字符')), isFalse);
    expect(
      isCommentGone(
        AppFailure.fromCode(BizCodes.stateNotAllowed, serverMessage: '评论不存在'),
      ),
      isFalse,
    );
  });
}
