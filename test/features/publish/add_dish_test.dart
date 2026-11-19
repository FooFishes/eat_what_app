import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:eat/design/widgets/keyboard_inset.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/analytics.dart';
import '../../support/app.dart';
import '../../support/fakes.dart';

/// 登记发布流程用到的接口. [created] 是发布接口返回的 `data`.
void _routes(
  TestEnv env,
  Map<String, Object?> created, {
  Map<String, Object?>? shop,
}) {
  env.photos.next = [PickedPhoto(bytes: transparentImage, width: 1, height: 1)];
  env.adapter
    ..on('GET /restaurant/detail/7', [FakeAdapter.ok(shop ?? restaurantJson())])
    ..on('GET /foods/duplicates', [FakeAdapter.ok(<Object?>[])])
    ..on('POST /upload/presign', [
      FakeAdapter.ok({
        'putUrl': 'https://oss.test/put/a',
        'key': 'foods/a.jpg',
        'expireAt': 0,
      }),
    ])
    ..on('PUT https://oss.test/put/a', [<String, Object?>{}])
    ..on('POST /upload/complete', [
      FakeAdapter.ok({'key': 'foods/a.jpg'}),
    ])
    ..on('POST /foods/upload', [FakeAdapter.ok(created)])
    ..on('GET /foods/detail/99', [FakeAdapter.ok(foodJson(id: 99))]);
}

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(EatFormField, label),
  matching: find.byType(TextField),
);

Finder _page() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

/// 滚动抽屉直到 [text] 可见, 再点它.
Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200, scrollable: _page());
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// 滚动抽屉直到 [text] 可见. 抽屉的内容按需构建, 不滚动到附近时找不到.
Future<void> _seeText(WidgetTester tester, String text) =>
    tester.scrollUntilVisible(find.text(text), 200, scrollable: _page());

