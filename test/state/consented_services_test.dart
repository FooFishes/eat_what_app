import 'package:eat/state/consented_services.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../support/fakes.dart';

void main() {
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
}
