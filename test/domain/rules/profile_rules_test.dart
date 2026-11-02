import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/rules/profile_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('昵称', () {
    test('2–12 个字，按字数算，首尾空格不算', () {
      expect(ProfileRules.nicknameError(''), '请输入昵称');
      expect(ProfileRules.nicknameError('   '), '请输入昵称');
      expect(ProfileRules.nicknameError('哲'), '昵称至少 2 个字');
      expect(ProfileRules.nicknameError(' 阿哲 '), isNull);
      expect(ProfileRules.nicknameError('一二三四五六七八九十一二'), isNull);
      expect(ProfileRules.nicknameError('一二三四五六七八九十一二三'), '昵称最多 12 个字');
    });
  });

  test('签名最多 30 个字，可以不填', () {
    expect(ProfileRules.signatureError(''), isNull);
    expect(ProfileRules.signatureError('字' * 30), isNull);
    expect(ProfileRules.signatureError('字' * 31), '签名最多 30 个字');
  });

  test('我的标签：不能为空，最多 10 个字，不能和其他标签重名', () {
    expect(ProfileRules.myTagError(' ', const []), '请输入标签名');
    expect(ProfileRules.myTagError('考试周', const ['宵夜']), isNull);
    expect(ProfileRules.myTagError('宵夜', const ['宵夜']), '已有同名标签');
    expect(ProfileRules.myTagError('字' * 11, const []), '标签名最多 10 个字');
  });

  test('关注按钮按双方关系显示', () {
    FollowState of(bool mine, bool theirs) =>
        FollowState.of(followedByMe: mine, followsMe: theirs);
    expect(of(false, false).label, '关注');
    expect(of(false, true).label, '回关');
    expect(of(true, false).label, '已关注');
    expect(of(true, true).label, '已互关');
    expect(of(true, true).followedByMe, isTrue);
    expect(of(false, true).followedByMe, isFalse);
  });
}
