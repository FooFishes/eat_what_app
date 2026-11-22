import 'dart:math';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_dto.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/crop_viewport.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/dish_revision.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const newDish = NewDish(
    shopId: 7,
    name: '云吞',
    imageKeys: ['foods/a.jpg', 'foods/b.jpg'],
    price: 18,
    category: DishCategory.staple,
    stage: StageColor.broth,
    stageAlternates: [StageColor.mango, StageColor.bamboo],
    tags: [Taste.spicy, Taste.numbing],
    signature: true,
    description: '汤很鲜',
  );

  test('发布：照片、口味、招牌按 v2 字段发出，舞台色和取景照常带上，不带幂等键', () async {
    final env = TestEnv();
    env.adapter.on('POST /foods/upload', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final container = await env.container();

    final id = await container.read(foodRepositoryProvider).publish(newDish);

    expect(id, 9);
    final request = env.adapter.sent('POST /foods/upload').single;
    expect(request.body, {
      'restaurantId': 7,
      'name': '云吞',
      'category': '主食',
      'price': 18.0,
      'description': '汤很鲜',
      'pictures': ['foods/a.jpg', 'foods/b.jpg'],
      'tags': ['辣', '麻'],
      'signature': true,
      'stageColor': 'broth',
      'stageAlternates': ['mango', 'bamboo'],
      'coverCrop': {'centerX': 0.5, 'centerY': 0.5, 'diameter': 1.0},
      'deliveryEnabled': false,
    });
    expect(request.headers.containsKey('Idempotency-Key'), isFalse);
  });

  test('发布：选了饭点和外卖时带上；没选饭点时不带，沿用店铺', () async {
    final env = TestEnv();
    env.adapter.on('POST /foods/upload', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final container = await env.container();

    await container
        .read(foodRepositoryProvider)
        .publish(
          const NewDish(
            shopId: 7,
            name: '云吞',
            imageKeys: ['k'],
            price: 18,
            category: DishCategory.staple,
            stage: StageColor.broth,
            stageAlternates: [],
            mealTimes: [MealTime.breakfast, MealTime.night],
            deliveryEnabled: true,
          ),
        );

    final body =
        env.adapter.sent('POST /foods/upload').single.body!
            as Map<String, dynamic>;
    expect(body['mealTimes'], ['breakfast', 'night']);
    expect(body['deliveryEnabled'], isTrue);
  });

  test('发布撞名时失败原因带上已有那道菜的 id', () async {
    final env = TestEnv();
    env.adapter.on('POST /foods/upload', [
      {
        'code': BizCodes.duplicateDish,
        'msg': 'exists',
        'data': {'id': 5},
        'timestamp': 0,
      },
    ]);
    final container = await env.container();

    final failure = await container
        .read(foodRepositoryProvider)
        .publish(newDish)
        .then<AppFailure?>((_) => null, onError: (Object e) => e as AppFailure);

    expect(failure?.code, BizCodes.duplicateDish);
    expect(failure?.data, {'id': 5});
  });

  test('发布时裁切参数取整到 4 位小数', () async {
    final env = TestEnv();
    env.adapter.on('POST /foods/upload', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final container = await env.container();

    await container
        .read(foodRepositoryProvider)
        .publish(
          const NewDish(
            shopId: 7,
            name: '云吞',
            imageKeys: ['k'],
            price: 18,
            category: DishCategory.staple,
            stage: StageColor.broth,
            stageAlternates: [],
            crop: CoverCrop(
              centerX: 0.123456789,
              centerY: 0.98766,
              diameter: 0.3333333333,
            ),
          ),
        );

    final body =
        env.adapter.sent('POST /foods/upload').single.body!
            as Map<String, dynamic>;
    expect(body['coverCrop'], {
      'centerX': 0.1235,
      'centerY': 0.9876,
      'diameter': 0.3333,
    });
  });

  group('编辑', () {
    test('只发出改动的字段；空说明、空照片和空口味表示清除；返回修改记录 id 和保存后的照片', () async {
      final env = TestEnv();
      env.adapter.on('PUT /foods/edit/1', [
        FakeAdapter.ok({'id': 1, 'revisionId': 31, 'pictureKeys': <String>[]}),
      ]);
      final container = await env.container();

      final edited = await container
          .read(foodRepositoryProvider)
          .edit(
            1,
            const DishChange(
              price: 16,
              description: '',
              imageKeys: [],
              tags: [],
              signature: false,
            ),
          );

      expect(edited.revisionId, 31);
      expect(edited.imageKeys, isEmpty);
      expect(env.adapter.sent('PUT /foods/edit/1').single.body, {
        'price': 16.0,
        'description': '',
        'pictures': <String>[],
        'tags': <String>[],
        'signature': false,
      });
    });

    test('饭点传空数组表示改回沿用店铺；外卖照改动发出', () async {
      final env = TestEnv();
      env.adapter.on('PUT /foods/edit/1', [
        FakeAdapter.ok({'id': 1, 'revisionId': 33}),
      ]);
      final container = await env.container();

      await container
          .read(foodRepositoryProvider)
          .edit(1, const DishChange(mealTimes: [], deliveryEnabled: false));

      expect(env.adapter.sent('PUT /foods/edit/1').single.body, {
        'mealTimes': <String>[],
        'deliveryEnabled': false,
      });
    });

    test('改了分类、口味、舞台色和取景时按 v2 字段发出', () async {
      final env = TestEnv();
      env.adapter.on('PUT /foods/edit/1', [
        FakeAdapter.ok({'id': 1, 'revisionId': 32}),
      ]);
      final container = await env.container();

      await container
          .read(foodRepositoryProvider)
          .edit(
            1,
            const DishChange(
              name: '鲜虾云吞',
              category: DishCategory.drinkDessert,
              tags: [Taste.sweet],
              stage: StageColor.mango,
              stageAlternates: [StageColor.soy, StageColor.chili],
              crop: CoverCrop(centerX: 0.123456, diameter: 0.55555),
            ),
          );

      expect(env.adapter.sent('PUT /foods/edit/1').single.body, {
        'name': '鲜虾云吞',
        'category': '饮品甜品',
        'tags': ['甜'],
        'stageColor': 'mango',
        'stageAlternates': ['soy', 'chili'],
        'coverCrop': {'centerX': 0.1235, 'centerY': 0.5, 'diameter': 0.5555},
      });
    });

    test('保留的原图和新图按顺序发出 key；返回保存后的照片顺序', () async {
      final env = TestEnv();
      env.adapter.on('PUT /foods/edit/1', [
        FakeAdapter.ok({
          'id': 1,
          'revisionId': 34,
          'pictureKeys': ['foods/b.jpg', 'foods/a.jpg', 'foods/c.jpg'],
        }),
      ]);
      final container = await env.container();

      final edited = await container
          .read(foodRepositoryProvider)
          .edit(
            1,
            const DishChange(
              imageKeys: ['foods/b.jpg', 'foods/a.jpg', 'foods/c.jpg'],
            ),
          );

      expect(env.adapter.sent('PUT /foods/edit/1').single.body, {
        'pictures': ['foods/b.jpg', 'foods/a.jpg', 'foods/c.jpg'],
      });
      expect(edited.revisionId, 34);
      expect(edited.imageKeys, ['foods/b.jpg', 'foods/a.jpg', 'foods/c.jpg']);
    });

    test('内容没有变化时修改记录 id 为 null，照片仍是当前的', () async {
      final env = TestEnv();
      env.adapter.on('PUT /foods/edit/1', [
        FakeAdapter.ok({
          'id': 1,
          'revisionId': null,
          'pictureKeys': ['foods/1.jpg'],
        }),
      ]);
      final container = await env.container();

      final edited = await container
          .read(foodRepositoryProvider)
          .edit(1, const DishChange(name: '鲜虾蟹籽云吞'));

      expect(edited.revisionId, isNull);
      expect(edited.imageKeys, ['foods/1.jpg']);
    });
  });

  test('修改记录：动作、编辑者、改动的字段，不认识的字段跳过', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/1/history', [
      FakeAdapter.ok({
        'currentPage': 1,
        'items': [
          {
            'id': 32,
            'action': 'restore',
            'editor': {'id': 9, 'displayName': '小林', 'avatar': ''},
            'restoredFrom': 30,
            'changes': [
              {'field': 'price', 'from': 16, 'to': 18},
              {
                'field': 'pictures',
                'from': ['https://img.test/a.jpg'],
                'to': <String>[],
              },
              {'field': 'spiciness', 'from': 1, 'to': 2},
              {
                'field': 'mealTimes',
                'from': <String>[],
                'to': ['lunch'],
              },
              {'field': 'deliveryEnabled', 'from': false, 'to': true},
            ],
            'createdAt': 1792763739329,
          },
          {
            'id': 30,
            'action': 'create',
            'editor': {'id': null, 'displayName': null, 'avatar': null},
            'restoredFrom': null,
            'changes': [
              {'field': 'name', 'from': null, 'to': '云吞'},
            ],
            'createdAt': 1792763739000,
          },
        ],
        'totalPages': 2,
        'totalItems': 21,
        'hasNext': true,
      }),
    ]);
    final container = await env.container();

    final page = await container.read(foodRepositoryProvider).history(1);

    expect(page.total, 21);
    expect(page.hasNext, isTrue);
    final [restored, created] = page.items;
    expect(restored.action, RevisionAction.restore);
    expect(restored.restoredFrom, 30);
    expect((restored.editorId, restored.editorName), (9, '小林'));
    expect(restored.editorAvatar, isNull);
    expect(restored.fields, [
      DishField.price,
      DishField.pictures,
      DishField.mealTimes,
      DishField.deliveryEnabled,
    ]);
    expect(created.action, RevisionAction.create);
    expect((created.editorId, created.editorName), (null, null));
    expect(env.adapter.sent('GET /foods/1/history').single.query, {
      'page': 1,
      'pageSize': 20,
    });
  });

  test('恢复到当前版本时失败原因是 40002', () async {
    final env = TestEnv();
    env.adapter.on('POST /foods/1/history/30/restore', [
      FakeAdapter.fail(BizCodes.stateNotAllowed),
    ]);
    final container = await env.container();

    await expectLater(
      container.read(foodRepositoryProvider).restore(1, 30),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.code,
          'code',
          BizCodes.stateNotAllowed,
        ),
      ),
    );
  });

  test('识别分类和口味：最多发 3 张照片，不认识的口味跳过', () async {
    final env = TestEnv();
    env.adapter.on('POST /foods/suggest-tags', [
      FakeAdapter.ok({
        'category': '汤',
        'tags': ['辣', '咸'],
      }),
    ]);
    final container = await env.container();

    final suggestion = await container
        .read(foodRepositoryProvider)
        .suggestTags(
          name: '酸辣汤',
          shopId: 7,
          imageKeys: ['k1', 'k2', 'k3', 'k4'],
        );

    expect(suggestion.category, DishCategory.soup);
    expect(suggestion.tags, [Taste.spicy]);
    expect(env.adapter.sent('POST /foods/suggest-tags').single.body, {
      'name': '酸辣汤',
      'restaurantId': 7,
      'pictures': ['k1', 'k2', 'k3'],
    });
  });

  test('裁切取整后都是 4 位小数，且仍满足 clampCircleCrop 的约束', () {
    bool fourDecimals(double v) => (v * 10000).round() / 10000 == v;
    final random = Random(7);
    for (var i = 0; i < 5000; i++) {
      final width = 1 + random.nextInt(8000);
      final height = 1 + random.nextInt(8000);
      final raw = clampCircleCrop(
        (
          centerX: random.nextDouble(),
          centerY: random.nextDouble(),
          diameter: random.nextDouble(),
        ),
        width: width,
        height: height,
      );

      final rounded = FoodRepository.roundCrop(
        CoverCrop(
          centerX: raw.centerX,
          centerY: raw.centerY,
          diameter: raw.diameter,
        ),
      );
      final crop = (
        centerX: rounded.centerX,
        centerY: rounded.centerY,
        diameter: rounded.diameter,
      );

      expect(fourDecimals(crop.centerX), isTrue, reason: '$crop');
      expect(fourDecimals(crop.centerY), isTrue, reason: '$crop');
      expect(fourDecimals(crop.diameter), isTrue, reason: '$crop');
      expect(crop.diameter, greaterThanOrEqualTo(minCropDiameter));
      expect(
        clampCircleCrop(crop, width: width, height: height),
        crop,
        reason: '$width×$height $raw',
      );
      expect((crop.centerX - raw.centerX).abs(), lessThan(0.0001));
      expect((crop.centerY - raw.centerY).abs(), lessThan(0.0001));
    }
  });

  test('贴边的取景和居中内切圆取整后不变或向内收', () {
    final edge = clampCircleCrop(
      (centerX: 0, centerY: 1, diameter: 0.3333333),
      width: 4032,
      height: 3024,
    );
    final rounded = FoodRepository.roundCrop(
      CoverCrop(
        centerX: edge.centerX,
        centerY: edge.centerY,
        diameter: edge.diameter,
      ),
    );
    expect(rounded.centerX, greaterThanOrEqualTo(edge.centerX));
    expect(rounded.centerY, lessThanOrEqualTo(edge.centerY));
    expect(rounded.diameter, lessThanOrEqualTo(edge.diameter));

    final center = FoodRepository.roundCrop(const CoverCrop());
    expect((center.centerX, center.centerY, center.diameter), (0.5, 0.5, 1.0));
  });

  test('DTO 转成菜：分类、口味、招牌、赞数、上传者和图片地址', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/detail/1', [
      FakeAdapter.ok(
        foodJson(category: '小吃', tags: ['辣', '咸', '麻'], signature: true),
      ),
    ]);
    final container = await env.container();

    final dish = await container.read(foodRepositoryProvider).detail(1);

    expect(dish.category, DishCategory.snack);
    expect(dish.tags, [Taste.spicy, Taste.numbing]);
    expect(dish.signature, isTrue);
    expect(dish.likes, 12);
    expect(dish.uploaderId, 9);
    expect(dish.cover, 'https://img.test/foods/1.jpg');
    expect(dish.price, 18);
  });

  group('照片的 key', () {
    Future<Dish> dishOf(Map<String, Object?> json) async {
      final container = await TestEnv().container();
      return container
          .read(foodRepositoryProvider)
          .toDish(FoodDto.fromJson(json));
    }

    test('地址和 key 按位置配对', () async {
      final dish = await dishOf(
        foodJson(pictures: ['foods/a.jpg', 'foods/b.jpg']),
      );
      expect(
        [for (final image in dish.images) (image.url, image.key)],
        [
          ('https://img.test/foods/a.jpg', 'foods/a.jpg'),
          ('https://img.test/foods/b.jpg', 'foods/b.jpg'),
        ],
      );
      expect(dish.imageKeys, ['foods/a.jpg', 'foods/b.jpg']);
    });

    test('没有 key（旧缓存）时照片照常显示，但不带 key', () async {
      final dish = await dishOf({...foodJson(), 'pictureKeys': null});
      expect(dish.cover, 'https://img.test/foods/1.jpg');
      expect(dish.images.single.key, isNull);
      expect(dish.imageKeys, isNull);
    });

    test('key 和地址数量对不上，或有空地址、空 key 时都不带 key', () async {
      for (final (urls, keys) in [
        (['https://img.test/a.jpg', 'https://img.test/b.jpg'], ['a.jpg']),
        (['https://img.test/a.jpg', ''], ['a.jpg', 'b.jpg']),
        (['https://img.test/a.jpg'], ['']),
      ]) {
        final dish = await dishOf({
          ...foodJson(),
          'pictureUrls': urls,
          'pictureKeys': keys,
        });
        expect(dish.images.map((i) => i.url), [
          for (final url in urls)
            if (url.isNotEmpty) url,
        ]);
        expect(dish.imageKeys, isNull, reason: '$urls $keys');
      }
    });

    test('没有照片时 key 列表为空', () async {
      final dish = await dishOf(foodJson(pictures: []));
      expect(dish.images, isEmpty);
      expect(dish.imageKeys, isEmpty);
    });
  });

  test('DTO 转成菜：饭点、外卖、评分和我的评分，不认识的饭点跳过', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/detail/1', [
      FakeAdapter.ok({
        ...foodJson(),
        'mealTimes': <String>[],
        'effectiveMealTimes': ['lunch', 'brunch', 'dinner'],
        'deliveryEnabled': true,
        'rating': {'score': 4.5, 'count': 12},
        'myRating': 5,
      }),
    ]);
    final container = await env.container();
    final repo = container.read(foodRepositoryProvider);

    final dish = await repo.detail(1);

    expect(dish.mealTimes, isEmpty);
    expect(dish.effectiveMealTimes, [MealTime.lunch, MealTime.dinner]);
    expect(dish.deliveryEnabled, isTrue);
    expect((dish.rating.score, dish.rating.count), (4.5, 12));
    expect(dish.myRating, 5);
    final cached = await repo.cachedDetail(1);
    expect((cached?.rating.score, cached?.myRating), (4.5, 5));
  });

  test('DTO 转成菜：没人评分、游客时评分为空', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/detail/1', [
      FakeAdapter.ok({
        ...foodJson(),
        'rating': {'score': null, 'count': 0},
        'myRating': null,
      }),
    ]);
    final container = await env.container();

    final dish = await container.read(foodRepositoryProvider).detail(1);

    expect((dish.rating.score, dish.rating.count), (null, 0));
    expect(dish.myRating, isNull);
    expect(dish.deliveryEnabled, isFalse);
  });

  group('舞台色和取景', () {
    Future<Dish> dishOf(Map<String, Object?> json) async {
      final container = await TestEnv().container();
      return container
          .read(foodRepositoryProvider)
          .toDish(FoodDto.fromJson(json));
    }

    test('服务端没返回时用分类的默认色，取景居中', () async {
      final dish = await dishOf(foodJson(category: '小吃'));
      expect(dish.stage, StageColor.chili);
      expect(dish.stageAlternates, isEmpty);
      expect(
        (dish.crop.centerX, dish.crop.centerY, dish.crop.diameter),
        (0.5, 0.5, 1.0),
      );
    });

    test('没有分类时用 broth', () async {
      final dish = await dishOf(foodJson(category: '盖饭'));
      expect(dish.category, isNull);
      expect(dish.stage, StageColor.broth);
    });

    test('服务端返回舞台色、备选色和取景时照用', () async {
      final dish = await dishOf({
        ...foodJson(stageColor: 'soy', alternates: ['mango', 'bamboo']),
        'coverCrop': {'centerX': 0.3, 'centerY': 0.6, 'diameter': 0.5},
      });
      expect(dish.stage, StageColor.soy);
      expect(dish.stageAlternates, [StageColor.mango, StageColor.bamboo]);
      expect(
        (dish.crop.centerX, dish.crop.centerY, dish.crop.diameter),
        (0.3, 0.6, 0.5),
      );
    });

    test('没有可显示的图时不用取景', () async {
      final dish = await dishOf({
        ...foodJson(),
        'pictureUrls': <String>[],
        'coverCrop': {'centerX': 0.3, 'centerY': 0.6, 'diameter': 0.5},
      });
      expect(
        (dish.crop.centerX, dish.crop.centerY, dish.crop.diameter),
        (0.5, 0.5, 1.0),
      );
    });
  });

  test('按场景和饭点查菜', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/list', [FakeAdapter.ok(pageJson([]))]);
    final container = await env.container();

    await container
        .read(foodRepositoryProvider)
        .list(
          keyword: '云吞',
          scene: RatingScene.delivery,
          mealTime: MealTime.night,
        );

    expect(env.adapter.sent('GET /foods/list').single.query, {
      'keyword': '云吞',
      'scene': 'delivery',
      'mealTime': 'night',
      'page': 1,
      'pageSize': 20,
    });
  });

  test('按店、分类、招牌和菜单顺序查菜，分页带总数', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/list', [
      FakeAdapter.ok(pageJson([foodJson(), foodJson(id: 2)])),
    ]);
    final container = await env.container();

    final page = await container
        .read(foodRepositoryProvider)
        .list(
          restaurantId: 7,
          category: DishCategory.dish,
          signatureOnly: true,
          sort: FoodSort.menu,
        );

    expect(page.total, 2);
    expect(env.adapter.sent('GET /foods/list').single.query, {
      'restaurantId': 7,
      'category': '菜',
      'signatureOnly': true,
      'sort': 'MENU',
      'page': 1,
      'pageSize': 20,
    });
  });

  test('收藏列表不再带排序参数', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/favorites', [FakeAdapter.ok(pageJson([]))]);
    final container = await env.container();

    await container.read(foodRepositoryProvider).favorites();

    expect(env.adapter.sent('GET /foods/favorites').single.query, {
      'page': 1,
      'pageSize': 20,
    });
  });

  test('查重：按店和输入的菜名问服务端，同名标记和封面照用', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/duplicates', [
      FakeAdapter.ok([
        {
          'id': 3,
          'name': 'Coco 奶茶',
          'category': '饮品甜品',
          'price': 12,
          'pictureUrl': 'https://img.test/foods/3.jpg',
          'sameName': true,
        },
        {
          'id': 4,
          'name': 'coco 奶茶大杯',
          'category': '饮品甜品',
          'price': null,
          'pictureUrl': null,
          'sameName': false,
        },
        {'id': 5, 'name': ' ', 'sameName': false},
      ]),
    ]);
    final container = await env.container();

    final found = await container
        .read(foodRepositoryProvider)
        .duplicates(7, ' coco奶茶 ');

    expect(env.adapter.sent('GET /foods/duplicates').single.query, {
      'restaurantId': 7,
      'keyword': 'coco奶茶',
    });
    expect(
      [for (final d in found) (d.id, d.sameName)],
      [(3, true), (4, false)],
    );
    expect(found.first.category, DishCategory.drinkDessert);
    expect(found.first.photo, 'https://img.test/foods/3.jpg');
    expect(found.last.photo, isNull);
  });

  test('查重：菜名只有空白时不请求', () async {
    final env = TestEnv();
    final container = await env.container();

    final found = await container
        .read(foodRepositoryProvider)
        .duplicates(7, '  ');

    expect(found, isEmpty);
    expect(env.adapter.sent('GET /foods/duplicates'), isEmpty);
  });

  group('发布选项', () {
    test('按服务端的顺序和上限，不认识的取值跳过', () async {
      final env = TestEnv();
      env.adapter.on('GET /foods/options', [
        FakeAdapter.ok({
          'categories': ['菜', '主食', '盖饭'],
          'tags': ['清淡', '辣', '咸'],
          'stageColors': ['broth', 'soy'],
          'maxPictures': 9,
          'maxTags': 2,
          'maxSignatures': 4,
          'mealTimes': ['lunch', 'dinner', 'brunch'],
        }),
      ]);
      final container = await env.container();

      final options = await container.read(foodRepositoryProvider).options();

      expect(options.categories, [DishCategory.dish, DishCategory.staple]);
      expect(options.tastes, [Taste.light, Taste.spicy]);
      expect(options.mealTimes, [MealTime.lunch, MealTime.dinner]);
      expect(
        (options.photosMax, options.tagsMax, options.signaturesMax),
        (9, 2, 4),
      );
    });

    test('某一项缺失或无效时用内置值', () async {
      final env = TestEnv();
      env.adapter.on('GET /foods/options', [
        FakeAdapter.ok({
          'categories': ['盖饭'],
          'tags': <String>[],
          'maxPictures': 0,
          'maxTags': null,
        }),
      ]);
      final container = await env.container();

      final options = await container.read(foodRepositoryProvider).options();

      const fallback = DishOptions();
      expect(options.categories, DishCategory.values);
      expect(options.tastes, Taste.values);
      expect(options.mealTimes, MealTime.values);
      expect(
        (options.photosMax, options.tagsMax, options.signaturesMax),
        (fallback.photosMax, fallback.tagsMax, fallback.signaturesMax),
      );
    });
  });

  test('看过的菜品详情断网时从缓存读', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())]);
    final container = await env.container();
    final repo = container.read(foodRepositoryProvider);

    await repo.detail(1);

    final cached = await repo.cachedDetail(1);
    expect(cached?.name, '鲜虾蟹籽云吞');
    expect(cached?.imageKeys, ['foods/1.jpg'], reason: '缓存里带上照片的 key');
    expect(await repo.cachedDetail(2), isNull);
  });
  group('评分', () {
    test('打分发 PUT 带 score，撤销发 DELETE；结果写回缓存的详情', () async {
      final env = TestEnv();
      env.adapter
        ..on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())])
        ..on('PUT /foods/1/rating', [
          FakeAdapter.ok({
            'myRating': 4,
            'rating': {'score': 4.3, 'count': 12},
          }),
        ])
        ..on('DELETE /foods/1/rating', [
          FakeAdapter.ok({
            'myRating': null,
            'rating': {'score': 4.2, 'count': 11},
          }),
        ]);
      final container = await env.container();
      final repo = container.read(foodRepositoryProvider);
      await repo.detail(1);

      final rated = await repo.rate(1, 4);

      expect(env.adapter.sent('PUT /foods/1/rating').single.body, {'score': 4});
      expect(rated.myRating, 4);
      expect(rated.rating.score, 4.3);
      expect(rated.rating.count, 12);
      var cached = await repo.cachedDetail(1);
      expect(cached?.myRating, 4);
      expect(cached?.rating.count, 12);

      final undone = await repo.rate(1, null);

      expect(env.adapter.sent('DELETE /foods/1/rating'), hasLength(1));
      expect(undone.myRating, isNull);
      expect(undone.rating.count, 11);
      cached = await repo.cachedDetail(1);
      expect(cached?.myRating, isNull);
      expect(cached?.rating.score, 4.2);
    });

    test('没看过详情时不写缓存', () async {
      final env = TestEnv();
      env.adapter.on('PUT /foods/1/rating', [
        FakeAdapter.ok({
          'myRating': 5,
          'rating': {'score': 5.0, 'count': 1},
        }),
      ]);
      final container = await env.container();
      final repo = container.read(foodRepositoryProvider);

      await repo.rate(1, 5);

      expect(await repo.cachedDetail(1), isNull);
    });
  });
}