/// 加一张照片. 加入第一张照片后自动打开 "调整照片", 此处直接点 "完成".
Future<void> _addPhoto(WidgetTester tester) async {
  await tester.tap(find.text('加一张照片'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('从相册选'));
  await tester.pumpAndSettle();
  expect(find.text('调整照片'), findsWidgets);
  await tester.tap(find.text('完成'));
  await tester.pumpAndSettle();
}

/// 填菜名并等识别的延时过去.
Future<void> _enterName(WidgetTester tester, String name) async {
  await tester.enterText(_field('菜名'), name);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> _enterPrice(WidgetTester tester, String price) async {
  await tester.scrollUntilVisible(_field('价格'), 200, scrollable: _page());
  await tester.enterText(_field('价格'), price);
  await tester.pumpAndSettle();
}

/// 加一张照片, 填好菜名, 价格和分类, 点 "发布".
Future<void> _fillAndPublish(WidgetTester tester) async {
  await _addPhoto(tester);
  await tester.enterText(_field('菜名'), '鲜虾云吞');
  await _enterPrice(tester, '18');
  await _tapText(tester, '小吃');

  await tester.tap(find.text('发布'));
  await tester.pump();
}

Map<String, dynamic> _published(TestEnv env) =>
    env.adapter.sent('POST /foods/upload').last.body! as Map<String, dynamic>;

void main() {
  testWidgets('加照片后在后台传完，填好必填项发布，退出发布流程打开这道菜', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99});
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
      overrides: [recordAnalytics],
    );

    expect(find.text('请添加照片并填写菜名、价格和分类'), findsOneWidget);

    await _fillAndPublish(tester);
    await tester.pumpAndSettle();

    final request = env.adapter.sent('POST /foods/upload').single;
    final body = request.body! as Map<String, dynamic>;
    expect(body['restaurantId'], 7);
    expect(body['name'], '鲜虾云吞');
    expect(body['price'], 18);
    expect(body['category'], '小吃');
    expect(body['pictures'], ['foods/a.jpg']);
    expect(body['tags'], isEmpty);
    expect(body['signature'], isFalse);
    expect(body['stageColor'], isA<String>());
    expect(body['stageAlternates'], hasLength(2));
    expect(body['coverCrop'], isA<Map<String, dynamic>>());
    expect(body.containsKey('mealTimes'), isFalse);
    expect(body['deliveryEnabled'], isFalse);
    expect(request.headers.containsKey('Idempotency-Key'), isFalse);
    expect(env.adapter.sent('GET /foods/tags/system'), isEmpty);
    expect(env.adapter.sent('PUT https://oss.test/put/a').single.headers, {
      'content-type': 'image/jpeg',
      'content-length': transparentImage.length,
    });
    expect(locationOf(router), Paths.dish(99));
    expect(find.text('发布成功'), findsOneWidget);
    expect(recordedIn(container).propertiesOf<PublishSuccessEvent>(), [
      {'event': 'publish_success', 'kind': 'FOOD'},
    ]);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('键盘弹起时整页停在键盘上方，键盘后面铺白底', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99});
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );
    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    final inset = find.byType(KeyboardInset);
    expect(tester.getRect(inset).bottom, 844, reason: '留白一直铺到屏幕底边, 在键盘后面');
    final fill = tester.widget<ColoredBox>(
      find.descendant(of: inset, matching: find.byType(ColoredBox)).first,
    );
    expect(fill.color, EatPalette.paper);
    expect(
      tester.getRect(find.byType(StageScaffold)).bottom,
      lessThanOrEqualTo(844 - 300),
      reason: '内容停在键盘上方',
    );
    await unmountApp(tester, container);
  });

  testWidgets('店已关门时拦下发布', (tester) async {
    final env = TestEnv();
    _routes(
      env,
      {'id': 99},
      shop: {...restaurantJson(), 'permanentlyClosed': true},
    );
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    await _fillAndPublish(tester);
    await tester.pumpAndSettle();

    expect(find.text('这家店已关门，不能加菜'), findsOneWidget);
    expect(env.adapter.sent('POST /foods/upload'), isEmpty);
    expect(locationOf(router), Paths.publishDish(7));
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('饭点不选就跟店里一样；选了饭点和外卖照选的提交', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99});
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    await _addPhoto(tester);
    await _seeText(tester, '跟店里一样，午饭、晚饭');
    await _tapText(tester, '夜宵');
    expect(find.text('跟店里一样，午饭、晚饭'), findsNothing);
    await _tapText(tester, '早饭');
    await _tapText(tester, '能点外卖');

    await tester.scrollUntilVisible(_field('菜名'), -200, scrollable: _page());
    await tester.enterText(_field('菜名'), '鲜虾云吞');
    await _enterPrice(tester, '18');
    await _tapText(tester, '小吃');
    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle();

    expect(_published(env)['mealTimes'], ['breakfast', 'night']);
    expect(_published(env)['deliveryEnabled'], isTrue);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('分类、口味、饭点和上限按服务端给的选项', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99});
    env.adapter.on('GET /foods/options', [
      FakeAdapter.ok({
        'categories': ['菜', '主食'],
        'tags': ['辣', '甜'],
        'stageColors': ['broth'],
        'maxPictures': 9,
        'maxTags': 1,
        'maxSignatures': 2,
        'mealTimes': ['lunch', 'dinner'],
      }),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    await _addPhoto(tester);
    expect(find.bySemanticsLabel('已加 1 张，最多 9 张'), findsOneWidget);
    await _seeText(tester, '口味，最多 1 个');
    for (final hidden in ['小吃', '汤', '麻', '早饭', '夜宵']) {
      expect(find.text(hidden), findsNothing, reason: hidden);
    }
    await _seeText(tester, '能点外卖');
    await _tapText(tester, '辣');
    await _tapText(tester, '甜');
    expect(find.text('口味最多选 1 个'), findsOneWidget);
    await _seeText(tester, '每家店最多 2 道招牌菜');
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('选项取不到时用内置的分类、口味和上限', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99});
    env.adapter.on('GET /foods/options', [const FakeResponse.offline()]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    await _addPhoto(tester);
    expect(find.bySemanticsLabel('已加 1 张，最多 6 张'), findsOneWidget);
    await _seeText(tester, '口味，最多 3 个');
    await _seeText(tester, '特色');
    await _seeText(tester, '清淡');
    await _seeText(tester, '夜宵');
    await _seeText(tester, '每家店最多 3 道招牌菜');
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('查重：这家店已有同名的菜时提示并拦下发布，相近的菜不拦', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99});
    env.adapter.on('GET /foods/duplicates', [
      FakeAdapter.ok([
        {
          'id': 5,
          'name': '鲜虾云吞面',
          'category': '主食',
          'price': 22,
          'pictureUrl': null,
          'sameName': false,
        },
      ]),
      FakeAdapter.ok([
        {
          'id': 3,
          'name': '鲜虾云吞',
          'category': '主食',
          'price': 18,
          'pictureUrl': null,
          'sameName': true,
        },
      ]),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    await _addPhoto(tester);
    await _enterName(tester, '鲜虾');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('GET /foods/duplicates').last.query, {
      'restaurantId': 7,
      'keyword': '鲜虾',
    });
    expect(find.textContaining('这家店已有'), findsNothing);

    await _enterName(tester, '鲜虾云吞');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('这家店已有「鲜虾云吞」'), findsOneWidget);
    await _enterPrice(tester, '18');
    await _tapText(tester, '小吃');
    expect(find.text('这家店已有这道菜，去看看再说两句'), findsOneWidget);
    final publish = find.widgetWithText(EatButton, '发布');
    expect(tester.widget<EatButton>(publish).onPressed, isNull);
    expect(env.adapter.sent('GET /foods/list'), isEmpty);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('分类 6 个；口味最多选 3 个；没有「自己写」', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99});
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    // 抽屉滚动后舞台上的盘子会移出屏幕, 所以先加照片.
    await _addPhoto(tester);
    for (final category in DishCategory.values) {
      await tester.scrollUntilVisible(
        find.text(category.label),
        200,
        scrollable: _page(),
      );
    }
    for (final taste in ['辣', '麻', '甜']) {
      await _tapText(tester, taste);
    }
    await _tapText(tester, '酸');
    expect(find.text('口味最多选 3 个'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('自己写'), findsNothing);

    await tester.scrollUntilVisible(_field('菜名'), -200, scrollable: _page());
    await tester.enterText(_field('菜名'), '鲜虾云吞');
    await _enterPrice(tester, '18');
    await _tapText(tester, '小吃');
    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle();
    expect(_published(env)['tags'], ['辣', '麻', '甜']);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('标为招牌菜发布；招牌菜已满时就地提示，关掉开关后能发布', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99});
    env.adapter.on('POST /foods/upload', [
      FakeAdapter.fail(40002, '每家店最多 3 个招牌菜，请先取消一个'),
      FakeAdapter.ok({'id': 99}),
    ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    await _addPhoto(tester);
    await tester.enterText(_field('菜名'), '鲜虾云吞');
    await _enterPrice(tester, '18');
    await _tapText(tester, '小吃');
    await _tapText(tester, '招牌菜');
    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle();

    expect(_published(env)['signature'], isTrue);
    expect(find.text('这家店已有 3 道招牌菜，先取消一道'), findsWidgets);
    expect(locationOf(router), Paths.publishDish(7));
    final publish = find.widgetWithText(EatButton, '发布');
    expect(tester.widget<EatButton>(publish).onPressed, isNull);

    await _tapText(tester, '招牌菜');
    expect(find.text('这家店已有 3 道招牌菜，先取消一道'), findsNothing);
    await tester.tap(find.text('发布'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('POST /foods/upload'), hasLength(2));
    expect(_published(env)['signature'], isFalse);
    expect(locationOf(router), Paths.dish(99));
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  group('按照片预选', () {
    testWidgets('菜名和封面都好了、还没选分类时识别一次，预选分类和口味', (tester) async {
      final env = TestEnv();
      _routes(env, {'id': 99});
      env.adapter.on('POST /foods/suggest-tags', [
        FakeAdapter.ok({
          'category': '主食',
          'tags': ['辣', '清淡'],
        }),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.publishDish(7),
      );

      await _addPhoto(tester);
      expect(env.adapter.sent('POST /foods/suggest-tags'), isEmpty);
      await _enterName(tester, '鲜虾云吞');

      expect(env.adapter.sent('POST /foods/suggest-tags').single.body, {
        'name': '鲜虾云吞',
        'restaurantId': 7,
        'pictures': ['foods/a.jpg'],
      });
      await _seeText(tester, '按照片预选，可以改');

      await tester.scrollUntilVisible(_field('菜名'), -200, scrollable: _page());
      await _enterName(tester, '鲜虾馄饨');
      expect(env.adapter.sent('POST /foods/suggest-tags'), hasLength(1));

      await _enterPrice(tester, '18');
      await tester.tap(find.text('发布'));
      await tester.pumpAndSettle();
      expect(_published(env)['category'], '主食');
      expect(_published(env)['tags'], ['辣', '清淡']);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('识别回来前手动选过的口味不覆盖；改了分类后不再显示预选说明', (tester) async {
      final env = TestEnv();
      _routes(env, {'id': 99});
      env.adapter.on('POST /foods/suggest-tags', [
        FakeAdapter.ok({
          'category': '主食',
          'tags': ['辣'],
        }),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.publishDish(7),
      );

      await _addPhoto(tester);
      await _tapText(tester, '甜');
      await tester.scrollUntilVisible(_field('菜名'), -200, scrollable: _page());
      await _enterName(tester, '鲜虾云吞');
      expect(env.adapter.sent('POST /foods/suggest-tags'), hasLength(1));
      await _seeText(tester, '按照片预选，可以改');

      await _tapText(tester, '小吃');
      expect(find.text('按照片预选，可以改'), findsNothing);
      await _enterPrice(tester, '18');
      await tester.tap(find.text('发布'));
      await tester.pumpAndSettle();
      expect(_published(env)['category'], '小吃');
      expect(_published(env)['tags'], ['甜']);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('识别失败时不提示，照常手动选择', (tester) async {
      final env = TestEnv();
      _routes(env, {'id': 99});
      env.adapter.on('POST /foods/suggest-tags', [
        FakeAdapter.fail(40001, '没能识别这道菜，请手动选择'),
      ]);
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.publishDish(7),
      );

      await _addPhoto(tester);
      await _enterName(tester, '鲜虾云吞');

      expect(env.adapter.sent('POST /foods/suggest-tags'), hasLength(1));
      expect(find.text('没能识别这道菜，请手动选择'), findsNothing);
      expect(find.text('按照片预选，可以改'), findsNothing);
      expect(find.text('请填写价格和分类'), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('已经选了分类时不识别', (tester) async {
      final env = TestEnv();
      _routes(env, {'id': 99});
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.publishDish(7),
      );

      await _addPhoto(tester);
      await _tapText(tester, '小吃');
      await tester.scrollUntilVisible(_field('菜名'), -200, scrollable: _page());
      await _enterName(tester, '鲜虾云吞');

      expect(env.adapter.sent('POST /foods/suggest-tags'), isEmpty);
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });
  });
}
