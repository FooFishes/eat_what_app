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
}
