import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/state/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  /// 创建容器, 等本机选择读出, 校区列表加载完.
  Future<ProviderContainer> start(TestEnv env) async {
    final container = await env.container();
    addTearDown(container.dispose);
    container.listen(currentPlaceProvider, (_, _) {});
    await container.read(campusesProvider.future);
    for (
      var i = 0;
      i < 10 && !container.read(currentPlaceProvider).ready;
      i++
    ) {
      await Future<void>.delayed(Duration.zero);
    }
    return container;
  }

  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.adapter.on('GET /campus/list', [FakeAdapter.ok(campusListJson)]);
  });

  test('没选过时按去店里吃', () async {
    final place = (await start(env)).read(currentPlaceProvider);

    expect(place.ready, isTrue);
    expect(place.scene, RatingScene.dineIn);
  });

  test('选了点外卖后记在本机，下次打开还是点外卖', () async {
    final container = await start(env);

    await container
        .read(placeAndMealProvider.notifier)
        .selectScene(RatingScene.delivery);

    expect(container.read(currentPlaceProvider).scene, RatingScene.delivery);
    expect(env.kv.values['prefs.scene'], 'delivery');
    final again = await start(env);
    expect(again.read(currentPlaceProvider).scene, RatingScene.delivery);
  });

  test('换校区、换饭点和恢复自动饭点都不改场景', () async {
    env.kv.values['prefs.scene'] = 'delivery';
    final container = await start(env);
    final notifier = container.read(placeAndMealProvider.notifier);

    await notifier.selectCampus(1);
    await notifier.selectMeal(MealTime.night);
    expect(container.read(currentPlaceProvider).scene, RatingScene.delivery);
    await notifier.autoMeal();
    expect(container.read(currentPlaceProvider).scene, RatingScene.delivery);
  });

  test('本机存的值认不出时按去店里吃', () async {
    env.kv.values['prefs.scene'] = 'takeaway';

    final place = (await start(env)).read(currentPlaceProvider);

    expect(place.scene, RatingScene.dineIn);
  });
}
