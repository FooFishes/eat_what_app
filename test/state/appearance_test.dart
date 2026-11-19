import 'package:eat/state/appearance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  /// 创建容器, 等本机保存的值读出.
  Future<ProviderContainer> start(TestEnv env) async {
    final container = await env.container();
    addTearDown(container.dispose);
    container.listen(navGlassTransparencyProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  late TestEnv env;

  setUp(() => env = TestEnv());

  test('没调过时用默认透明度', () async {
    final container = await start(env);

    expect(
      container.read(navGlassTransparencyProvider),
      NavGlassTransparency.fallback,
    );
  });

  test('调过的透明度记在本机，下次打开还是这个值', () async {
    final container = await start(env);

    container.read(navGlassTransparencyProvider.notifier).set(0.9);
    await container.read(navGlassTransparencyProvider.notifier).save();

    expect(env.kv.values[NavGlassTransparency.key], '0.9');
    final again = await start(env);
    expect(again.read(navGlassTransparencyProvider), 0.9);
  });

  test('超出范围的值收回到上下限', () async {
    env.kv.values[NavGlassTransparency.key] = '1.5';
    final container = await start(env);
    expect(
      container.read(navGlassTransparencyProvider),
      NavGlassTransparency.max,
    );

    container.read(navGlassTransparencyProvider.notifier).set(0);
    expect(
      container.read(navGlassTransparencyProvider),
      NavGlassTransparency.min,
    );
  });

  test('本机的值读出之前调过，以调的为准', () async {
    env.kv.values[NavGlassTransparency.key] = '0.3';
    final container = await env.container();
    addTearDown(container.dispose);
    container.listen(navGlassTransparencyProvider, (_, _) {});

    container.read(navGlassTransparencyProvider.notifier).set(0.7);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(navGlassTransparencyProvider), 0.7);
  });

  group('AppearancePreference', () {
    test('没选过时跟随系统', () async {
      final container = await env.container();
      addTearDown(container.dispose);
      await container.read(appearancePreferenceProvider.notifier).restore();

      expect(container.read(appearancePreferenceProvider), Appearance.system);
    });

    test('选过的深浅色记在本机，下次启动读出来；认不出的值按跟随系统', () async {
      final container = await env.container();
      addTearDown(container.dispose);
      await container
          .read(appearancePreferenceProvider.notifier)
          .select(Appearance.dark);
      expect(env.kv.values[AppearancePreference.key], 'dark');

      final again = await env.container();
      addTearDown(again.dispose);
      await again.read(appearancePreferenceProvider.notifier).restore();
      expect(again.read(appearancePreferenceProvider), Appearance.dark);

      env.kv.values[AppearancePreference.key] = 'sepia';
      final third = await env.container();
      addTearDown(third.dispose);
      await third.read(appearancePreferenceProvider.notifier).restore();
      expect(third.read(appearancePreferenceProvider), Appearance.system);
    });
  });
}
