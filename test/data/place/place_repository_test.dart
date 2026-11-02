import 'package:eat/core/network/idempotency.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const here = GcjPoint(36.6681, 117.1412);

  test('搜店总是带上坐标和校区', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
    final container = await env.container();

    await container
        .read(placeRepositoryProvider)
        .searchShops(keyword: '袁记', near: here, campusId: 2);

    final query = env.adapter.sent('GET /restaurant/search').single.query;
    expect(query, containsPair('gcjLat', here.lat));
    expect(query, containsPair('gcjLng', here.lng));
    expect(query, containsPair('campusId', 2));
  });

  test('搜店带上分类、价位、只看推荐率高的和排序', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
    final container = await env.container();

    await container
        .read(placeRepositoryProvider)
        .searchShops(
          near: here,
          categories: {DishCategory.snack, DishCategory.hotPot},
          priceBand: PriceBand.from15To30,
          recommendedOnly: true,
          favoritesOnly: true,
          sort: ShopSort.recommendation,
        );

    final query = env.adapter.sent('GET /restaurant/search').single.query;
    expect(query['categories'], unorderedEquals(['snack', 'hot_pot']));
    expect(query, containsPair('priceBand', 'FROM_15_TO_30'));
    expect(query, containsPair('recommendedOnly', true));
    expect(query, containsPair('favoritesOnly', true));
    expect(query, containsPair('sort', 'RECOMMENDATION_RATE'));
  });

  test('不筛选时不带筛选参数；没有坐标时不带距离排序', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
    final container = await env.container();
    final repository = container.read(placeRepositoryProvider);

    await repository.searchShops(sort: ShopSort.distance);
    await repository.searchShops(near: here, sort: ShopSort.dishCount);

    final [noPoint, withPoint] = env.adapter
        .sent('GET /restaurant/search')
        .map((r) => r.query)
        .toList();
    expect(noPoint.containsKey('sort'), isFalse);
    expect(noPoint.containsKey('categories'), isFalse);
    expect(noPoint.containsKey('priceBand'), isFalse);
    expect(noPoint.containsKey('recommendedOnly'), isFalse);
    expect(noPoint.containsKey('favoritesOnly'), isFalse);
    expect(withPoint, containsPair('sort', 'FOOD_COUNT'));
  });

  test('没有坐标时照常搜店，不带坐标和半径', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
    final container = await env.container();

    await container
        .read(placeRepositoryProvider)
        .searchShops(keyword: '袁记', radius: 500);

    final query = env.adapter.sent('GET /restaurant/search').single.query;
    expect(query, containsPair('keyword', '袁记'));
    expect(query.containsKey('gcjLat'), isFalse);
    expect(query.containsKey('gcjLng'), isFalse);
    expect(query.containsKey('radius'), isFalse);
  });

  test('店铺的汇总字段解析进店铺，没有汇总时为空', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/browse', [
      FakeAdapter.ok(
        pageJson([
          {
            ...restaurantJson(id: 1),
            'operatingStatus': 'CLOSED',
            'permanentlyClosed': true,
            'visibleFoodCount': 13,
            'priceBand': 'FROM_15_TO_30',
            'ratingCount': 32,
            'recommendationRate': 86,
            'coverUrl': 'https://img.test/foods/1.jpg?sig=a',
            'signatureFoods': [
              {
                'id': 5,
                'name': '鲜虾云吞',
                'price': 18,
                'coverUrl': 'https://img.test/foods/5.jpg',
                'stageColor': 'broth',
                'likesCount': 30,
              },
            ],
            'publicTastes': [
              {'restaurantId': 1, 'tagId': 3, 'name': '皮薄', 'taggerCount': 5},
            ],
          },
          {...restaurantJson(id: 2), 'operatingStatus': 'SYNC_PENDING'},
          restaurantJson(id: 3),
        ]),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(placeRepositoryProvider)
        .browseShops(keyword: '云吞');
    final [full, pending, empty] = page.items;

    expect(full.status, ShopStatus.closed);
    expect(full.dishCount, 13);
    expect(full.priceBand, PriceBand.from15To30);
    expect(full.ratingCount, 32);
    expect(full.recommendRate, 86);
    expect(full.cover, 'https://img.test/foods/1.jpg?sig=a');
    expect(full.signatures.single.name, '鲜虾云吞');
    expect(full.signatures.single.price, 18);
    expect(full.tastes.single.count, 5);
    expect(pending.status, ShopStatus.pending);
    expect(pending.closed, isFalse);
    expect(empty.status, ShopStatus.open);
    expect(empty.dishCount, 0);
    expect(empty.recommendRate, isNull);
    expect(empty.signatures, isEmpty);
    final query = env.adapter.sent('GET /restaurant/browse').single.query;
    expect(query.containsKey('gcjLat'), isFalse);
  });

  test('新建店带 Idempotency-Key；返回 PENDING 时标为审核中', () async {
    final env = TestEnv();
    env.adapter.on('POST /restaurant/add', [
      FakeAdapter.ok({'id': 9, 'moderationStatus': 'PENDING'}),
      FakeAdapter.ok({'id': 10}),
    ]);
    final container = await env.container();
    final repo = container.read(placeRepositoryProvider);

    final pending = await repo.createShop(
      name: '麻辣烫',
      address: '万达金街 1 层',
      point: here,
      idempotencyKey: 'key-1',
    );
    final legacy = await repo.createShop(
      name: '麻辣烫',
      address: '万达金街 1 层',
      point: here,
      idempotencyKey: 'key-2',
    );

    expect(pending, (id: 9, pending: true));
    expect(legacy, (id: 10, pending: false));
    expect(
      env.adapter.sent('POST /restaurant/add').first.headers,
      containsPair('Idempotency-Key', 'key-1'),
    );
  });

  test('Idempotency-Key 是 UUID v4', () {
    final key = newIdempotencyKey();
    expect(
      key,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(newIdempotencyKey(), isNot(key));
  });

  test('店名带空白时，原名和去掉空白的名字各查一次目录，合并后查重', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/browse', [
      FakeAdapter.ok(pageJson([])),
      FakeAdapter.ok(pageJson([restaurantJson(id: 8, name: '麻辣烫')])),
    ]);
    final container = await env.container();

    final shop = await container
        .read(placeRepositoryProvider)
        .sameNameNearby(' 麻辣 烫 ', here, campusId: 2);

    expect(shop?.id, 8);
    final sent = env.adapter.sent('GET /restaurant/browse');
    expect(
      sent.map((r) => r.query['keyword']),
      unorderedEquals(['麻辣 烫', '麻辣烫']),
    );
    expect(sent.first.query, containsPair('campusId', 2));
    expect(sent.first.query, containsPair('radius', 200));
    expect(env.adapter.sent('GET /restaurant/search'), isEmpty);
  });

  test('店名不带空白时只查一次；已关门的同名店也算', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/browse', [
      FakeAdapter.ok(
        pageJson([
          {...restaurantJson(id: 9, name: '麻辣烫'), 'operatingStatus': 'CLOSED'},
        ]),
      ),
    ]);
    final container = await env.container();

    final shop = await container
        .read(placeRepositoryProvider)
        .sameNameNearby('麻辣烫', here);

    expect(shop?.id, 9);
    expect(shop?.closed, isTrue);
    expect(env.adapter.sent('GET /restaurant/browse'), hasLength(1));
  });

  test('名字只是包含关系的店不算同名', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/browse', [
      FakeAdapter.ok(pageJson([restaurantJson(name: '张亮麻辣烫')])),
    ]);
    final container = await env.container();

    final shop = await container
        .read(placeRepositoryProvider)
        .sameNameNearby('麻辣烫', here);

    expect(shop, isNull);
  });

  test('店铺详情带上我的评价、是否收藏和招牌菜的舞台色', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/detail/7', [
      FakeAdapter.ok({
        ...restaurantJson(),
        'personalState': 'READY',
        'myRating': 'GOOD',
        'isFavorite': true,
        'signatureFoods': [
          {'id': 5, 'name': '鲜虾云吞', 'stageColor': 'chili', 'likesCount': 30},
          {'id': 6, 'name': '紫菜汤', 'stageColor': 'unknown'},
        ],
      }),
    ]);
    final container = await env.container();

    final shop = await container.read(placeRepositoryProvider).shop(7);

    expect(shop.myRating, ShopRating.good);
    expect(shop.favorite, isTrue);
    expect(shop.signatures.map((d) => (d.stage, d.likes)), [
      (StageColor.chili, 30),
      (null, 0),
    ]);
  });

  test('游客或个人状态未就绪时没有评价，也不算收藏', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/detail/7', [
      FakeAdapter.ok(restaurantJson()),
    ]);
    final container = await env.container();

    final shop = await container.read(placeRepositoryProvider).shop(7);

    expect(shop.myRating, isNull);
    expect(shop.favorite, isFalse);
  });

  test('评价用 PUT 提交，撤回用 DELETE，返回服务端的当前评价', () async {
    final env = TestEnv();
    env.adapter
      ..on('PUT /restaurant/7/rating', [
        FakeAdapter.ok({'rating': 'NOT_RECOMMEND'}),
      ])
      ..on('DELETE /restaurant/7/rating', [
        FakeAdapter.ok({'rating': null}),
      ]);
    final container = await env.container();
    final repository = container.read(placeRepositoryProvider);

    expect(
      await repository.rateShop(7, ShopRating.notRecommend),
      ShopRating.notRecommend,
    );
    expect(env.adapter.sent('PUT /restaurant/7/rating').single.body, {
      'rating': 'NOT_RECOMMEND',
    });
    expect(await repository.rateShop(7, null), isNull);
    expect(env.adapter.sent('DELETE /restaurant/7/rating'), hasLength(1));
  });

  test('收藏用 PUT，取消用 DELETE；收藏的店分页请求', () async {
    final env = TestEnv();
    env.adapter
      ..on('PUT /restaurant/7/favorite', [FakeAdapter.ok()])
      ..on('DELETE /restaurant/7/favorite', [FakeAdapter.ok()])
      ..on('GET /restaurant/favorites', [
        FakeAdapter.ok(pageJson([restaurantJson()], hasNext: true)),
      ]);
    final container = await env.container();
    final repository = container.read(placeRepositoryProvider);

    await repository.setShopFavorite(7, favorite: true);
    await repository.setShopFavorite(7, favorite: false);
    final page = await repository.favoriteShops(page: 2);

    expect(env.adapter.sent('PUT /restaurant/7/favorite'), hasLength(1));
    expect(env.adapter.sent('DELETE /restaurant/7/favorite'), hasLength(1));
    expect(page.items.single.name, '袁记云饺');
    expect(page.hasNext, isTrue);
    expect(
      env.adapter.sent('GET /restaurant/favorites').single.query,
      containsPair('page', 2),
    );
  });
}
