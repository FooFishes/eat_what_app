import 'package:eat/design/widgets/eat_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/fakes.dart';

/// 先联网打开 [location] 一次, 把数据存进本地缓存; 再断网重新打开, 返回第二次的容器.
Future<ProviderContainer> _openOfflineAfterOnline(
  WidgetTester tester,
  TestEnv env,
  String location,
  Map<String, Object> routes,
) async {
  for (final MapEntry(:key, :value) in routes.entries) {
    env.adapter.on(key, [value]);
  }
  final (first, _) = await pumpApp(
    tester,
    env,
    session: const SignedIn(user: verifiedUser),
    location: location,
  );
  await unmountApp(tester, first);

  for (final route in routes.keys) {
    env.adapter.on(route, [const FakeResponse.offline()]);
  }
  final (second, _) = await pumpApp(
    tester,
    env,
    session: const SignedIn(user: verifiedUser),
    location: location,
  );
  return second;
}

/// 等轻提示消失后卸载.
Future<void> _close(WidgetTester tester, ProviderContainer container) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  await unmountApp(tester, container);
}

bool _on(WidgetTester tester, String label) =>
    tester.widget<EatSwitch>(find.widgetWithText(EatSwitch, label)).value;

void main() {
  testWidgets('通知：断网时显示上次的开关，并提示网络连接失败', (tester) async {
    final env = TestEnv();
    final container = await _openOfflineAfterOnline(
      tester,
      env,
      Paths.settingsNotify,
      {
        'GET /push/settings': FakeAdapter.ok({
          'categories': {'COMMENTS': true, 'FOLLOWS': false},
        }),
      },
    );

    expect(_on(tester, '评论和回复'), isTrue);
    expect(_on(tester, '关注'), isFalse);
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    await _close(tester, container);
  });

  testWidgets('隐私：断网时显示上次的三组开关，几项一起失败只提示一次', (tester) async {
    final env = TestEnv();
    final container = await _openOfflineAfterOnline(
      tester,
      env,
      Paths.settingsPrivacy,
      {
        'GET /user/userInfo': FakeAdapter.ok({
          'displayName': '天凉被破王',
          'fansVisible': false,
          'followingsVisible': true,
        }),
        'GET /user/recommendation-settings': FakeAdapter.ok({
          'personalized': false,
        }),
        'GET /telemetry/consent': FakeAdapter.ok({
          'enabled': true,
          'retentionDays': 7,
        }),
      },
    );

    expect(_on(tester, '公开我的关注列表'), isTrue);
    expect(_on(tester, '公开我的粉丝列表'), isFalse);
    expect(_on(tester, '个性化推荐'), isFalse);
    expect(_on(tester, '使用统计'), isTrue);
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    await _close(tester, container);
  });

  testWidgets('我的：断网时显示上次的资料和上传，并提示网络连接失败', (tester) async {
    final env = TestEnv();
    final container = await _openOfflineAfterOnline(tester, env, Paths.me, {
      'GET /user/userInfo': FakeAdapter.ok({
        'id': 42,
        'displayName': '天凉被破王',
        'level': 2,
        'earnedLikes': 40,
        'fansCount': 3,
        'followingsCount': 5,
      }),
      'GET /foods/my': FakeAdapter.ok({
        ...pageJson([foodJson(id: 1, name: '虾仁云吞')]),
        'totalItems': 1,
      }),
    });

    expect(find.bySemanticsLabel('粉丝 3'), findsOneWidget);
    expect(find.text('虾仁云吞'), findsOneWidget);
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    await _close(tester, container);
  });
}
