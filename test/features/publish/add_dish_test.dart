import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/app.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('加照片后在后台传完，填好必填项发布，退出发布流程打开这道菜', (tester) async {
    final env = TestEnv();
    env.photos.next = [
      PickedPhoto(bytes: transparentImage, width: 1, height: 1),
    ];
    env.adapter
      ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())])
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
      ..on('POST /foods/upload', [
        FakeAdapter.ok({'id': 99}),
      ])
      ..on('GET /foods/detail/99', [FakeAdapter.ok(foodJson(id: 99))]);
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.publishDish(7),
    );

    expect(find.text('请添加照片并填写菜名、价格和分类'), findsOneWidget);

    await tester.tap(find.text('加一张照片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册选'));
    await tester.pumpAndSettle();
    // 第一张加好后自动进「调整照片」，直接完成。
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
    await tester.pumpAndSettle();

    final body =
        env.adapter.sent('POST /foods/upload').single.body!
            as Map<String, dynamic>;
    expect(body['restaurantId'], 7);
    expect(body['name'], '鲜虾云吞');
    expect(body['price'], 18);
    expect(body['category'], 'snack');
    expect(body['pictureUrl'], ['foods/a.jpg']);
    expect(body['stageAlternates'], hasLength(2));
    expect(env.adapter.sent('PUT https://oss.test/put/a').single.headers, {
      'content-type': 'image/jpeg',
      'content-length': transparentImage.length,
    });
    expect(locationOf(router), Paths.dish(99));
    await unmountApp(tester, container);
  });
}
