import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/features/publish/add_dish_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/analytics.dart';
import '../../support/app.dart';
import '../../support/fakes.dart';

/// 编辑用的模拟环境: 菜品 1 在店 7, 照片上传后得到 `foods/a.jpg`.
TestEnv _env() {
  final env = TestEnv();
  env.photos.next = [PickedPhoto(bytes: transparentImage, width: 1, height: 1)];
  env.adapter
    ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
    ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
    ..on('GET /user/userInfo', [
      FakeAdapter.ok({'id': 9, 'displayName': '小林'}),
    ])
    ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())])
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
    ]);
  return env;
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

String _textOf(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

VoidCallback? _save(WidgetTester tester) =>
    tester.widget<EatButton>(find.widgetWithText(EatButton, '保存')).onPressed;

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200, scrollable: _page());
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, Finder field, String text) async {
  await tester.scrollUntilVisible(field, 200, scrollable: _page());
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

Map<String, Object?> _bizFail(int code, Object? data) => {
  'code': code,
  'msg': 'error',
  'data': data,
  'timestamp': 0,
};

void main() {
  testWidgets('从详情进编辑：预填现有内容，不能换店；只提交改动的字段，保存后回到详情并刷新', (tester) async {
    final env = _env();
    env.adapter.on('PUT /foods/edit/1', [
      FakeAdapter.ok({'id': 1, 'revisionId': 5}),
    ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
      overrides: [recordAnalytics],
    );
    await tester.tap(find.bySemanticsLabel('编辑'));
    await tester.pumpAndSettle();

    expect(find.byType(AddDishPage), findsOneWidget);
    expect(
      env.adapter.sent('GET /foods/detail/1'),
      hasLength(1),
      reason: '详情页带入了菜品，编辑页不再读取',
    );
    expect(_textOf(tester, _field('菜名')), '鲜虾蟹籽云吞');
    expect(_textOf(tester, _field('价格，选填')), '18');
    expect(find.text('所在的店 袁记云饺', findRichText: true), findsOneWidget);
    expect(find.text('换一家'), findsNothing);
    expect(find.text('2 / 2'), findsNothing);
    expect(_save(tester), isNull, reason: '没有改动时不能保存');

    await _enter(tester, _field('价格，选填'), '20');
    await _tapText(tester, '辣');
    await _enter(tester, find.byType(TextField).last, '');
    expect(_save(tester), isNotNull);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('PUT /foods/edit/1').single.body, {
      'price': 20,
      'description': '',
      'tags': ['辣'],
    });
    expect(find.text('已保存'), findsOneWidget);
    expect(locationOf(router), Paths.dish(1));
    expect(
      env.adapter.sent('GET /foods/detail/1'),
      hasLength(2),
      reason: '保存后详情重新读取',
    );
    expect(
      recordedIn(container).propertiesOf<PublishSuccessEvent>(),
      isEmpty,
      reason: '编辑不算发布',
    );
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('已有的价格不能清空', (tester) async {
    final env = _env();
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );
    await tester.tap(find.bySemanticsLabel('编辑'));
    await tester.pumpAndSettle();

    await _enter(tester, _field('价格，选填'), '');
    expect(find.text('价格不能清空'), findsWidgets);
    expect(_save(tester), isNull);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('刷新编辑页时按 id 读取菜品；保存后前往详情', (tester) async {
    final env = _env();
    env.adapter.on('PUT /foods/edit/1', [
      FakeAdapter.ok({'id': 1, 'revisionId': 5}),
    ]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dishEdit(1),
    );

    expect(env.adapter.sent('GET /foods/detail/1'), hasLength(1));
    expect(_textOf(tester, _field('菜名')), '鲜虾蟹籽云吞');
    expect(_save(tester), isNull);

    await _enter(tester, _field('菜名'), '鲜虾云吞');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('PUT /foods/edit/1').single.body, {'name': '鲜虾云吞'});
    expect(env.adapter.sent('POST /foods/suggest-tags'), isEmpty);
    expect(locationOf(router), Paths.dish(1));
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('预填自己的饭点和外卖；全部取消改回跟店里一样，关掉外卖', (tester) async {
    final env = _env();
    env.adapter
      ..on('GET /foods/detail/1', [
        FakeAdapter.ok({
          ...foodJson(),
          'mealTimes': ['breakfast'],
          'effectiveMealTimes': ['breakfast'],
          'deliveryEnabled': true,
        }),
      ])
      ..on('PUT /foods/edit/1', [
        FakeAdapter.ok({'id': 1, 'revisionId': 5}),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dishEdit(1),
    );

    await tester.scrollUntilVisible(
      find.text('能点外卖'),
      200,
      scrollable: _page(),
    );
    expect(find.text('跟店里一样，午饭、晚饭'), findsNothing);
    await _tapText(tester, '早饭');
    expect(find.text('跟店里一样，午饭、晚饭'), findsOneWidget);
    await _tapText(tester, '能点外卖');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(env.adapter.sent('PUT /foods/edit/1').single.body, {
      'mealTimes': <String>[],
      'deliveryEnabled': false,
    });
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('改名撞名和招牌菜已满都就地提示，改好后能保存', (tester) async {
    final env = _env();
    env.adapter.on('PUT /foods/edit/1', [
      _bizFail(40016, {'id': 3}),
      _bizFail(40002, null),
      FakeAdapter.ok({'id': 1, 'revisionId': 5}),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dishEdit(1),
    );

    await _enter(tester, _field('菜名'), '虾饺');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('这家店已有「虾饺」'), findsOneWidget);
    expect(find.text('这家店已有同名的菜，换个菜名'), findsOneWidget);
    expect(_save(tester), isNull);
    await tester.pump(const Duration(seconds: 3));

    await _enter(tester, _field('菜名'), '虾饺皇');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await _tapText(tester, '招牌菜');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('这家店已有 3 道招牌菜，先取消一道'), findsWidgets);
    expect(_save(tester), isNull);

    await _tapText(tester, '招牌菜');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final sent = env.adapter.sent('PUT /foods/edit/1').toList();
    expect(sent, hasLength(3));
    expect(sent[1].body, {'name': '虾饺皇', 'signature': true});
    expect(sent[2].body, {'name': '虾饺皇'});
    expect(find.text('已保存'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  group('照片', () {
    /// 菜品 1 有两张照片, 带保存过的舞台色和取景.
    TestEnv photosEnv({bool keys = true}) {
      final env = _env();
      final json = {
        ...foodJson(
          pictures: ['foods/1.jpg', 'foods/2.jpg'],
          stageColor: 'soy',
          alternates: ['mango', 'bamboo'],
        ),
        'coverCrop': {'centerX': 0.4, 'centerY': 0.5, 'diameter': 0.8},
        if (!keys) 'pictureKeys': null,
      };
      env.adapter
        ..on('GET /foods/detail/1', [FakeAdapter.ok(json)])
        ..on('PUT /foods/edit/1', [
          FakeAdapter.ok({'id': 1, 'revisionId': 5}),
        ]);
      return env;
    }

    Future<ProviderContainer> open(WidgetTester tester, TestEnv env) async {
      final (container, _) = await pumpApp(
        tester,
        env,
        session: const SignedIn(user: verifiedUser),
        location: Paths.dish(1),
      );
      await tester.tap(find.bySemanticsLabel('编辑'));
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> tapPhoto(WidgetTester tester, Pattern label) async {
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();
    }

    /// 等原有照片取色结束. 网络图片的解码要在真实的异步里完成.
    Future<void> settleImages(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
    }

    Map<String, dynamic> sentBody(TestEnv env) =>
        env.adapter.sent('PUT /foods/edit/1').single.body!
            as Map<String, dynamic>;

    testWidgets('原有照片载入照片条；不动照片时不提交照片、舞台色和取景', (tester) async {
      final env = photosEnv();
      final container = await open(tester, env);

      expect(find.bySemanticsLabel(RegExp('^封面，已上传')), findsOneWidget);
      expect(find.bySemanticsLabel('已上传'), findsOneWidget);
      expect(find.text('照片暂时不能修改'), findsNothing);
      expect(find.text('主色取自照片'), findsNothing);
      expect(_save(tester), isNull);

      await _enter(tester, _field('菜名'), '鲜虾云吞');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(sentBody(env), {'name': '鲜虾云吞'});
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('删掉后面的一张：只提交剩下的 key', (tester) async {
      final env = photosEnv();
      final container = await open(tester, env);

      await tapPhoto(tester, '已上传');
      await tester.tap(find.text('删掉这张'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('已上传'), findsNothing);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(sentBody(env), {
        'pictures': ['foods/1.jpg'],
      });
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('追加一张：原图带原 key，新图排在后面，不重新调整封面', (tester) async {
      final env = photosEnv();
      final container = await open(tester, env);

      await tester.tap(find.bySemanticsLabel('再加一张照片'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('从相册选'));
      await tester.pumpAndSettle();
      expect(find.text('完成'), findsNothing, reason: '不是第一张，不进调整照片');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(sentBody(env), {
        'pictures': ['foods/1.jpg', 'foods/2.jpg', 'foods/a.jpg'],
      });
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('把第二张设为封面：调整后提交新顺序、舞台色、备选色和取景', (tester) async {
      final env = photosEnv();
      final container = await open(tester, env);

      await tapPhoto(tester, '已上传');
      await tester.tap(find.text('设为封面'));
      await settleImages(tester);
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.text('主色取自照片'), findsOneWidget);
      await tester.tap(find.text('保存'));
      await settleImages(tester);

      final body = sentBody(env);
      expect(body.keys, {
        'pictures',
        'stageColor',
        'stageAlternates',
        'coverCrop',
      });
      expect(body['pictures'], ['foods/2.jpg', 'foods/1.jpg']);
      expect(body['stageAlternates'], hasLength(2));
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('删掉封面：第二张成为封面，取景回到居中，带上新的舞台色', (tester) async {
      final env = photosEnv();
      final container = await open(tester, env);

      await tapPhoto(tester, RegExp('^封面，已上传'));
      await tester.tap(find.text('删掉这张'));
      await settleImages(tester);
      await tester.tap(find.text('保存'));
      await settleImages(tester);

      final body = sentBody(env);
      expect(body['pictures'], ['foods/2.jpg']);
      expect(body['stageColor'], isA<String>());
      expect(body['stageAlternates'], hasLength(2));
      expect(body['coverCrop'], {
        'centerX': 0.5,
        'centerY': 0.5,
        'diameter': 1.0,
      });
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('只调整原封面：不提交照片，提交舞台色和取景', (tester) async {
      final env = photosEnv();
      final container = await open(tester, env);

      await tapPhoto(tester, RegExp('^封面，已上传'));
      await tester.tap(find.text('调整照片'));
      await settleImages(tester);
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await settleImages(tester);

      final body = sentBody(env);
      expect(body.keys, {'stageColor', 'stageAlternates', 'coverCrop'});
      expect(body['coverCrop'], {
        'centerX': 0.4,
        'centerY': 0.5,
        'diameter': 0.8,
      });
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });

    testWidgets('带入的菜缺照片 key 时重新读取；仍然缺时照片只能看，保存不带照片', (tester) async {
      final env = photosEnv(keys: false);
      final container = await open(tester, env);

      expect(
        env.adapter.sent('GET /foods/detail/1'),
        hasLength(2),
        reason: '带入的菜没有照片 key，编辑页重新读取',
      );
      expect(find.text('照片暂时不能修改'), findsOneWidget);
      expect(find.bySemanticsLabel('再加一张照片'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^封面，已上传')), findsOneWidget);

      await _enter(tester, _field('菜名'), '鲜虾云吞');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(sentBody(env), {'name': '鲜虾云吞'});
      await tester.pump(const Duration(seconds: 3));
      await unmountApp(tester, container);
    });
  });
}
