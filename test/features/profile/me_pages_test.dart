import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/features/profile/edit_profile_page.dart';
import 'package:eat/features/profile/history_page.dart';
import 'package:eat/features/profile/tag_dishes_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  testWidgets('「我的」右上角有历史和编辑资料，没有我的标签', (tester) async {
    env.adapter.on('GET /foods/my', [FakeAdapter.ok(pageJson([]))]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.me,
    );

    expect(find.text('我的标签'), findsNothing);
    expect(env.adapter.sent('GET /foods/tags/my'), isEmpty);

    await tester.tap(find.text('历史'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('编辑资料'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfilePage), findsOneWidget);
  });

  testWidgets('编辑资料：换头像后先上传，再保存昵称和签名', (tester) async {
    env.photos.next = [
      PickedPhoto(bytes: transparentImage, width: 1, height: 1),
    ];
    env.adapter
      ..on('POST /upload/presign', [
        FakeAdapter.ok({
          'putUrl': 'https://oss.test/put/avatar',
          'key': 'avatar/a.jpg',
          'expireAt': 0,
        }),
      ])
      ..on('PUT https://oss.test/put/avatar', [<String, Object?>{}])
      ..on('POST /upload/complete', [
        FakeAdapter.ok({'key': 'avatar/a.jpg'}),
      ])
      ..on('PUT /user/updateInfo', [FakeAdapter.ok()])
      ..on('GET /user/info', [FakeAdapter.ok(userInfoJson())]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.meEdit,
    );
    await expectAccessible(tester);

    await tester.enterText(find.byType(EditableText).first, '哲');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('昵称至少 2 个字'), findsOneWidget);
    expect(env.adapter.sent('PUT /user/updateInfo'), isEmpty);

    await tester.tap(find.text('换头像').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册选'));
    await tester.pumpAndSettle();
    expect(find.text('调整头像'), findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(env.photos.lastCrop, (centerX: 0.5, centerY: 0.5, diameter: 1.0));

    await tester.enterText(find.byType(EditableText).first, '阿哲');
    await tester.pump();
    await tester.enterText(find.byType(EditableText).last, '只吃辣的');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('POST /upload/presign').single.body,
      containsPair('biz', 'avatar'),
    );
    expect(env.adapter.sent('PUT /user/updateInfo').single.body, {
      'displayName': '阿哲',
      'signature': '只吃辣的',
      'avatar': 'avatar/a.jpg',
    });
    expect(find.byType(EditProfilePage), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await unmountApp(tester, container);
  });

  testWidgets('改了资料没保存就返回，先确认是否放弃', (tester) async {
    env.adapter.on('GET /foods/my', [FakeAdapter.ok(pageJson([]))]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.me,
    );
    await tester.tap(find.bySemanticsLabel('编辑资料'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).first, '新名字');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsOneWidget);
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfilePage), findsNothing);
  });

  testWidgets('我的标签：显示用了几道菜，可以改名和删除，点标签看标签下的菜', (tester) async {
    env.adapter
      ..on('GET /foods/tags/my', [
        FakeAdapter.ok(
          pageJson([
            {'id': 1, 'name': '宵夜', 'usageCount': 3},
            {'id': 2, 'name': '请客', 'usageCount': 1},
          ]),
        ),
      ])
      ..on('PUT /foods/tags/my/1', [FakeAdapter.ok()])
      ..on('DELETE /foods/tags/my/2', [FakeAdapter.ok()])
      ..on('GET /foods/tags/my/1/foods', [
        FakeAdapter.ok(pageJson([foodJson(name: '烤冷面')])),
      ]);
    final (container, _) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.myTags,
    );

    expect(find.text('宵夜'), findsOneWidget);
    expect(find.text('3 道菜'), findsOneWidget);
    await expectAccessible(tester);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('改名').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '请客');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('已有同名标签'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '考试周');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('PUT /foods/tags/my/1').single.body, {
      'name': '考试周',
    });
    expect(find.text('考试周'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('删除').last);
    await tester.pumpAndSettle();
    expect(find.text('删除「请客」？'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('DELETE /foods/tags/my/2'), hasLength(1));
    expect(find.text('请客'), findsNothing);

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('考试周'));
    await tester.pumpAndSettle();
    expect(find.byType(TagDishesPage), findsOneWidget);
    expect(find.text('烤冷面'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(env.adapter.sent('GET /foods/tags/my/1/foods'), hasLength(1));
    await unmountApp(tester, container);
  });

  testWidgets('历史：菜和店分栏，菜带赞数，店带门头照，清空当前分栏', (tester) async {
    final viewed = DateTime.now()
        .subtract(const Duration(minutes: 12))
        .millisecondsSinceEpoch;
    env.adapter
      ..on('GET /history/browse', [
        FakeAdapter.ok(
          pageJson([
            {
              'targetType': 'food',
              'targetId': 1,
              'viewedAt': viewed,
              'food': {
                'id': 1,
                'restaurantId': 7,
                'name': '柳州螺蛳粉',
                'pictureUrls': <String>[],
                'likeCount': 96,
              },
              'restaurant': null,
            },
          ]),
        ),
        FakeAdapter.ok(
          pageJson([
            {
              'targetType': 'restaurant',
              'targetId': 7,
              'viewedAt': viewed,
              'food': null,
              'restaurant': {
                'id': 7,
                'name': '袁记云饺',
                'pictureUrl': 'https://img.test/shops/7.jpg',
              },
            },
          ]),
        ),
      ])
      ..on('DELETE /history/browse', [FakeAdapter.ok()]);
    await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.history,
    );

    expect(find.text('柳州螺蛳粉'), findsOneWidget);
    expect(find.textContaining('96', findRichText: true), findsOneWidget);
    expect(find.text('12 分钟前'), findsOneWidget);
    expect(
      env.adapter.sent('GET /history/browse').single.query['targetType'],
      'food',
    );
    await expectAccessible(tester);

    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    expect(find.text('清空看过的菜？'), findsOneWidget);
    await tester.tap(find.text('清空').last);
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('DELETE /history/browse').single.query['targetType'],
      'food',
    );
    expect(find.text('还没看过菜'), findsOneWidget);

    // 切换分栏触发的请求在当前帧之后发出. 单独调用 pumpAndSettle 时, 断言执行前该请求尚未发出.
    await tester.tap(find.text('店'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
    expect(
      env.adapter.sent('GET /history/browse').last.query['targetType'],
      'restaurant',
    );
    expect(find.text('袁记云饺'), findsOneWidget);
  });
}
