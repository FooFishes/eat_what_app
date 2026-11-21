import 'package:eat/features/nearby/nearby_providers.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  test('最近选的在前，去重，最多 4 个，按账号存在本地', () async {
    final env = TestEnv();
    final container = await env.container(
      session: const SignedIn(user: verifiedUser),
    );
    addTearDown(container.dispose);
    expect(await container.read(recentHubsProvider.future), isEmpty);

    final notifier = container.read(recentHubsProvider.notifier);
    for (final id in [1, 2, 3, 4, 5, 2]) {
      await notifier.add(id);
    }
    expect(container.read(recentHubsProvider).value, [2, 5, 4, 3]);
    expect(env.kv.values['cache.nearby.hubs.42'], '[2,5,4,3]');

    final again = await env.container(
      session: const SignedIn(user: verifiedUser),
    );
    addTearDown(again.dispose);
    expect(await again.read(recentHubsProvider.future), [2, 5, 4, 3]);
  });

  test('游客只在内存里记，不写本地', () async {
    final env = TestEnv();
    final container = await env.container(session: const Guest());
    addTearDown(container.dispose);
    await container.read(recentHubsProvider.future);

    await container.read(recentHubsProvider.notifier).add(1);
    expect(container.read(recentHubsProvider).value, [1]);
    expect(env.kv.values.keys.where((k) => k.contains('hubs')), isEmpty);
  });
}
