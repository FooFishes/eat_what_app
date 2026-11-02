import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
    ..on('GET /foods/tags/system', [
      FakeAdapter.ok([
        {'id': 3, 'name': '皮薄'},
      ]),
    ])
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
    ])
    ..on('POST /foods/upload', [FakeAdapter.ok(created)])
    ..on('GET /foods/detail/99', [FakeAdapter.ok(foodJson(id: 99))]);
}

/// 加一张照片, 填好菜名, 价格和分类, 点 "发布".
Future<void> _fillAndPublish(WidgetTester tester) async {
  await tester.tap(find.text('加一张照片'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('从相册选'));
  await tester.pumpAndSettle();
  // 加入第一张照片后自动打开 "调整照片", 此处直接点 "完成".
  expect(find.text('调整照片'), findsWidgets);
  await tester.tap(find.text('完成'));
  await tester.pumpAndSettle();

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(EatFormField, label),
    matching: find.byType(TextField),
  );
  final page = find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;
  await tester.enterText(field('菜名'), '鲜虾云吞');
  await tester.scrollUntilVisible(field('价格'), 200, scrollable: page);
  await tester.enterText(field('价格'), '18');
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('小吃'));
  await tester.tap(find.text('小吃'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('发布'));
  await tester.pump();
}

void main() {
  testWidgets('加照片后在后台传完，填好必填项发布，退出发布流程打开这道菜', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99});
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    expect(find.text('请添加照片并填写菜名、价格和分类'), findsOneWidget);

    await _fillAndPublish(tester);
    await tester.pumpAndSettle();

    final request = env.adapter.sent('POST /foods/upload').single;
    final body = request.body! as Map<String, dynamic>;
    expect(body['restaurantId'], 7);
    expect(body['name'], '鲜虾云吞');
    expect(body['price'], 18);
    expect(body['category'], 'snack');
    expect(body['pictureUrl'], ['foods/a.jpg']);
    expect(body['stageAlternates'], hasLength(2));
    expect(
      request.headers['Idempotency-Key'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(env.adapter.sent('PUT https://oss.test/put/a').single.headers, {
      'content-type': 'image/jpeg',
      'content-length': transparentImage.length,
    });
    expect(locationOf(router), Paths.dish(99));
    expect(find.text('发布成功'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('发布后进入审核：不打开详情，提示已提交审核', (tester) async {
    final env = TestEnv();
    _routes(env, {'id': 99, 'moderationStatus': 'PENDING'});
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    await _fillAndPublish(tester);
    await tester.pumpAndSettle();

    expect(find.text('已提交审核，通过后公开'), findsOneWidget);
    expect(locationOf(router), Paths.discover);
    expect(env.adapter.sent('GET /foods/detail/99'), isEmpty);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('店已关门时拦下发布', (tester) async {
    final env = TestEnv();
    _routes(
      env,
      {'id': 99},
      shop: {...restaurantJson(), 'operatingStatus': 'CLOSED'},
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
}
