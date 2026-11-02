import 'package:eat/data/topic/topic_repository.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/topic_json.dart';

void main() {
  test('当期专题按校区请求；没有当期专题时为 null', () async {
    final env = TestEnv();
    env.adapter.on('GET /topics/current', [
      FakeAdapter.ok(topicJson()),
      FakeAdapter.ok(),
    ]);
    final container = await env.container();
    final repository = container.read(topicRepositoryProvider);

    final topic = await repository.current(2);
    expect(topic?.id, 7);
    expect(topic?.name, '期末续命餐');
    expect(topic?.dishCount, 2);
    expect(
      env.adapter.sent('GET /topics/current').single.query,
      containsPair('campusId', 2),
    );
    expect(await repository.current(2), isNull);
  });

  test('专题详情按位置排菜，菜带上取景、舞台色和店名', () async {
    final env = TestEnv();
    env.adapter.on('GET /topics/7', [
      FakeAdapter.ok(
        topicDetailJson(
          foods: [
            topicFoodJson(id: 2, name: '铁锅炖大鹅', position: 1),
            topicFoodJson(),
          ],
        ),
      ),
    ]);
    final container = await env.container();

    final detail = await container.read(topicRepositoryProvider).detail(7);
    final dishes = detail!.dishes;
    expect(dishes.map((d) => d.name), ['柳州螺蛳粉', '铁锅炖大鹅']);
    final first = dishes.first;
    expect(first.shopName, '螺蛳粉研究所');
    expect(first.cover, 'https://img.test/foods/1.jpg');
    expect(first.stage, StageColor.chili);
    expect(first.category, DishCategory.staple);
    expect(first.crop.centerX, 0.4);
    expect(first.crop.diameter, 0.8);
    expect(first.price, 16.5);
  });

  test('往期专题分页；缺少时间的专题丢弃', () async {
    final env = TestEnv();
    env.adapter.on('GET /topics/history', [
      FakeAdapter.ok(
        pageJson([
          topicJson(id: 3, name: '降温了喝碗汤'),
          {...topicJson(id: 4), 'endsAt': null},
        ], hasNext: true),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(topicRepositoryProvider)
        .history(1, page: 2);
    expect(page.items.map((t) => t.id), [3]);
    expect(page.hasNext, isTrue);
    final query = env.adapter.sent('GET /topics/history').single.query;
    expect(query, containsPair('campusId', 1));
    expect(query, containsPair('page', 2));
  });

  test('收录过这道菜的专题最近开始的在前', () async {
    final env = TestEnv();
    final now = DateTime.now();
    env.adapter.on('GET /topics/by-food/1', [
      FakeAdapter.ok([
        topicJson(
          id: 3,
          name: '降温了喝碗汤',
          startsAt: now.subtract(const Duration(days: 30)),
          endsAt: now.subtract(const Duration(days: 23)),
        ),
        topicJson(),
      ]),
    ]);
    final container = await env.container();

    final topics = await container.read(topicRepositoryProvider).byDish(1);
    expect(topics.map((t) => t.id), [7, 3]);
  });
}
