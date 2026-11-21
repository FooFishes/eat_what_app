import 'dart:async';

import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/features/comments/comments_page.dart';
import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/analytics.dart';
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
      ..on('GET /foods/1/comments', [
        FakeAdapter.ok(
          commentPageJson([
            commentJson(id: 11, author: '安安', text: '酸笋给得很大方', replies: 1),
          ], total: 1),
        ),
      ])
      ..on('GET /comments/11/replies', [
        FakeAdapter.ok(
          commentPageJson([
            replyJson(id: 21, author: '阿哲', text: '同意，加个炸蛋更香'),
          ], total: 1),
        ),
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

  Future<ProviderContainer> open(
    WidgetTester tester, {
    SessionState session = const SignedIn(user: verifiedUser),
  }) async {
    final (container, _) = await pumpApp(
      tester,
      env,
      session: session,
      location: Paths.comments(1),
      overrides: [recordAnalytics],
    );
    return container;
  }

  /// 点开写评论的输入框.
  Future<void> expand(WidgetTester tester) async {
    await tester.tap(find.text('吃过的话，说两句'));
    await tester.pumpAndSettle();
  }

  testWidgets('点输入框就地展开；没写字也没照片时不能发送；发出后清空收起并刷新评论', (tester) async {
    env.adapter.on('POST /foods/1/comments', [FakeAdapter.ok(createdJson())]);
    final container = await open(tester);
    final before = env.adapter.sent('GET /foods/1/comments').length;

    await expand(tester);
    expect(find.byType(EditableText), findsOneWidget, reason: '不跳新页面');
    expect(find.text('0 / 200'), findsOneWidget);
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
    expect(find.byType(EditableText), findsNothing, reason: '发出后收回成胶囊');
    expect(
      env.adapter.sent('GET /foods/1/comments').length,
      greaterThan(before),
    );
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('文字最多 200 字', (tester) async {
    final container = await open(tester);
    await expand(tester);

    await tester.enterText(find.byType(EditableText), '好' * 205);
    await tester.pump();
    expect(find.text('好' * 200), findsOneWidget);
    expect(find.text('200 / 200'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('全屏写：同一份草稿铺满屏幕，退出全屏后内容还在', (tester) async {
    final container = await open(tester);
    await expand(tester);
    await tester.enterText(find.byType(EditableText), '汤很鲜');
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('全屏'));
    await tester.pumpAndSettle();
    expect(find.text('写一条'), findsOneWidget);
    // 输入框从原处展开铺满屏幕, 下面的页面还在, 但已经被盖住点不到.
    expect(find.text('汤很鲜').hitTestable(), findsOneWidget);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getSize(find.bySemanticsLabel('评论内容').last).height,
      greaterThan(screen.height / 2),
    );
    await tester.enterText(find.byType(EditableText).last, '汤很鲜，面也筋道');
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('退出全屏'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('退出全屏'), findsNothing);
    expect(find.text('汤很鲜，面也筋道'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('最多加 3 张照片；只有照片也能发，照片按评论用途一次申请地址上传', (tester) async {
    env.photos.next = [
      for (var i = 0; i < 4; i++)
        PickedPhoto(bytes: transparentImage, width: 1, height: 1),
    ];
    env.adapter.on('POST /foods/1/comments', [FakeAdapter.ok(createdJson())]);
    final container = await open(tester);

    await tester.tap(find.bySemanticsLabel('带照片写一条'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册选'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('去掉第 . 张照片')), findsNWidgets(3));

    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
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

  testWidgets('收起时点相机：从相机展开「加照片」卡片，没选照片就关掉时输入框不展开', (tester) async {
    final container = await open(tester);

    await tester.tap(find.bySemanticsLabel('带照片写一条'));
    await tester.pumpAndSettle();
    expect(find.text('拍一张'), findsOneWidget);
    await expectAccessible(tester);
    await tester.tap(find.bySemanticsLabel('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('拍一张'), findsNothing);
    expect(find.byType(EditableText), findsNothing, reason: '还是胶囊');
    await unmountApp(tester, container);
  });

  testWidgets('点「回复」在屏幕最下面弹出回复横条，只能写字，提示「回复 某某」，带上被回复的那条', (tester) async {
    env.adapter.on('POST /foods/1/comments/11/replies', [
      FakeAdapter.ok(createdJson(id: 30)),
    ]);
    final container = await open(tester);

    // 最后一个 "回复" 箭头属于阿哲那条回复.
    await tester.tap(find.bySemanticsLabel('回复').last);
    await tester.pumpAndSettle();
    expect(find.text('回复 阿哲'), findsOneWidget);
    expect(find.bySemanticsLabel('加照片'), findsNothing);
    await expectAccessible(tester);

    await tester.enterText(find.byType(EditableText), '同意');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();

    final sent = env.adapter.sent('POST /foods/1/comments/11/replies').single;
    expect(sent.body, {'text': '同意', 'replyToId': 21});
    expect(recordedIn(container).propertiesOf<CommentSuccessEvent>(), [
      {'event': 'comment_success'},
    ]);
    expect(find.text('回复 阿哲'), findsNothing, reason: '发出后回复框收起');
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('回复横条贴在屏幕最下面，点横条外面收起', (tester) async {
    final container = await open(tester);
    await tester.tap(find.bySemanticsLabel('回复').first);
    await tester.pumpAndSettle();
    expect(find.text('回复 安安'), findsOneWidget);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getRect(find.text('发送')).bottom,
      greaterThan(screen.height - 80),
    );

    await tester.tapAt(const Offset(5, 200));
    await tester.pumpAndSettle();
    expect(find.text('回复 安安'), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('发送失败时内容保留，可以重发', (tester) async {
    env.adapter.on('POST /foods/1/comments', [
      const FakeResponse.offline(),
      FakeAdapter.ok(createdJson()),
    ]);
    final container = await open(tester);
    final recorded = recordedIn(container);
    await expand(tester);

    await tester.enterText(find.byType(EditableText), '汤很鲜');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('网络连接失败，请重试'), findsOneWidget);
    expect(find.text('汤很鲜'), findsOneWidget);
    expect(recorded.propertiesOf<CommentSuccessEvent>(), isEmpty);
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(env.adapter.sent('POST /foods/1/comments'), hasLength(2));
    expect(recorded.propertiesOf<CommentSuccessEvent>(), hasLength(1));
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('回复时被对方屏蔽：提示无法回复，内容保留', (tester) async {
    env.adapter.on('POST /foods/1/comments/11/replies', [
      FakeAdapter.fail(40002),
    ]);
    final container = await open(tester);
    await tester.tap(find.bySemanticsLabel('回复').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), '同意');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('无法回复对方'), findsOneWidget);
    expect(find.text('同意'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('回复里有联系方式：提示服务端说的原因，回复框和内容都保留', (tester) async {
    env.adapter.on('POST /foods/1/comments/11/replies', [
      FakeAdapter.fail(10001, '评论里不能放链接和联系方式'),
    ]);
    final container = await open(tester);
    await tester.tap(find.bySemanticsLabel('回复').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), '加我微信');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('评论里不能放链接和联系方式'), findsOneWidget);
    expect(find.text('回复 安安'), findsOneWidget);
    expect(find.text('加我微信'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('回复时评论已删除：提示已删除，收起回复框并刷新评论', (tester) async {
    env.adapter.on('POST /foods/1/comments/11/replies', [
      FakeAdapter.fail(10001, '被回复的评论不存在'),
    ]);
    final container = await open(tester);
    final before = env.adapter.sent('GET /foods/1/comments').length;
    await tester.tap(find.bySemanticsLabel('回复').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), '同意');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('这条评论已删除'), findsOneWidget);
    expect(find.text('回复 安安'), findsNothing);
    expect(
      env.adapter.sent('GET /foods/1/comments').length,
      greaterThan(before),
    );
    await tester.pump(const Duration(seconds: 3));
    await unmountApp(tester, container);
  });

  testWidgets('没认证时点输入框弹拦截对话框，不展开', (tester) async {
    final container = await open(
      tester,
      session: const SignedIn(user: testUser),
    );

    await tester.tap(find.text('吃过的话，说两句'));
    await tester.pumpAndSettle();
    expect(find.text('认证后才能评论'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('写了内容没发就返回时确认是否放弃', (tester) async {
    final (container, router) = await pumpApp(
      tester,
      env,
      session: const SignedIn(user: verifiedUser),
      location: Paths.dish(1),
    );
    unawaited(router.push(Paths.comments(1)));
    await tester.pumpAndSettle();
    await expand(tester);
    await tester.enterText(find.byType(EditableText), '汤很鲜');
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    expect(find.text('放弃这条评论？'), findsOneWidget);
    await tester.tap(find.text('继续写'));
    await tester.pumpAndSettle();
    expect(find.text('汤很鲜'), findsOneWidget);
    expect(find.byType(CommentsPage), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
    expect(find.byType(CommentsPage), findsNothing);
    expect(find.byType(DishPage), findsOneWidget);
    await unmountApp(tester, container);
  });
}
