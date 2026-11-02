import 'package:eat/features/publish/publish_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter.on('GET /restaurant/search', [
      FakeAdapter.ok(pageJson([restaurantJson()])),
    ]);
  });

  test('没有定位时等校区加载出来，按校区中心搜附近的店', () async {
    env.adapter.on('GET /campus/list', [FakeAdapter.ok(campusListJson)]);
    final container = await env.container();
    final provider = pickableShopsProvider('');
    container.listen(provider, (_, _) {});

    final shops = await container.read(provider.future);

    expect(shops.single.id, 7);
    final query = env.adapter.sent('GET /restaurant/search').single.query;
    expect(query, containsPair('gcjLat', 36.667382));
    expect(query, containsPair('gcjLng', 117.140109));
    expect(query, containsPair('campusId', 1));
  });

  test('定位和校区都拿不到时照常搜店，不带坐标', () async {
    env.adapter.on('GET /campus/list', [const FakeResponse.offline()]);
    final container = await env.container();
    final provider = pickableShopsProvider('袁记');
    container.listen(provider, (_, _) {});

    final shops = await container.read(provider.future);

    expect(shops.single.id, 7);
    final query = env.adapter.sent('GET /restaurant/search').single.query;
    expect(query, containsPair('keyword', '袁记'));
    expect(query.containsKey('gcjLat'), isFalse);
    expect(query.containsKey('gcjLng'), isFalse);
  });
}
