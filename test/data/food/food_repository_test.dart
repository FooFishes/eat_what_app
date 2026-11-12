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
    });
    expect(request.headers.containsKey('Idempotency-Key'), isFalse);
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
    test('只发出改动的字段；空说明、空照片和空口味表示清除；返回修改记录 id', () async {
      final env = TestEnv();
      env.adapter.on('PUT /foods/edit/1', [
        FakeAdapter.ok({'id': 1, 'revisionId': 31}),
      ]);
      final container = await env.container();

      final revision = await container
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

      expect(revision, 31);
      expect(env.adapter.sent('PUT /foods/edit/1').single.body, {
        'price': 16.0,
        'description': '',
        'pictures': <String>[],
        'tags': <String>[],
        'signature': false,
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

    test('内容没有变化时返回 null', () async {
      final env = TestEnv();
      env.adapter.on('PUT /foods/edit/1', [
        FakeAdapter.ok({'id': 1, 'revisionId': null}),
      ]);
      final container = await env.container();

      final revision = await container
          .read(foodRepositoryProvider)
          .edit(1, const DishChange(name: '鲜虾蟹籽云吞'));

      expect(revision, isNull);
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
    expect(restored.fields, [DishField.price, DishField.pictures]);
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

  test('同名判断忽略空白和大小写', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/list', [
      FakeAdapter.ok(pageJson([foodJson(id: 3, name: 'Coco 奶茶')])),
    ]);
    final container = await env.container();

    final same = await container
        .read(foodRepositoryProvider)
        .sameName(7, 'coco奶茶');

    expect(same?.id, 3);
  });

  test('看过的菜品详情断网时从缓存读', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/detail/1', [FakeAdapter.ok(foodJson())]);
    final container = await env.container();
    final repo = container.read(foodRepositoryProvider);

    await repo.detail(1);

    expect((await repo.cachedDetail(1))?.name, '鲜虾蟹籽云吞');
    expect(await repo.cachedDetail(2), isNull);
  });
}
