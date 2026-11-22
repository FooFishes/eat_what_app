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
    images: [
      DishImage(url: 'https://img.test/foods/a.jpg', key: 'foods/a.jpg'),
      DishImage(url: 'https://img.test/foods/b.jpg', key: 'foods/b.jpg'),
    ],
    stage: StageColor.soy,
    crop: CoverCrop(centerX: 0.4, diameter: 0.8),
    tags: [Taste.spicy, Taste.sweet],
    description: '汤很鲜',
  );

  DraftPhoto existing(int id, String key) => DraftPhoto(
    id: id,
    image: MemoryImage(transparentImage),
    status: UploadStatus.done,
    progress: 1,
    key: key,
  );

  DraftPhoto added(int id, String? key) => DraftPhoto(
    id: id,
    photo: PickedPhoto(bytes: transparentImage, width: 1, height: 1),
    image: MemoryImage(transparentImage),
    status: key == null ? UploadStatus.uploading : UploadStatus.done,
    progress: key == null ? 0.5 : 1,
    key: key,
  );

  final a = existing(0, 'foods/a.jpg');
  final b = existing(1, 'foods/b.jpg');

  final unchanged = PublishDraft(
    photos: [a, b],
    crop: original.crop,
    pickedStage: original.stage,
    category: DishCategory.staple,
    tastes: const {Taste.sweet, Taste.spicy},
  );

  DishChange? change(
    PublishDraft draft, {
    String name = '鲜虾云吞',
    double? price,
    String description = '汤很鲜',
    Dish dish = original,
  }) => draft.changeFrom(
    dish,
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

  test('删掉后面的一张：带剩下的 key，封面没变不带舞台色和取景', () {
    final result = change(unchanged.copy(photos: [a]))!;
    expect(result.imageKeys, ['foods/a.jpg']);
    expect(result.stage, isNull);
    expect(result.stageAlternates, isNull);
    expect(result.crop, isNull);
  });

  test('追加一张：原图带原 key，新图带上传得到的 key，没传完时也算改动', () {
    final result = change(
      unchanged.copy(photos: [a, b, added(2, 'foods/c.jpg')]),
    )!;
    expect(result.imageKeys, ['foods/a.jpg', 'foods/b.jpg', 'foods/c.jpg']);
    expect(result.stage, isNull);
    expect(result.crop, isNull);

    expect(change(unchanged.copy(photos: [a, b, added(2, null)])), isNotNull);
  });

  test('换了封面：带新顺序和新封面的舞台色、备选色、取景', () {
    final result = change(
      unchanged.copy(
        photos: [b, a],
        coverEdited: true,
        crop: const CoverCrop(),
        pickedStage: StageColor.chili,
      ),
    )!;
    expect(result.imageKeys, ['foods/b.jpg', 'foods/a.jpg']);
    expect(result.stage, StageColor.chili);
    expect(result.stageAlternates, hasLength(2));
    expect(result.stageAlternates, isNot(contains(StageColor.chili)));
    expect(result.crop, isNotNull);
    expect(result.tags, isNull);
  });

  test('只调整了原封面的取景和颜色：不带照片，带舞台色和取景', () {
    final result = change(
      unchanged.copy(
        coverEdited: true,
        crop: const CoverCrop(centerY: 0.3),
        pickedStage: StageColor.mango,
      ),
    )!;
    expect(result.imageKeys, isNull);
    expect(result.stage, StageColor.mango);
    expect(result.crop?.centerY, 0.3);
  });

  test('换了封面但取色没有结果时用分类默认色', () {
    final result = change(
      unchanged.copy(photos: [b], coverEdited: true, clearPicked: true),
    )!;
    expect(result.stage, DishCategory.staple.stage);
  });

  test('原菜品缺照片 key 时照片锁住，不带照片和封面的任何字段', () {
    const legacy = Dish(
      id: 1,
      name: '鲜虾云吞',
      shopId: 7,
      category: DishCategory.staple,
      images: [DishImage(url: 'https://img.test/foods/a.jpg')],
      stage: StageColor.soy,
      tags: [Taste.spicy, Taste.sweet],
      description: '汤很鲜',
    );
    final locked = PublishDraft(
      photos: [
        DraftPhoto(
          id: 0,
          image: MemoryImage(transparentImage),
          status: UploadStatus.done,
        ),
      ],
      photosLocked: true,
      pickedStage: StageColor.soy,
      category: DishCategory.staple,
      tastes: const {Taste.sweet, Taste.spicy},
    );
    expect(change(locked, dish: legacy), isNull);
    final result = change(
      locked.copy(coverEdited: true),
      dish: legacy,
      name: '虾饺',
    )!;
    expect(result.name, '虾饺');
    expect(result.imageKeys, isNull);
    expect(result.stage, isNull);
    expect(result.crop, isNull);
  });

  group('编辑时的草稿', () {
    late ProviderContainer container;
    final provider = draftProvider(original: original);

    setUp(() async {
      container = await TestEnv().container();
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
    });

    test('原有照片作为已上传的照片载入，带原 key；舞台色和取景沿用原值', () {
      final draft = container.read(provider);
      expect(
        [for (final p in draft.photos) (p.photo, p.status, p.key)],
        [
          (null, UploadStatus.done, 'foods/a.jpg'),
          (null, UploadStatus.done, 'foods/b.jpg'),
        ],
      );
      expect(draft.stage, StageColor.soy);
      expect(draft.crop.centerX, 0.4);
      expect(draft.coverEdited, isFalse);
      expect(draft.photosLocked, isFalse);
    });

    test('删掉封面后第二张成了封面，取景回到居中，要重新定舞台色', () {
      final notifier = container.read(provider.notifier);
      notifier.remove(container.read(provider).photos.first.id);
      final draft = container.read(provider);
      expect([for (final p in draft.photos) p.key], ['foods/b.jpg']);
      expect(draft.coverEdited, isTrue);
      expect(draft.pickedStage, isNull);
      expect(draft.crop.centerX, 0.5);
    });

    test('删掉后面的一张不动封面', () {
      final notifier = container.read(provider.notifier);
      notifier.remove(container.read(provider).photos.last.id);
      final draft = container.read(provider);
      expect(draft.coverEdited, isFalse);
      expect(draft.stage, StageColor.soy);
    });

    test('缺照片 key 的菜照片锁住', () async {
      const legacy = Dish(
        id: 2,
        name: '虾饺',
        shopId: 7,
        images: [DishImage(url: 'https://img.test/foods/a.jpg')],
        stage: StageColor.soy,
      );
      final draft = container.read(draftProvider(original: legacy));
      expect(draft.photosLocked, isTrue);
      expect(draft.photos, hasLength(1));
    });
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

    test('进后台时在途的照片被删除后，回前台新加的照片失败不自动重试', () async {
      add(1);
      await settle();
      draft().enterBackground();
      draft().remove(container.read(provider).photos.single.id);
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
