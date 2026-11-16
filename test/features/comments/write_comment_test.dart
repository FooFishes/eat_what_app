import 'dart:async';

import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/features/comments/write_comment_page.dart';
import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app.dart';
import '../../support/comment_fixtures.dart';
import '../../support/eat_test_app.dart';
import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..on('GET /campus/list', [FakeAdapter.ok(campusListJson)])
      ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
      ..on('GET /restaurant/detail/7', [FakeAdapter.ok(restaurantJson())])
      ..on('GET /foods/1/comments', [FakeAdapter.ok(commentPageJson(const []))])
      ..on('POST /upload/presign', [
        FakeAdapter.ok({
          'putUrl': 'https://oss.test/put/c',
          'key': 'comments/c.jpg',
          'expireAt': 0,
        }),
      ])
      ..on('POST /upload/presign/batch', [
        FakeAdapter.ok({
          'files': [
            for (final name in ['c1', 'c2', 'c3'])
              {
                'putUrl': 'https://oss.test/put/c',
                'key': 'comments/$name.jpg',
                'expireAt': DateTime(2100).millisecondsSinceEpoch,
              },
          ],
        }),
      ])
      ..on('PUT https://oss.test/put/c', [<String, Object?>{}])
      ..on('POST /upload/complete', [FakeAdapter.ok()]);
  });

  /// 以菜品详情为底页打开 [location], 使写评论页发送后可以返回详情页.
  Future<(ProviderContainer, GoRouter)> open(
    WidgetTester tester,
    String location,
  ) async {
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );
    unawaited(router.push(location));
    await tester.pumpAndSettle();
    return (container, router);
  }

  testWidgets('写评论：没写字也没照片时不能发送；发出后提示成功、回到详情并刷新评论', (tester) async {
    env.adapter.on('POST /foods/1/comments', [FakeAdapter.ok(createdJson())]);
    final (container, _) = await open(tester, Paths.writeComment(1));

    expect(find.textContaining('写一条'), findsWidgets);
    expect(find.text('吃过的话，说两句'), findsOneWidget);
    await expectAccessible(tester);
    await tester.tap(find.text('发送'));
    await tester.pump();
    expect(env.adapter.sent('POST /foods/1/comments'), isEmpty);

    await tester.enterText(find.byType(EditableText), ' 加了辣油更好吃 ');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();

    final sent = env.adapter.sent('POST /foods/1/comments').single;
    expect(sent.body, {'text': '加了辣油更好吃', 'pictureKeys': <String>[]});
    expect(sent.headers.containsKey('Idempotency-Key'), isFalse);
    expect(find.text('发送成功'), findsOneWidget);
    expect(find.byType(DishPage), findsOneWidget);
    expect(env.adapter.sent('GET /foods/1/comments'), hasLength(2));
    expect(find.byType(WriteCommentPage), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('文字最多 200 字', (tester) async {
    final (container, _) = await open(tester, Paths.writeComment(1));

    await tester.enterText(find.byType(EditableText), '好' * 205);
    await tester.pump();
    expect(find.text('好' * 200), findsOneWidget);
    expect(find.text('200 / 200'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('最多加 3 张照片；只有照片也能发，照片按评论用途一次申请地址上传', (tester) async {
    env.photos.next = [
      for (var i = 0; i < 4; i++)
        PickedPhoto(bytes: transparentImage, width: 1, height: 1),
    ];
    env.adapter.on('POST /foods/1/comments', [FakeAdapter.ok(createdJson())]);
    final (container, _) = await open(tester, Paths.writeComment(1));

    await tester.tap(find.bySemanticsLabel('加照片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册选'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('去掉第 . 张照片')), findsNWidgets(3));
    expect(find.bySemanticsLabel('加照片'), findsNothing);

    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /upload/presign'), isEmpty);
    final presign = env.adapter.sent('POST /upload/presign/batch').single;
    expect((presign.body as Map)['biz'], 'comments');
    expect((presign.body as Map)['files'], hasLength(3));
    final sent = env.adapter.sent('POST /foods/1/comments').single;
    expect((sent.body as Map)['pictureKeys'], [
      'comments/c1.jpg',
      'comments/c2.jpg',
      'comments/c3.jpg',
    ]);
    expect((sent.body as Map)['text'], '');
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('回复只能写字，提示「回复 某某」，带上被回复的那条', (tester) async {
    env.adapter.on('POST /foods/1/comments/11/replies', [
      FakeAdapter.ok(createdJson(id: 30)),
    ]);
    final (container, _) = await open(
      tester,
      Paths.writeComment(1, reply: 11, to: 21, name: '阿哲'),
    );

    // 标题和菜名同属一段文字, 中间隔着占位符 U+FFFC.
    expect(find.textContaining(RegExp('^回复￼')), findsOneWidget);
    expect(find.text('回复 阿哲'), findsOneWidget);
    expect(find.bySemanticsLabel('加照片'), findsNothing);
    await expectAccessible(tester);

    await tester.enterText(find.byType(EditableText), '同意');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();

    final sent = env.adapter.sent('POST /foods/1/comments/11/replies').single;
    expect(sent.body, {'text': '同意', 'replyToId': 21});
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('发送失败时内容保留，可以重发', (tester) async {
    env.adapter.on('POST /foods/1/comments', [
      const FakeResponse.offline(),
      FakeAdapter.ok(createdJson()),
    ]);
    final (container, _) = await open(tester, Paths.writeComment(1));

    await tester.enterText(find.byType(EditableText), '汤很鲜');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    expect(find.text('汤很鲜'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /foods/1/comments'), hasLength(2));
    expect(find.byType(WriteCommentPage), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('回复时被对方屏蔽：提示无法回复，内容保留', (tester) async {
    env.adapter.on('POST /foods/1/comments/11/replies', [
      FakeAdapter.fail(40002),
    ]);
    final (container, _) = await open(
      tester,
      Paths.writeComment(1, reply: 11, name: '安安'),
    );

    await tester.enterText(find.byType(EditableText), '同意');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('无法回复对方'), findsOneWidget);
    expect(find.text('同意'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('回复时评论已删除：提示已删除，并刷新评论', (tester) async {
    env.adapter.on('POST /foods/1/comments/11/replies', [
      FakeAdapter.fail(10001),
    ]);
    final (container, _) = await open(
      tester,
      Paths.writeComment(1, reply: 11, name: '安安'),
    );
    final before = env.adapter.sent('GET /foods/1/comments').length;

    await tester.enterText(find.byType(EditableText), '同意');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('这条评论已删除'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    // 底下的菜品详情不可见时暂停监听, 回到详情后才重新请求.
    await tester.enterText(find.byType(EditableText), '');
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    expect(find.byType(DishPage), findsOneWidget);
    expect(
      env.adapter.sent('GET /foods/1/comments').length,
      greaterThan(before),
    );
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('没认证时发送弹拦截对话框', (tester) async {
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: testUser),
      location: Paths.writeComment(1),
    );

    await tester.enterText(find.byType(EditableText), '汤很鲜');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能评论'), findsOneWidget);
    expect(env.adapter.sent('POST /foods/1/comments'), isEmpty);
    expect(locationOf(router), Paths.writeComment(1));
    await unmountApp(tester, container);
  });
}
