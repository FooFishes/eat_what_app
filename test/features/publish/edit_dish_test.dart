import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/features/publish/add_dish_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
    ..on('GET /foods/list', [FakeAdapter.ok(pageJson([]))])
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
    );
    await tester.scrollUntilVisible(
      find.text('修改记录'),
      200,
      scrollable: _page(),
    );
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.byType(AddDishPage), findsOneWidget);
    expect(
      env.adapter.sent('GET /foods/detail/1'),
      hasLength(1),
      reason: '详情页带入了菜品，编辑页不再读取',
    );
    expect(_textOf(tester, _field('菜名')), '鲜虾蟹籽云吞');
    expect(_textOf(tester, _field('价格')), '18');
    expect(find.text('所在的店 袁记云饺', findRichText: true), findsOneWidget);
    expect(find.text('换一家'), findsNothing);
    expect(find.text('2 / 2'), findsNothing);
    expect(_save(tester), isNull, reason: '没有改动时不能保存');

    await _enter(tester, _field('价格'), '20');
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

  testWidgets('照片只能整组换：不换时不提交照片，换了提交新照片、舞台色和取景', (tester) async {
    final env = _env();
    env.adapter.on('PUT /foods/edit/1', [
      FakeAdapter.ok({'id': 1, 'revisionId': 5}),
    ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dishEdit(1),
    );

    expect(find.text('换照片会替换现有的全部照片'), findsOneWidget);
    await tester.tap(find.widgetWithText(EatButton, '换照片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册选'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.text('保存后替换原有的 1 张照片'), findsOneWidget);
    expect(_save(tester), isNotNull);

    await tester.tap(find.text('不换了'));
    await tester.pumpAndSettle();
    expect(find.text('换照片会替换现有的全部照片'), findsOneWidget);
    expect(_save(tester), isNull);

    await tester.tap(find.widgetWithText(EatButton, '换照片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册选'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final body =
        env.adapter.sent('PUT /foods/edit/1').single.body!
            as Map<String, dynamic>;
    expect(body.keys, {
      'pictures',
      'stageColor',
      'stageAlternates',
      'coverCrop',
    });
    expect(body['pictures'], ['foods/a.jpg']);
    expect(body['stageAlternates'], hasLength(2));
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });
}
