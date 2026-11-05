import 'package:eat/features/verify/verify_providers.dart';
import 'package:eat/router/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

String? _location(String link) => DeepLinks.locationOf(Uri.parse(link));

void main() {
  test('白名单为空：认证回跳和其他链接都忽略', () {
    for (final link in [
      'https://eat.v50to.you/app/auth/callback?result=success&code=0',
      'https://eat.v50to.you/dishes/1',
      'you.v50to.eat://auth/callback?result=success&code=0',
    ]) {
      expect(_location(link), isNull, reason: link);
    }
  });

  group('Web 回跳地址转认证页地址', () {
    test('成功不带业务码，失败带上业务码', () {
      expect(
        DeepLinks.ssoLocation({'result': 'success', 'code': '0'}),
        '/verify?sso=success',
      );
      expect(
        DeepLinks.ssoLocation({'result': 'failure', 'code': '30013'}),
        '/verify?sso=failure&code=30013',
      );
    });

    test('没有 result 或 result 不认识时只打开认证页', () {
      expect(DeepLinks.ssoLocation({}), '/verify');
      expect(DeepLinks.ssoLocation({'result': 'ok', 'code': '0'}), '/verify');
    });
  });

  group('App 回跳链接中的结果', () {
    test('解析成功和失败', () {
      expect(SsoResult.fromCallback({'result': 'success'})!.success, isTrue);
      final failure = SsoResult.fromCallback({
        'result': 'failure',
        'code': '50003',
      })!;
      expect(failure.success, isFalse);
      expect(failure.code, 50003);
      expect(SsoResult.fromCallback({'result': 'ok'}), isNull);
      expect(SsoResult.fromCallback({}), isNull);
    });
  });

  group('认证页地址中的结果', () {
    test('解析成功和失败', () {
      final success = DeepLinks.ssoResultOf({'sso': 'success'})!;
      expect(success.success, isTrue);

      final failure = DeepLinks.ssoResultOf({
        'sso': 'failure',
        'code': '30013',
      })!;
      expect(failure.success, isFalse);
      expect(failure.code, 30013);

      expect(DeepLinks.ssoResultOf({'sso': 'failure'})!.code, isNull);
      expect(DeepLinks.ssoResultOf({}), isNull);
      expect(DeepLinks.ssoResultOf({'sso': 'x'}), isNull);
    });
  });

  group('统一认证失败的提示', () {
    test('按业务码给出规范短句，不显示业务码', () {
      const expected = {
        30012: '认证链接已失效，请重新发起认证',
        30013: '该学号已认证其他账号',
        50003: '学校返回的认证结果无效，请重新认证',
        20005: '账号正在同步，请稍后重新认证',
        20006: '账号正在同步，请稍后重新认证',
        30002: '账号已被封禁',
        90001: '暂时无法认证，请稍后再试',
        90002: '暂时无法认证，请稍后再试',
        90003: '暂时无法认证，请稍后再试',
      };
      for (final MapEntry(key: code, value: message) in expected.entries) {
        expect(ssoFailureMessage(code), message, reason: '$code');
        expect(ssoFailureMessage(code), isNot(contains('$code')));
      }
    });

    test('码表里没有的业务码和缺少业务码时用通用提示', () {
      expect(ssoFailureMessage(40001), '认证未完成，请重新认证');
      expect(ssoFailureMessage(null), '认证未完成，请重新认证');
    });
  });
}
