import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/telemetry/crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('release 写成 eat@版本名+构建号，和 CI 上传符号表时一致', () {
    expect(CrashReporter.releaseName('0.3.0', '30'), 'eat@0.3.0+30');
  });

  test('没配 SENTRY_DSN 时不启用，启动和设置账号都什么也不做', () async {
    const config = AppConfig(
      envName: 'dev',
      apiBaseUrl: '',
      webBaseUrl: '',
      sentryDsn: '',
      baiduMapAkAndroid: '',
      baiduMapAkIos: '',
      baiduMapAkWeb: '',
      privacyUrl: '',
      termsUrl: '',
    );
    final reporter = CrashReporter(config);

    expect(reporter.enabled, isFalse);
    await reporter.start(patch: 2);
    await reporter.setUser(42);
    expect(Sentry.isEnabled, isFalse);
  });

  group('上报前去掉个人信息', () {
    test('请求只留方法和不带查询参数的地址，账号只留 id', () {
      final event = SentryEvent(
        request: SentryRequest(
          method: 'GET',
          url: 'https://example.com/api/restaurant/search?keyword=云吞',
          queryString: 'keyword=云吞',
          headers: {'satoken': 'Bearer tk'},
          cookies: 'a=b',
          data: {'phone': '13800000000'},
        ),
        user: SentryUser(id: '42', username: 'foo', email: 'a@b.c'),
      );

      final scrubbed = CrashReporter.scrubEvent(event, Hint());

      final request = scrubbed.request!;
      expect(request.method, 'GET');
      expect(request.url, 'https://example.com/api/restaurant/search');
      expect(request.queryString, isNull);
      expect(request.headers, isEmpty);
      expect(request.cookies, isNull);
      expect(request.data, isNull);
      expect(scrubbed.user?.id, '42');
      expect(scrubbed.user?.username, isNull);
      expect(scrubbed.user?.email, isNull);
    });

    test('网络面包屑去掉查询参数，路由面包屑去掉路由参数', () {
      final http = Breadcrumb.http(
        url: Uri.parse('https://example.com/api/foods/search?keyword=云吞#top'),
        method: 'GET',
      );
      final scrubbedHttp = CrashReporter.scrubBreadcrumb(http, Hint())!;
      expect(scrubbedHttp.data?['url'], 'https://example.com/api/foods/search');
      expect(scrubbedHttp.data?.containsKey('http.query'), isFalse);
      expect(scrubbedHttp.data?.containsKey('http.fragment'), isFalse);
      expect(scrubbedHttp.data?['method'], 'GET');

      final navigation = Breadcrumb(
        category: 'navigation',
        data: {
          'from': '/search',
          'from_arguments': {'q': '云吞'},
          'to': '/dishes/:id',
          'to_arguments': {'id': '2'},
        },
      );
      final scrubbedNavigation = CrashReporter.scrubBreadcrumb(
        navigation,
        Hint(),
      )!;
      expect(scrubbedNavigation.data, {'from': '/search', 'to': '/dishes/:id'});
    });

    test('事件里已有的面包屑也一起处理', () {
      final event = SentryEvent(
        breadcrumbs: [
          Breadcrumb(data: {'url': 'https://example.com/a?b=c'}),
        ],
      );

      final scrubbed = CrashReporter.scrubEvent(event, Hint());

      expect(
        scrubbed.breadcrumbs?.single.data?['url'],
        'https://example.com/a',
      );
    });
  });
}
