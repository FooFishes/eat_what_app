import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/recommend/recommend_repository.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/recommend_json.dart';

void main() {
  const here = GcjPoint(36.6681, 117.1412);

  test('请求带上场景、饭点、类型、校区、坐标和页码', () async {
    final env = TestEnv();
    env.adapter.on('GET /recommend', [FakeAdapter.ok(feedJson([]))]);
    final container = await env.container();

    await container
        .read(recommendRepositoryProvider)
        .recommend(
          scene: RatingScene.delivery,
          meal: MealTime.dinner,
          kind: ShopKind.drink,
          campusId: 2,
          near: here,
          page: 3,
          pageSize: 8,
        );

    final query = env.adapter.sent('GET /recommend').single.query;
    expect(query, {
      'scene': 'delivery',
      'mealTime': 'dinner',
      'kind': 'drink',
      'campusId': 2,
      'gcjLat': here.lat,
      'gcjLng': here.lng,
      'page': 3,
      'pageSize': 8,
    });
  });

  test('没有位置时不带坐标', () async {
    final env = TestEnv();
    env.adapter.on('GET /recommend', [FakeAdapter.ok(feedJson([]))]);
    final container = await env.container();

    await container
        .read(recommendRepositoryProvider)
        .recommend(scene: RatingScene.dineIn, meal: MealTime.lunch);

    final query = env.adapter.sent('GET /recommend').single.query;
    expect(query, containsPair('scene', 'dine_in'));
    expect(query, containsPair('kind', 'food'));
    expect(query.containsKey('gcjLat'), isFalse);
    expect(query.containsKey('gcjLng'), isFalse);
  });

  test('卡片按店铺解析：招牌菜、距离、推荐率和商圈；缺坐标的卡片丢弃', () async {
    final env = TestEnv();
    env.adapter.on('GET /recommend', [
      FakeAdapter.ok(
        feedJson([
          cardJson(distance: 321.6),
          cardJson(id: 8, name: '一点点', kind: 'drink', signature: null),
          {...cardJson(id: 9), 'gcjLat': null},
        ], hasNext: true),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(recommendRepositoryProvider)
        .recommend(scene: RatingScene.dineIn, meal: MealTime.lunch);

    expect(page.items.map((s) => s.id), [7, 8]);
    expect(page.hasNext, isTrue);
    expect(page.total, 3);
    final shop = page.items.first;
    expect(shop.name, '袁记云饺');
    expect(shop.distance, 322);
    expect(shop.hubName, '万达金街');
    expect(shop.categories, [ShopCategory.noodles]);
    expect(shop.dineIn.count, 12);
    expect(shop.signatures.single.name, '鲜虾蟹籽云吞');
    expect(shop.signatures.single.price, 18);
    expect(shop.signatures.single.photo, 'https://img.test/foods/1.jpg');
    expect(page.items.last.kind, ShopKind.drink);
    expect(page.items.last.signatures, isEmpty);
  });

  test('拿到的一批存成这个校区、场景、饭点和类型的上一批，断网时还能拿出来', () async {
    final env = TestEnv();
    env.adapter.on('GET /recommend', [
      FakeAdapter.ok(feedJson([cardJson(), cardJson(id: 8)])),
      const FakeResponse.offline(),
    ]);
    final container = await env.container();
    final repo = container.read(recommendRepositoryProvider);

    await repo.recommend(
      scene: RatingScene.delivery,
      meal: MealTime.dinner,
      campusId: 1,
    );
    await expectLater(
      repo.recommend(
        scene: RatingScene.delivery,
        meal: MealTime.dinner,
        campusId: 1,
      ),
      throwsA(isA<AppFailure>()),
    );

    final last = await repo.lastBatch(
      scene: RatingScene.delivery,
      meal: MealTime.dinner,
      campusId: 1,
    );
    expect(last.map((s) => s.id), [7, 8]);
    expect(last.first.signatures.single.name, '鲜虾蟹籽云吞');
    for (final other in [
      repo.lastBatch(
        scene: RatingScene.dineIn,
        meal: MealTime.dinner,
        campusId: 1,
      ),
      repo.lastBatch(
        scene: RatingScene.delivery,
        meal: MealTime.lunch,
        campusId: 1,
      ),
      repo.lastBatch(
        scene: RatingScene.delivery,
        meal: MealTime.dinner,
        kind: ShopKind.drink,
        campusId: 1,
      ),
      repo.lastBatch(
        scene: RatingScene.delivery,
        meal: MealTime.dinner,
        campusId: 2,
      ),
    ]) {
      expect(await other, isEmpty);
    }
  });

  test('空的一批不覆盖上一批', () async {
    final env = TestEnv();
    env.adapter.on('GET /recommend', [
      FakeAdapter.ok(feedJson([cardJson()])),
      FakeAdapter.ok(feedJson([])),
    ]);
    final container = await env.container();
    final repo = container.read(recommendRepositoryProvider);

    await repo.recommend(scene: RatingScene.dineIn, meal: MealTime.lunch);
    await repo.recommend(scene: RatingScene.dineIn, meal: MealTime.lunch);

    final last = await repo.lastBatch(
      scene: RatingScene.dineIn,
      meal: MealTime.lunch,
    );
    expect(last.map((s) => s.id), [7]);
  });

  test('不想去这家：发到这家店的 dismiss 接口', () async {
    final env = TestEnv();
    env.adapter.on('POST /recommend/dismiss/7', [FakeAdapter.ok()]);
    final container = await env.container();

    await container.read(recommendRepositoryProvider).dismiss(7);

    expect(env.adapter.sent('POST /recommend/dismiss/7'), hasLength(1));
  });

  test('不想去这家：每天的次数用完时抛出操作太频繁', () async {
    final env = TestEnv();
    env.adapter.on('POST /recommend/dismiss/7', [
      FakeAdapter.fail(BizCodes.tooFrequent, '操作太频繁'),
    ]);
    final container = await env.container();

    await expectLater(
      container.read(recommendRepositoryProvider).dismiss(7),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.kind,
          'kind',
          FailureKind.tooFrequent,
        ),
      ),
    );
  });
}
