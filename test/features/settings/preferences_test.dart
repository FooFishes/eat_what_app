import 'dart:async';

import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/fakes.dart';

const _prefs = '/user/recommendation-profile/preferences';

/// 文字为 [label] 的胶囊. 喜欢的口味和忌口里都有 "辣" "麻", 前者在上.
Finder _chip(String label) =>
    find.byWidgetPredicate((w) => w is EatChip && w.label == label);

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is EatButton && w.label == label);

Map<String, Object?> _prefsJson({
  List<String> categories = const [],
  List<String> liked = const [],
  List<String> disliked = const [],
  String? priceBand,
  int? maxDistance,
}) => {
  'likedCategories': categories,
  'likedTags': liked,
  'dislikedTags': disliked,
  'priceBand': priceBand,
  'maxDistance': maxDistance,
  'updatedAt': null,
};

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      // 隐私页先显示本机记下的使用统计开关, 后台请求失败会弹提示, 所以这里都要给响应.
      ..on('GET /telemetry/consent', [
        FakeAdapter.ok({'enabled': true, 'retentionDays': 7}),
      ])
      ..on('GET /user/recommendation-settings', [
        FakeAdapter.ok({'personalized': true}),
      ])
      ..on('GET /recommend/tags', [
        FakeAdapter.ok({
          'categories': ['米饭炒菜', '粉面', '火锅麻辣烫'],
          'tags': ['辣', '麻', '甜', '酸', '清淡'],
          'dislikableTags': ['辣', '麻'],
        }),
      ])
      ..on('GET /user/recommendation-profile/taste', [
        FakeAdapter.ok({
          'tags': [
            {'name': '酸', 'score': 2.4},
          ],
          'categories': <Object>[],
          'inferredTags': ['酸'],
          'inferredCategories': <String>[],
        }),
      ]);
  });

  testWidgets('从隐私页进入，改了偏好保存后整体提交并返回；喜欢和忌口互斥', (tester) async {
    env.adapter
      ..on('GET /user/userInfo', [
        FakeAdapter.ok({
          'displayName': '天凉被破王',
          'fansVisible': true,
          'followingsVisible': true,
        }),
      ])
      ..on('GET /telemetry/consent', [
        FakeAdapter.ok({'enabled': true, 'retentionDays': 7}),
      ])
      ..on('GET $_prefs', [
        FakeAdapter.ok(_prefsJson(liked: ['辣'], maxDistance: 1000)),
      ])
      ..on('PUT $_prefs', [
        FakeAdapter.ok(
          _prefsJson(categories: ['粉面'], disliked: ['辣'], maxDistance: 1000),
        ),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.settingsPrivacy,
    );

    await tester.ensureVisible(find.text('推荐偏好'));
    await tester.tap(find.text('推荐偏好'));
    await tester.pumpAndSettle();
    expect(find.text('喜欢的品类'), findsOneWidget);

    expect(tester.widget<EatChip>(_chip('辣').first).selected, isTrue);
    expect(tester.widget<EatChip>(_chip('1 km')).selected, isTrue);
    expect(tester.widget<EatChip>(_chip('不限').first).selected, isTrue);
    expect(find.text('「酸」'), findsOneWidget);

    await tester.tap(_chip('粉面'));
    await tester.pump();
    await tester.ensureVisible(_chip('辣').last);
    await tester.pumpAndSettle();
    await tester.tap(_chip('辣').last);
    await tester.pump();
    expect(tester.widget<EatChip>(_chip('辣').first).selected, isFalse);
    expect(tester.widget<EatChip>(_chip('辣').last).selected, isTrue);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('PUT $_prefs').single.body, {
      'likedCategories': ['粉面'],
      'likedTags': <String>[],
      'dislikedTags': ['辣'],
      'maxDistance': 1000,
    });
    expect(find.text('偏好已保存'), findsOneWidget);
    expect(find.text('喜欢的品类'), findsNothing);
    expect(find.text('推荐偏好'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('有改动时返回先确认，放弃后不提交', (tester) async {
    env.adapter.on('GET $_prefs', [FakeAdapter.ok(_prefsJson())]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.settingsPrivacy,
    );
    unawaited(router.push(Paths.settingsPreferences));
    await tester.pumpAndSettle();

    expect(find.text('还没设置偏好。选几项喜欢的，推荐会更合你的口味'), findsOneWidget);
    expect(_button('清空偏好'), findsNothing);
    await tester.tap(_chip('米饭炒菜'));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsOneWidget);
    await tester.tap(_button('继续编辑'));
    await tester.pumpAndSettle();
    expect(find.text('喜欢的品类'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    await tester.tap(_button('放弃'));
    await tester.pumpAndSettle();
    expect(find.text('喜欢的品类'), findsNothing);
    expect(find.text('推荐偏好'), findsOneWidget);
    expect(env.adapter.sent('PUT $_prefs'), isEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('清空偏好：确认后删除，页面回到未设置', (tester) async {
    env.adapter
      ..on('GET $_prefs', [
        FakeAdapter.ok(_prefsJson(categories: ['粉面'], priceBand: 'UNDER_15')),
      ])
      ..on('DELETE $_prefs', [FakeAdapter.ok()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.settingsPreferences,
    );

    expect(tester.widget<EatChip>(_chip('粉面')).selected, isTrue);
    expect(tester.widget<EatChip>(_chip('¥ 15 以下')).selected, isTrue);
    await tester.ensureVisible(_button('清空偏好'));
    await tester.pumpAndSettle();
    await tester.tap(_button('清空偏好'));
    await tester.pumpAndSettle();
    expect(find.text('清空推荐偏好？'), findsOneWidget);
    await tester.tap(_button('先不清空'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE $_prefs'), isEmpty);

    await tester.ensureVisible(_button('清空偏好'));
    await tester.pumpAndSettle();
    await tester.tap(_button('清空偏好'));
    await tester.pumpAndSettle();
    await tester.tap(_button('清空'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE $_prefs'), hasLength(1));
    expect(find.text('偏好已清空'), findsOneWidget);
    expect(tester.widget<EatChip>(_chip('粉面')).selected, isFalse);
    expect(_button('清空偏好'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('加载失败就地重试；可选值取不到时用客户端的品类和口味', (tester) async {
    env.adapter
      ..on('GET $_prefs', [
        const FakeResponse.offline(),
        FakeAdapter.ok(_prefsJson()),
      ])
      ..on('GET /recommend/tags', [const FakeResponse(status: 500)]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.settingsPreferences,
    );

    expect(find.text('加载失败'), findsOneWidget);
    await tester.tap(_button('重试'));
    await tester.pumpAndSettle();
    expect(find.text('加载失败'), findsNothing);
    expect(_chip('日韩料理'), findsOneWidget);
    expect(_chip('麻'), findsNWidgets(2));
    await unmountApp(tester, container);
  });

  testWidgets('个性化推荐关闭时提示偏好暂不生效，不显示推断的口味', (tester) async {
    env.adapter
      ..on('GET /user/recommendation-settings', [
        FakeAdapter.ok({'personalized': false}),
      ])
      ..on('GET $_prefs', [FakeAdapter.ok(_prefsJson())]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.settingsPreferences,
    );
    await tester.pumpAndSettle();

    expect(find.text('个性化推荐已关闭，偏好暂不生效。在隐私设置里打开后生效'), findsOneWidget);
    expect(find.text('从你的点赞和收藏看出'), findsNothing);
    expect(env.adapter.sent('GET /user/recommendation-profile/taste'), isEmpty);
    await unmountApp(tester, container);
  });
}
