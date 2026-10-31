import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  test('推荐接口实际返回数组，也按文档的分页外壳解析', () async {
    final env = TestEnv();
    env.adapter.on('GET /foods/recommend', [
      FakeAdapter.ok([foodJson(recommend: true)]),
      FakeAdapter.ok(pageJson([foodJson(id: 2, recommend: true)])),
    ]);
    final container = await env.container();
    final repo = container.read(foodRepositoryProvider);

    final first = await repo.recommend(campusId: 1, meal: MealTime.lunch);
    final second = await repo.recommend(campusId: 1, meal: MealTime.lunch);

    expect(first.single.id, 1);
    expect(second.single.id, 2);
    final query = env.adapter.sent('GET /foods/recommend').first.query;
    expect(query, containsPair('campusId', 1));
    expect(query, containsPair('mealTime', 'lunch'));
    expect(query, containsPair('size', 8));
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
