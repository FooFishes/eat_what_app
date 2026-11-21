import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/upload_dto.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:eat/features/publish/publish_providers.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const original = Dish(
    id: 1,
    name: '鲜虾云吞',
    shopId: 7,
    price: 18,
    category: DishCategory.staple,
    stage: StageColor.broth,
    tags: [Taste.spicy, Taste.sweet],
    description: '汤很鲜',
  );

  const unchanged = PublishDraft(
    category: DishCategory.staple,
    tastes: {Taste.sweet, Taste.spicy},
  );

  DishChange? change(
    PublishDraft draft, {
    String name = '鲜虾云吞',
    double? price,
    String description = '汤很鲜',
  }) => draft.changeFrom(
    original,
    name: name,
    price: price,
    description: description,
  );

  test('内容和原菜一样时没有改动，口味顺序不同不算改动', () {
    expect(change(unchanged), isNull);
    expect(change(unchanged, price: 18), isNull);
  });

  test('只带改了的字段；说明清空传空串，口味清空传空列表', () {
    final result = change(
      unchanged.copy(tastes: const {}, signature: true),
      price: 20,
      description: '',
    )!;
    expect(result.name, isNull);
    expect(result.category, isNull);
    expect(result.price, 20);
    expect(result.description, '');
    expect(result.tags, isEmpty);
    expect(result.signature, isTrue);
    expect(result.imageKeys, isNull);
    expect(result.stage, isNull);
    expect(result.crop, isNull);
  });

  test('换了照片时带上整组新照片和新封面的舞台色、备选色、取景', () {
    final photo = DraftPhoto(
      id: 0,
      photo: PickedPhoto(bytes: transparentImage, width: 1, height: 1),
      image: MemoryImage(transparentImage),
      status: UploadStatus.done,
      progress: 1,
      key: 'foods/a.jpg',
    );
    final result = change(
      unchanged.copy(photos: [photo], pickedStage: StageColor.chili),
    )!;
    expect(result.imageKeys, ['foods/a.jpg']);
    expect(result.stage, StageColor.chili);
    expect(result.stageAlternates, hasLength(2));
    expect(result.crop, isNotNull);
    expect(result.tags, isNull);
  });

  test('一次加多张照片时一次申请地址，再按并发上限逐张上传', () async {
    final env = TestEnv();
    final later = DateTime(2100).millisecondsSinceEpoch;
    env.adapter
      ..on('POST /upload/presign/batch', [
        FakeAdapter.ok({
          'files': [
            for (final name in ['a', 'b', 'c'])
              {
                'putUrl': 'https://oss.test/put/$name',
                'key': 'foods/$name.jpg',
                'expireAt': later,
              },
          ],
        }),
      ])
      ..onPattern(RegExp(r'^PUT https://oss\.test/put/'), [<String, Object?>{}])
      ..on('POST /upload/complete', [FakeAdapter.ok()]);
    final container = await env.container();
    final provider = draftProvider();
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);

    container.read(provider.notifier).addPhotos([
      for (var i = 0; i < 3; i++)
        PickedPhoto(bytes: transparentImage, width: 1, height: 1),
    ]);
    while (container
        .read(provider)
        .photos
        .any((p) => p.status != UploadStatus.done)) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(env.adapter.sent('POST /upload/presign/batch'), hasLength(1));
    expect(env.adapter.sent('POST /upload/presign'), isEmpty);
    expect(
      [for (final p in container.read(provider).photos) p.key],
      ['foods/a.jpg', 'foods/b.jpg', 'foods/c.jpg'],
    );
  });

  group('回到前台后的自动重试', () {
    late List<Completer<String>> calls;
    late ProviderContainer container;
    final provider = draftProvider();

    setUp(() async {
      calls = [];
      container = await TestEnv().container(
        overrides: [uploaderProvider.overrideWithValue(_HeldUploader(calls))],
      );
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
    });

    Draft draft() => container.read(provider.notifier);
    List<UploadStatus> statuses() => [
      for (final p in container.read(provider).photos) p.status,
    ];
    Future<void> settle() => Future<void>.delayed(Duration.zero);
    void add(int count) => draft().addPhotos([
      for (var i = 0; i < count; i++)
        PickedPhoto(bytes: transparentImage, width: 1, height: 1),
    ]);

    test('进后台时在途、回前台后才失败的照片立即重试一次', () async {
      add(1);
      await settle();
      expect(calls, hasLength(1));

      draft().enterBackground();
      draft().retryFailedOnce();
      calls[0].completeError(const AppFailure.network());
      await settle();
      expect(calls, hasLength(2));
      expect(statuses(), [UploadStatus.uploading]);
      expect(container.read(provider).photos.single.autoRetried, isTrue);

      calls[1].completeError(const AppFailure.network());
      await settle();
      expect(calls, hasLength(2));
      expect(statuses(), [UploadStatus.failed]);

      draft().enterBackground();
      draft().retryFailedOnce();
      await settle();
      expect(calls, hasLength(2));
      expect(statuses(), [UploadStatus.failed]);
    });

    test('后台期间就失败的照片只在回前台时重试一次', () async {
      add(1);
      await settle();
      draft().enterBackground();
      calls[0].completeError(const AppFailure.network());
      await settle();
      expect(calls, hasLength(1));
      expect(statuses(), [UploadStatus.failed]);

      draft().retryFailedOnce();
      await settle();
      expect(calls, hasLength(2));
      calls[1].completeError(const AppFailure.network());
      await settle();
      expect(calls, hasLength(2));
      expect(statuses(), [UploadStatus.failed]);
    });

    test('进后台时不在途的照片失败后不自动重试', () async {
      draft().enterBackground();
      draft().retryFailedOnce();
      add(1);
      await settle();
      calls[0].completeError(const AppFailure.network());
      await settle();
      expect(calls, hasLength(1));
      expect(statuses(), [UploadStatus.failed]);
      expect(container.read(provider).photos.single.autoRetried, isFalse);
    });

    test('进后台时在途、回前台后上传成功的照片正常完成', () async {
      add(1);
      await settle();
      draft().enterBackground();
      draft().retryFailedOnce();
      calls[0].complete('foods/a.jpg');
      await settle();
      expect(statuses(), [UploadStatus.done]);
    });

    for (final (action, drop) in <(String, void Function(Draft, int))>[
      ('删除', (d, id) => d.remove(id)),
      ('清空', (d, _) => d.clearPhotos()),
    ]) {
      test('进后台时在途的照片被$action后，回前台新加的照片失败不自动重试', () async {
        add(1);
        await settle();
        draft().enterBackground();
        drop(draft(), container.read(provider).photos.single.id);
        calls[0].completeError(const AppFailure.cancelled());
        await settle();
        expect(statuses(), isEmpty);

        draft().retryFailedOnce();
        add(1);
        await settle();
        expect(calls, hasLength(2));
        calls[1].completeError(const AppFailure.network());
        await settle();
        expect(calls, hasLength(2));
        expect(statuses(), [UploadStatus.failed]);
        expect(container.read(provider).photos.single.autoRetried, isFalse);
      });
    }

    test('自动重试过的照片手动重试再失败时不再自动重试', () async {
      add(1);
      await settle();
      draft().enterBackground();
      draft().retryFailedOnce();
      calls[0].completeError(const AppFailure.network());
      await settle();
      expect(calls, hasLength(2));
      calls[1].completeError(const AppFailure.network());
      await settle();
      expect(statuses(), [UploadStatus.failed]);

      draft().retry(container.read(provider).photos.single.id);
      await settle();
      expect(calls, hasLength(3));
      expect(statuses(), [UploadStatus.uploading]);
      calls[2].completeError(const AppFailure.network());
      await settle();
      expect(calls, hasLength(3));
      expect(statuses(), [UploadStatus.failed]);
      expect(container.read(provider).photos.single.autoRetried, isTrue);
    });
  });
}

/// 每次上传都挂起, 由测试通过 [calls] 里的 [Completer] 决定何时以何种结果结束.
class _HeldUploader implements Uploader {
  _HeldUploader(this.calls);

  final List<Completer<String>> calls;

  @override
  Future<String> upload(
    Uint8List jpeg, {
    required UploadBiz biz,
    PresignDto? presigned,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) {
    final call = Completer<String>();
    calls.add(call);
    return call.future;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
