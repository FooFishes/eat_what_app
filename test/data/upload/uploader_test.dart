import 'dart:typed_data';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// 远在未来的过期时间, 预先申请的地址不会被当作过期.
final _later = DateTime(2100).millisecondsSinceEpoch;

Map<String, Object?> _presigned(String name, {int? expireAt}) => {
  'putUrl': 'https://oss.test/put/$name',
  'key': 'foods/$name.jpg',
  'expireAt': expireAt ?? _later,
};

List<Uint8List> _files(int n) => [
  for (var i = 0; i < n; i++) Uint8List.fromList(List.filled(i + 1, i)),
];

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter
      ..onPattern(RegExp(r'^PUT https://oss\.test/put/'), [<String, Object?>{}])
      ..on('POST /upload/complete', [FakeAdapter.ok()]);
  });

  test('多张图一次申请地址，按顺序上传并逐张确认，回调每张的 key', () async {
    env.adapter.on('POST /upload/presign/batch', [
      FakeAdapter.ok({
        'files': [_presigned('a'), _presigned('b'), _presigned('c')],
      }),
    ]);
    final container = await env.container();
    final done = <(int, String)>[];

    final keys = await container
        .read(uploaderProvider)
        .uploadAll(
          _files(3),
          biz: UploadBiz.foods,
          onEach: (i, key) => done.add((i, key)),
        );

    expect(keys, ['foods/a.jpg', 'foods/b.jpg', 'foods/c.jpg']);
    expect(done, [(0, 'foods/a.jpg'), (1, 'foods/b.jpg'), (2, 'foods/c.jpg')]);
    expect(env.adapter.sent('POST /upload/presign'), isEmpty);
    final body =
        env.adapter.sent('POST /upload/presign/batch').single.body! as Map;
    expect(body['biz'], 'foods');
    expect([for (final f in body['files'] as List) f['fileSize']], [1, 2, 3]);
    expect(
      [for (final f in body['files'] as List) f['contentType']],
      [for (var i = 0; i < 3; i++) 'image/jpeg'],
    );
    expect(
      [for (final r in env.adapter.sent('POST /upload/complete')) r.body],
      [
        {'key': 'foods/a.jpg'},
        {'key': 'foods/b.jpg'},
        {'key': 'foods/c.jpg'},
      ],
    );
  });

  test('超过 9 张时分批申请', () async {
    env.adapter.on('POST /upload/presign/batch', [
      FakeAdapter.ok({
        'files': [for (var i = 0; i < 9; i++) _presigned('a$i')],
      }),
      FakeAdapter.ok({
        'files': [_presigned('b0')],
      }),
    ]);
    final container = await env.container();

    final presigned = await container
        .read(uploaderProvider)
        .presignAll(_files(10), biz: UploadBiz.comments);

    expect(presigned, hasLength(10));
    expect(presigned.last.key, 'foods/b0.jpg');
    final sizes = [
      for (final r in env.adapter.sent('POST /upload/presign/batch'))
        ((r.body! as Map)['files'] as List).length,
    ];
    expect(sizes, [9, 1]);
  });

  test('只有一张时用单张接口', () async {
    env.adapter.on('POST /upload/presign', [FakeAdapter.ok(_presigned('a'))]);
    final container = await env.container();

    final keys = await container
        .read(uploaderProvider)
        .uploadAll(_files(1), biz: UploadBiz.feedback);

    expect(keys, ['foods/a.jpg']);
    expect(env.adapter.sent('POST /upload/presign/batch'), isEmpty);
    expect(
      env.adapter.sent('POST /upload/presign').single.body,
      containsPair('biz', 'feedback'),
    );
  });

  test('预先申请的地址临近过期时单张重新申请', () async {
    env.adapter.on('POST /upload/presign', [FakeAdapter.ok(_presigned('new'))]);
    final container = await env.container();
    final uploader = container.read(uploaderProvider);
    env.adapter.on('POST /upload/presign/batch', [
      FakeAdapter.ok({
        'files': [
          _presigned('old', expireAt: DateTime.now().millisecondsSinceEpoch),
          _presigned('ok'),
        ],
      }),
    ]);

    final presigned = await uploader.presignAll(
      _files(2),
      biz: UploadBiz.foods,
    );
    final stale = await uploader.upload(
      _files(1).single,
      biz: UploadBiz.foods,
      presigned: presigned.first,
    );
    final fresh = await uploader.upload(
      _files(1).single,
      biz: UploadBiz.foods,
      presigned: presigned.last,
    );

    expect(stale, 'foods/new.jpg');
    expect(fresh, 'foods/ok.jpg');
    expect(env.adapter.sent('POST /upload/presign'), hasLength(1));
    expect(env.adapter.sent('PUT https://oss.test/put/old'), isEmpty);
  });

  test('批量申请返回的数量不对时失败，不上传', () async {
    env.adapter.on('POST /upload/presign/batch', [
      FakeAdapter.ok({
        'files': [_presigned('a')],
      }),
    ]);
    final container = await env.container();

    await expectLater(
      container
          .read(uploaderProvider)
          .uploadAll(_files(2), biz: UploadBiz.foods),
      throwsA(isA<AppFailure>()),
    );
    expect(env.adapter.sent('POST /upload/complete'), isEmpty);
  });

  group('上传接口被拒时的提示', () {
    Future<AppFailure> failWith(String route, Object code, String msg) async {
      env.adapter
        ..on('POST /upload/presign', [FakeAdapter.ok(_presigned('a'))])
        ..on(route, [FakeAdapter.fail(code, msg)]);
      final container = await env.container();
      try {
        await container
            .read(uploaderProvider)
            .upload(_files(1).single, biz: UploadBiz.foods);
      } on AppFailure catch (e) {
        return e;
      }
      fail('没有失败');
    }

    test('文件不合规、内容检查未通过、还在检查时显示服务端的原因', () async {
      for (final (route, code, msg) in [
        ('POST /upload/presign', 10001, '文件不能超过 10MB'),
        ('POST /upload/complete', 10001, '这张照片未通过内容检查：照片里有二维码，请更换'),
        ('POST /upload/complete', 40001, '文件还没有上传完成'),
        ('POST /upload/complete', 40004, '图片正在检查，请稍后重试'),
      ]) {
        final failure = await failWith(route, code, msg);
        expect(failure.kind, FailureKind.business);
        expect(failure.message, msg);
      }
    });

    test('字段校验和只有默认文案的 msg 不显示，用客户端的提示', () async {
      final field = await failWith(
        'POST /upload/presign',
        10001,
        'contentType不能为空',
      );
      expect(field.message, '提交的内容有误，请检查后重试');
      final generic = await failWith('POST /upload/complete', 40001, '操作失败');
      expect(generic.userMessage, isNull);
      expect(generic.kind, FailureKind.unknown);
    });

    test('没权限和限流照旧处理，不显示服务端的 msg', () async {
      final forbidden = await failWith(
        'POST /upload/presign',
        20004,
        '请先完成身份认证',
      );
      expect(forbidden.kind, FailureKind.forbidden);
      expect(forbidden.userMessage, isNull);
      final frequent = await failWith('POST /upload/presign', 10003, '请求频率过高');
      expect(frequent.kind, FailureKind.tooFrequent);
      expect(frequent.message, '操作过于频繁，请稍后再试');
    });

    test('客户端自己发现的问题不显示内部说明', () async {
      env.adapter.on('POST /upload/presign', [
        FakeAdapter.ok({'key': 'foods/a.jpg', 'expireAt': _later}),
      ]);
      final container = await env.container();
      await expectLater(
        container
            .read(uploaderProvider)
            .upload(_files(1).single, biz: UploadBiz.foods),
        throwsA(
          isA<AppFailure>().having((e) => e.message, 'message', '操作失败，请重试'),
        ),
      );
    });
  });
}
