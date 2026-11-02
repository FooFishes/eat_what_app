import 'dart:math';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_dto.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/crop_viewport.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  test('推荐接口返回数组', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/recommend', [
      FakeAdapter.ok([foodJson(recommend: true)]),
    ]);
    final container = await env.container();
    final repo = container.read(foodRepositoryProvider);

    final dishes = await repo.recommend(campusId: 1, meal: MealTime.lunch);

    expect(dishes.single.id, 1);
    final query = env.adapter.sent('GET /foods/recommend').first.query;
    expect(query, containsPair('campusId', 1));
    expect(query, containsPair('mealTime', 'lunch'));
    expect(query, containsPair('size', 8));
  });

  test('推荐请求都带同一个设备标识，换容器后从存储读出', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/recommend', [FakeAdapter.ok(<Object>[])]);
    final container = await env.container();
    final repo = container.read(foodRepositoryProvider);

    await repo.recommend(campusId: 1, meal: MealTime.lunch);
    await repo.recommend(
      campusId: 1,
      meal: MealTime.lunch,
      category: DishCategory.staple,
    );
    final again = await env.container();
    await again
        .read(foodRepositoryProvider)
        .recommend(campusId: 1, meal: MealTime.lunch);

    final ids = env.adapter
        .sent('GET /foods/recommend')
        .map((r) => r.query['deviceId'])
        .toSet();
    expect(ids, hasLength(1));
    expect(ids.single, matches(RegExp(r'^[0-9a-f]{32}$')));
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
            mealTimes: [MealTime.lunch],
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

  group('发布的幂等键和审核状态', () {
    const dish = NewDish(
      shopId: 7,
      name: '云吞',
      imageKeys: ['k'],
      price: 18,
      category: DishCategory.staple,
      mealTimes: [MealTime.lunch],
      stage: StageColor.broth,
      stageAlternates: [],
    );
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('失败后原样重试沿用键，改了内容换键，成功后下一份换键', () async {
      final env = TestEnv();
      env.adapter.on('POST /foods/upload', [
        const FakeResponse.offline(),
        const FakeResponse.offline(),
        FakeAdapter.ok({'id': 9}),
        FakeAdapter.ok({'id': 10}),
      ]);
      final container = await env.container();
      final repo = container.read(foodRepositoryProvider);
      const changed = NewDish(
        shopId: 7,
        name: '鲜虾云吞',
        imageKeys: ['k'],
        price: 18,
        category: DishCategory.staple,
        mealTimes: [MealTime.lunch],
        stage: StageColor.broth,
        stageAlternates: [],
      );

      await expectLater(repo.publish(dish), throwsA(isA<AppFailure>()));
      await expectLater(repo.publish(dish), throwsA(isA<AppFailure>()));
      await repo.publish(changed);
      await repo.publish(changed);

      final keys = [
        for (final r in env.adapter.sent('POST /foods/upload'))
          r.headers['Idempotency-Key'] as String,
      ];
      expect(keys, everyElement(matches(uuid)));
      expect(keys[1], keys[0], reason: '原样重试');
      expect(keys[2], isNot(keys[1]), reason: '内容变了');
      expect(keys[3], isNot(keys[2]), reason: '上一次已成功');
    });

    test('返回 PENDING 时进入审核，不返回审核状态时按已公开', () async {
      final env = TestEnv();
      env.adapter.on('POST /foods/upload', [
        FakeAdapter.ok({'id': 9, 'moderationStatus': 'PENDING'}),
        FakeAdapter.ok({'id': 10}),
      ]);
      final container = await env.container();
      final repo = container.read(foodRepositoryProvider);

      final pending = await repo.publish(dish);
      final public = await repo.publish(dish);

      expect((pending.id, pending.pending), (9, true));
      expect((public.id, public.pending), (10, false));
    });
  });

  group('封面被滤掉时不用裁切', () {
    Future<CoverCrop> cropOf(Map<String, Object?> json) async {
      final container = await TestEnv().container();
      return container
          .read(foodRepositoryProvider)
          .toDish(FoodDto.fromJson(json))
          .crop;
    }

    const custom = {'centerX': 0.3, 'centerY': 0.6, 'diameter': 0.5};

    test('pictureKeys 与 pictureUrl 张数相同，沿用裁切', () async {
      final crop = await cropOf({
        ...foodJson(),
        'pictureUrl': ['https://img.test/a.jpg', 'https://img.test/b.jpg'],
        'pictureKeys': ['foods/a.jpg', 'foods/b.jpg'],
        'coverCrop': custom,
      });
      expect((crop.centerX, crop.centerY, crop.diameter), (0.3, 0.6, 0.5));
    });

    test('张数不同时第一张不能确认是封面，按居中内切圆显示', () async {
      final crop = await cropOf({
        ...foodJson(),
        'pictureUrl': ['https://img.test/b.jpg'],
        'pictureKeys': ['foods/a.jpg', 'foods/b.jpg'],
        'coverCrop': custom,
      });
      expect((crop.centerX, crop.centerY, crop.diameter), (0.5, 0.5, 1.0));
    });

    test('没有可显示的图时不用裁切', () async {
      final crop = await cropOf({
        ...foodJson(),
        'pictureUrl': <String>[],
        'pictureKeys': <String>[],
        'coverCrop': custom,
      });
      expect((crop.centerX, crop.centerY, crop.diameter), (0.5, 0.5, 1.0));
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

  test('DTO 转成菜：舞台色、备选色、饭点、店的坐标和图片地址', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/detail/1', [
      FakeAdapter.ok(foodJson(stageColor: 'soy', recommend: true)),
    ]);
    final container = await env.container();

    final dish = await container.read(foodRepositoryProvider).detail(1);

    expect(dish.stage, StageColor.soy);
    expect(dish.stageAlternates, [StageColor.mango, StageColor.bamboo]);
    expect(dish.mealTimes, [MealTime.lunch, MealTime.dinner]);
    expect(dish.category, DishCategory.staple);
    expect(dish.shopPoint, const GcjPoint(36.6681, 117.1412));
    expect(dish.cover, 'https://img.test/foods/1.jpg');
    expect(dish.price, 18);
  });

  test('带坐标按距离搜菜，距离解析进菜；没有坐标时不带距离排序', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/list', [
      FakeAdapter.ok(
        pageJson([
          {...foodJson(), 'distanceMeters': 321.4},
        ]),
      ),
      FakeAdapter.ok(pageJson([foodJson()])),
    ]);
    final container = await env.container();
    final repository = container.read(foodRepositoryProvider);
    const here = GcjPoint(36.6681, 117.1412);

    final near = await repository.list(
      keyword: '云吞',
      near: here,
      sort: FoodSort.distance,
    );
    final far = await repository.list(keyword: '云吞', sort: FoodSort.distance);

    final [withPoint, noPoint] = env.adapter
        .sent('GET /foods/list')
        .map((r) => r.query)
        .toList();
    expect(withPoint, containsPair('gcjLat', here.lat));
    expect(withPoint, containsPair('gcjLng', here.lng));
    expect(withPoint, containsPair('sort', 'DISTANCE'));
    expect(near.items.single.distance, 321.4);
    expect(noPoint.containsKey('gcjLat'), isFalse);
    expect(noPoint.containsKey('sort'), isFalse);
    expect(far.items.single.distance, isNull);
  });

  test('没存舞台色时用分类的默认色', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/detail/1', [
      FakeAdapter.ok(foodJson(stageColor: null, category: 'hot_pot')),
    ]);
    final container = await env.container();

    final dish = await container.read(foodRepositoryProvider).detail(1);

    expect(dish.stage, StageColor.redoil);
  });

  test('推荐拿到后存成这个校区和饭点的上一批，断网时还能拿出来', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/recommend', [
      FakeAdapter.ok([foodJson(), foodJson(id: 2)]),
      const FakeResponse.offline(),
    ]);
    final container = await env.container();
    final repo = container.read(foodRepositoryProvider);

    await repo.recommend(campusId: 1, meal: MealTime.dinner);
    await expectLater(
      repo.recommend(campusId: 1, meal: MealTime.dinner),
      throwsA(isA<AppFailure>()),
    );

    final last = await repo.lastBatch(campusId: 1, meal: MealTime.dinner);
    expect(last.map((d) => d.id), [1, 2]);
    expect(await repo.lastBatch(campusId: 1, meal: MealTime.lunch), isEmpty);
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
