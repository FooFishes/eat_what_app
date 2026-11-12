import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('业务码归类', () {
    expect(failureKindOf(10003), FailureKind.tooFrequent);
    expect(failureKindOf(20001), FailureKind.sessionExpired);
    expect(failureKindOf(20004), FailureKind.forbidden);
    expect(failureKindOf(30005), FailureKind.business);
    expect(failureKindOf(40008), FailureKind.business);
    expect(failureKindOf(90004), FailureKind.server);
    for (final code in [20005, 20009, 30002, 30006, 30008, 30009]) {
      expect(failureKindOf(code), FailureKind.business, reason: '$code');
    }
    expect(
      failureKindOf(40001),
      FailureKind.unknown,
      reason: '含义随接口而定, 由页面就地说明',
    );
    expect(failureKindOf('SITE_ENROLLMENT_REQUIRED'), FailureKind.unknown);
  });

  test('限流按服务端给的秒数提示何时重试', () {
    AppFailure limited(Object? data) =>
        AppFailure.fromCode(BizCodes.tooFrequent, data: data);

    expect(limited(null).retryAfter, isNull);
    expect(limited(null).message, '操作过于频繁，请稍后再试');
    expect(limited({'retryAfterSeconds': 30}).retryHint, '请 30 秒后再试');
    expect(limited({'retryAfterSeconds': 61}).retryHint, '请 2 分钟后再试');
    expect(limited({'retryAfterSeconds': 900}).message, '操作过于频繁，请 15 分钟后再试');
    expect(limited({'retryAfterSeconds': 3600}).retryHint, '请 60 分钟后再试');
    expect(limited({'retryAfterSeconds': 30000}).retryHint, '请 9 小时后再试');
    expect(limited({'retryAfterSeconds': 0}).retryAfter, isNull);
    expect(limited({'retryAfterSeconds': 'x'}).retryAfter, isNull);
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

  test('密码登录的失败统一说账号或密码错误，不透露是哪一个错了', () {
    expect(AppFailure.fromCode(BizCodes.wrongPassword).message, '账号或密码错误');
  });
}
