import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/dish_revision.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/taste.dart';
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

  test('搜店带上类型、品类、口味、价位、外卖、口碑好、收藏和排序', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
    final container = await env.container();

    await container
        .read(placeRepositoryProvider)
        .searchShops(
          near: here,
          kind: ShopKind.drink,
          categories: {ShopCategory.noodles, ShopCategory.hotPot},
          tastes: {Taste.spicy},
          priceBand: PriceBand.from15To30,
          delivery: true,
          recommendedOnly: true,
          favoritesOnly: true,
          sort: ShopSort.newest,
        );

    final query = env.adapter.sent('GET /restaurant/search').single.query;
    expect(query, containsPair('kind', 'drink'));
    expect(query['categories'], unorderedEquals(['粉面', '火锅麻辣烫']));
    expect(query, containsPair('tags', ['辣']));
    expect(query, containsPair('priceBand', 'FROM_15_TO_30'));
    expect(query, containsPair('delivery', true));
    expect(query, containsPair('recommendedOnly', true));
    expect(query, containsPair('favoritesOnly', true));
    expect(query, containsPair('sort', 'NEWEST'));
  });

  test('不筛选时不带筛选参数；没有坐标时不带距离排序和半径', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [FakeAdapter.ok(pageJson([]))]);
    final container = await env.container();

    await container
        .read(placeRepositoryProvider)
        .searchShops(radius: 500, sort: ShopSort.distance);

    final query = env.adapter.sent('GET /restaurant/search').single.query;
    for (final key in [
      'sort',
      'gcjLat',
      'radius',
      'kind',
      'categories',
      'tags',
      'priceBand',
      'delivery',
      'recommendedOnly',
      'favoritesOnly',
    ]) {
      expect(query.containsKey(key), isFalse, reason: key);
    }
  });

  test('店铺的字段解析进店铺；不认识的品类和口味忽略', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [
      FakeAdapter.ok(
        pageJson([
          {
            ...restaurantJson(id: 1, poi: 'baidu-1'),
            'pictureUrl': 'https://img.test/restaurants/1.jpg',
            'permanentlyClosed': true,
            'kind': 'drink',
            'mealTimes': ['breakfast', 'night'],
            'priceBand': 'FROM_15_TO_30',
            'categories': ['粉面', '新品类'],
            'tags': ['辣', '酸', '咸'],
            'deliveryEnabled': true,
            'dineIn': {'rate': 0.856, 'count': 32},
            'delivery': {'rate': null, 'count': 0},
            'isFavorite': true,
            'myRatings': {'dineIn': 'RECOMMEND', 'delivery': null},
          },
          {...restaurantJson(id: 2), 'kind': 'unknown', 'hubName': ''},
        ]),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(placeRepositoryProvider)
        .searchShops(keyword: '云吞');
    final [full, plain] = page.items;

    expect(full.poi, 'baidu-1');
    expect(full.photo, 'https://img.test/restaurants/1.jpg');
    expect(full.closed, isTrue);
    expect(full.hubName, '万达金街');
    expect(full.campusId, 1);
    expect(full.kind, ShopKind.drink);
    expect(full.mealTimes, [MealTime.breakfast, MealTime.night]);
    expect(full.priceBand, PriceBand.from15To30);
    expect(full.categories, [ShopCategory.noodles]);
    expect(full.tastes, [Taste.spicy, Taste.sour]);
    expect(full.deliveryEnabled, isTrue);
    expect((full.dineIn.rate, full.dineIn.count), (0.856, 32));
    expect((full.delivery.rate, full.delivery.count), (null, 0));
    expect(full.favorite, isTrue);
    expect(full.myRatings, const MyShopRatings(dineIn: ShopRating.recommend));
    expect(plain.kind, ShopKind.food, reason: '不认识的类型按美食处理');
    expect(plain.hubName, isNull);
    expect(plain.photo, isNull);
    expect(plain.favorite, isNull, reason: '游客没有收藏状态');
    expect(plain.myRatings, isNull);
    expect(page.total, 2);
  });

  test('推荐卡片的 JSON 也能转成店铺，带招牌菜和距离', () {
    final shop = PlaceRepository.shopFromJson({
      'id': 7,
      'name': '袁记云饺',
      'address': '万达金街 1 层',
      'gcjLng': 117.1412,
      'gcjLat': 36.6681,
      'kind': 'food',
      'distanceMeters': 321.6,
      'signatureFoods': [
        {
          'id': 5,
          'name': '鲜虾云吞',
          'price': 18,
          'pictureUrl': 'https://img.test/foods/5.jpg',
        },
        {'id': 6, 'name': '紫菜汤', 'price': null, 'pictureUrl': null},
      ],
    });

    expect(shop?.distance, 322);
    expect(shop?.signatures.map((d) => (d.name, d.price, d.photo)), [
      ('鲜虾云吞', 18, 'https://img.test/foods/5.jpg'),
      ('紫菜汤', null, null),
    ]);
  });

  test('商圈边界原样按 GCJ-02 解析，只取外环', () async {
    final env = TestEnv();
    env.adapter.on('GET /hub/list', [
      FakeAdapter.ok(
        pageJson([
          {
            'id': 3,
            'name': '万达金街',
            'gcjLng': 117.14,
            'gcjLat': 36.66,
            'boundary': {
              'type': 'MultiPolygon',
              'coordinates': [
                [
                  [
                    [117.1, 36.6],
                    [117.2, 36.6],
                    [117.2, 36.7],
                    [117.1, 36.6],
                  ],
                  [
                    [117.15, 36.65],
                    [117.16, 36.65],
                    [117.15, 36.65],
                  ],
                ],
              ],
            },
          },
          {'id': 4, 'name': '食堂', 'gcjLng': 117.13, 'gcjLat': 36.65},
        ]),
      ),
    ]);
    final container = await env.container();

    final [mall, canteen] = await container
        .read(placeRepositoryProvider)
        .hubs();

    expect(mall.boundary, [
      const [
        GcjPoint(36.6, 117.1),
        GcjPoint(36.6, 117.2),
        GcjPoint(36.7, 117.2),
        GcjPoint(36.6, 117.1),
      ],
    ]);
    expect(canteen.boundary, isEmpty);
  });

  test('新建店用 poi 键提交，带类型和选填项，不带幂等键，返回店铺 id', () async {
    final env = TestEnv();
    env.adapter.on('POST /restaurant/add', [
      FakeAdapter.ok({'id': 9}),
    ]);
    final container = await env.container();

    final id = await container
        .read(placeRepositoryProvider)
        .createShop(
          name: '麻辣烫',
          address: '万达金街 1 层',
          point: here,
          kind: ShopKind.food,
          poi: 'baidu-1',
          photoKey: 'restaurants/1.jpg',
          mealTimes: [MealTime.lunch],
          categories: [ShopCategory.hotPot],
          tastes: [Taste.spicy, Taste.numbing],
          deliveryEnabled: true,
        );

    expect(id, 9);
    final sent = env.adapter.sent('POST /restaurant/add').single;
    expect(sent.body, {
      'name': '麻辣烫',
      'address': '万达金街 1 层',
      'gcjLng': here.lng,
      'gcjLat': here.lat,
      'poi': 'baidu-1',
      'picture': 'restaurants/1.jpg',
      'kind': 'food',
      'mealTimes': ['lunch'],
      'categories': ['火锅麻辣烫'],
      'tags': ['辣', '麻'],
      'deliveryEnabled': true,
    });
    expect(sent.headers.containsKey('Idempotency-Key'), isFalse);
  });

  test('修改店铺只提交改动；清除门头照片和价位传空串，清除品类传空数组', () async {
    final env = TestEnv();
    env.adapter.on('PUT /restaurant/edit/7', [
      FakeAdapter.ok({'id': 7, 'revisionId': 30}),
      FakeAdapter.ok({'id': 7, 'revisionId': null}),
    ]);
    final container = await env.container();
    final repository = container.read(placeRepositoryProvider);

    final changed = await repository.editShop(
      7,
      const ShopChange(
        name: '袁记云饺（万达店）',
        photo: (key: null),
        priceBand: (band: null),
        categories: [],
        closed: true,
      ),
    );
    final unchanged = await repository.editShop(
      7,
      const ShopChange(photo: (key: 'restaurants/2.jpg')),
    );

    expect((changed, unchanged), (true, false));
    final [first, second] = env.adapter
        .sent('PUT /restaurant/edit/7')
        .map((r) => r.body)
        .toList();
    expect(first, {
      'name': '袁记云饺（万达店）',
      'picture': '',
      'permanentlyClosed': true,
      'priceBand': '',
      'categories': <String>[],
    });
    expect(second, {'picture': 'restaurants/2.jpg'});
  });

  test('修改记录：字段名转成枚举，经纬度合并为位置，不认识的字段忽略', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/7/history', [
      FakeAdapter.ok(
        pageJson([
          {
            'id': 31,
            'action': 'restore',
            'editor': {'id': 9, 'displayName': '小林', 'avatar': ''},
            'restoredFrom': 29,
            'changes': [
              {'field': 'gcjLng', 'from': 117.1, 'to': 117.2},
              {'field': 'gcjLat', 'from': 36.6, 'to': 36.7},
              {'field': 'picture', 'from': null, 'to': 'https://img.test/a'},
              {'field': 'unknown', 'from': 1, 'to': 2},
            ],
            'createdAt': 1792763739329,
          },
          {
            'id': 29,
            'action': 'create',
            'editor': null,
            'changes': <Object>[],
            'createdAt': 1792763739000,
          },
        ], hasNext: true),
      ),
    ]);
    final container = await env.container();

    final page = await container
        .read(placeRepositoryProvider)
        .history(7, page: 2);
    final [restore, create] = page.items;

    expect(restore.action, RevisionAction.restore);
    expect(restore.restoredFrom, 29);
    expect(restore.editorName, '小林');
    expect(restore.editorAvatar, isNull);
    expect(restore.fields, [ShopField.location, ShopField.picture]);
    expect(create.action, RevisionAction.create);
    expect(create.editorName, isNull);
    expect(page.hasNext, isTrue);
    expect(
      env.adapter.sent('GET /restaurant/7/history').single.query,
      containsPair('page', 2),
    );
  });

  test('恢复用 POST 到对应的修改记录', () async {
    final env = TestEnv();
    env.adapter.on('POST /restaurant/7/history/29/restore', [
      FakeAdapter.ok({'id': 7, 'revisionId': 32}),
    ]);
    final container = await env.container();

    await container.read(placeRepositoryProvider).restore(7, 29);

    expect(
      env.adapter.sent('POST /restaurant/7/history/29/restore'),
      hasLength(1),
    );
  });

  test('店名带空白时，原名和去掉空白的名字各搜一次，合并后在 100 m 内查重', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [
      FakeAdapter.ok(pageJson([])),
      FakeAdapter.ok(pageJson([restaurantJson(id: 8, name: '麻辣烫')])),
    ]);
    final container = await env.container();

    final shop = await container
        .read(placeRepositoryProvider)
        .sameNameNearby(' 麻辣 烫 ', here, campusId: 2);

    expect(shop?.id, 8);
    final sent = env.adapter.sent('GET /restaurant/search');
    expect(
      sent.map((r) => r.query['keyword']),
      unorderedEquals(['麻辣 烫', '麻辣烫']),
    );
    expect(sent.first.query, containsPair('campusId', 2));
    expect(sent.first.query, containsPair('radius', 100));
  });

  test('店名不带空白时只查一次；已关门的同名店也算', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [
      FakeAdapter.ok(
        pageJson([
          {...restaurantJson(id: 9, name: '麻辣烫'), 'permanentlyClosed': true},
        ]),
      ),
    ]);
    final container = await env.container();

    final shop = await container
        .read(placeRepositoryProvider)
        .sameNameNearby('麻辣烫', here);

    expect(shop?.id, 9);
    expect(shop?.closed, isTrue);
    expect(env.adapter.sent('GET /restaurant/search'), hasLength(1));
  });

  test('名字只是包含关系的店不算同名', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [
      FakeAdapter.ok(pageJson([restaurantJson(name: '张亮麻辣烫')])),
    ]);
    final container = await env.container();

    final shop = await container
        .read(placeRepositoryProvider)
        .sameNameNearby('麻辣烫', here);

    expect(shop, isNull);
  });

  test('按 poi 找这个地点已有的店', () async {
    final env = TestEnv();
    env.adapter.on('GET /restaurant/search', [
      FakeAdapter.ok(
        pageJson([
          restaurantJson(id: 1, poi: 'baidu-2'),
          restaurantJson(id: 2, poi: 'baidu-1'),
        ]),
      ),
    ]);
    final container = await env.container();

    final shop = await container
        .read(placeRepositoryProvider)
        .shopAtPoi('baidu-1', here);

    expect(shop?.id, 2);
  });

  test('评价用 PUT 提交场景和评价，撤回用 DELETE 带场景，返回两个场景的评价', () async {
    final env = TestEnv();
    env.adapter
      ..on('PUT /restaurant/7/rating', [
        FakeAdapter.ok({'dineIn': 'RECOMMEND', 'delivery': 'NOT_RECOMMEND'}),
      ])
      ..on('DELETE /restaurant/7/rating', [
        FakeAdapter.ok({'dineIn': 'RECOMMEND', 'delivery': null}),
      ]);
    final container = await env.container();
    final repository = container.read(placeRepositoryProvider);

    expect(
      await repository.rateShop(
        7,
        RatingScene.delivery,
        ShopRating.notRecommend,
      ),
      const MyShopRatings(
        dineIn: ShopRating.recommend,
        delivery: ShopRating.notRecommend,
      ),
    );
    expect(env.adapter.sent('PUT /restaurant/7/rating').single.body, {
      'scene': 'delivery',
      'rating': 'NOT_RECOMMEND',
    });
    expect(
      await repository.rateShop(7, RatingScene.delivery, null),
      const MyShopRatings(dineIn: ShopRating.recommend),
    );
    expect(env.adapter.sent('DELETE /restaurant/7/rating').single.query, {
      'scene': 'delivery',
    });
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
