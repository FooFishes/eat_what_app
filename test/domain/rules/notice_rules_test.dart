import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/rules/notice_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Notice _notice(
  String type,
  String targetType, {
  Map<String, Object?> data = const {},
}) => Notice(
  id: 1,
  actorId: 5,
  actorName: '小林',
  type: type,
  targetType: targetType,
  targetId: 42,
  data: data,
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  test('关注消息去对方的主页', () {
    final target = NoticeRules.targetOf(_notice('follow', 'user'));
    expect(target, isA<UserTarget>().having((t) => t.userId, 'userId', 5));
    expect(NoticeRules.sentenceOf(_notice('follow', 'user')), '关注了你');
  });

  test('赞、收藏菜的消息去菜品详情，写出菜名', () {
    final like = _notice('like', 'food', data: {'foodName': '番茄牛腩饭'});
    expect(
      NoticeRules.targetOf(like),
      isA<DishTarget>().having((t) => t.dishId, 'dishId', 42),
    );
    expect(NoticeRules.sentenceOf(like), '赞了你上传的番茄牛腩饭');
    expect(NoticeRules.sentenceOf(_notice('favorite', 'food')), '收藏了你上传的菜');
  });

  test('认不出的类型不跳转', () {
    expect(NoticeRules.targetOf(_notice('dinner', 'post')), isA<NoTarget>());
    expect(NoticeRules.sentenceOf(_notice('dinner', 'post')), '和你有了新的互动');
  });
}
