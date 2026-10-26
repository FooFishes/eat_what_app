import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('业务码归类', () {
    expect(failureKindOf(10003), FailureKind.tooFrequent);
    for (final code in [20001, 20002, 20003]) {
      expect(failureKindOf(code), FailureKind.sessionExpired, reason: '$code');
    }
    expect(failureKindOf(20004), FailureKind.forbidden);
    expect(failureKindOf('STATE_NOT_ALLOWED'), FailureKind.forbidden);
    expect(failureKindOf(30005), FailureKind.business);
    expect(failureKindOf(90004), FailureKind.server);
    expect(failureKindOf(20005), FailureKind.unknown);
    expect(failureKindOf('SITE_ENROLLMENT_REQUIRED'), FailureKind.unknown);
  });

  test('提示用规范短句，不带错误码和口语词', () {
    final messages = [
      ...failureMessages.values,
      for (final kind in FailureKind.values) AppFailure(kind).message,
    ];
    for (final message in messages) {
      expect(message, isNot(matches(RegExp(r'\d{4,}'))), reason: message);
      for (final word in ['一下', '吧', '开小差', '！', '!']) {
        expect(message, isNot(contains(word)), reason: message);
      }
    }
  });

  test('账号或密码不对的几个码说同一句话，不透露是哪一个错了', () {
    expect(AppFailure.fromCode(BizCodes.userNotFound).message, '账号或密码错误');
    expect(AppFailure.fromCode(BizCodes.wrongPassword).message, '账号或密码错误');
  });
}
