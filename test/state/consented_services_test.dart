import 'package:clock/clock.dart';
import 'package:eat/core/platform/hot_update.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.updater
      ..isAvailable = true
      ..status = UpdateStatus.outdated;
  });

  test('本机没同意过隐私政策时不启动，也不检查热更新', () async {
    final container = await env.container();

    await container.read(consentedServicesProvider.notifier).start();

    expect(container.read(consentedServicesProvider), isFalse);
    expect(env.updater.checks, 0);
  });

  test('同意过就启动并检查热更新；重复调用只启动一次', () async {
    env.kv.values[PrivacyConsentStore.key] = '{"version":"2026-10"}';
    final container = await env.container();
    final services = container.read(consentedServicesProvider.notifier);

    await services.start();
    await services.start();
    await pumpEventQueue();

    expect(container.read(consentedServicesProvider), isTrue);
    expect(env.updater.checks, 1);
    expect(env.updater.updates, 1);
  });

  test('启动后回到前台时按间隔再检查热更新', () async {
    env.kv.values[PrivacyConsentStore.key] = '{"version":"2026-10"}';
    final container = await env.container();
    final binding = TestWidgetsFlutterBinding.instance;
    final start = DateTime(2026, 11, 21, 12);

    await withClock(
      Clock.fixed(start),
      container.read(consentedServicesProvider.notifier).start,
    );
    await pumpEventQueue();
    expect(env.updater.checks, 1);

    void backAndForth() {
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        binding.handleAppLifecycleStateChanged(state);
      }
    }

    withClock(Clock.fixed(start.add(const Duration(minutes: 5))), backAndForth);
    await pumpEventQueue();
    expect(env.updater.checks, 1);

    withClock(
      Clock.fixed(start.add(HotUpdate.staleAfter + const Duration(minutes: 1))),
      backAndForth,
    );
    await pumpEventQueue();
    expect(env.updater.checks, 2);
  });
}
