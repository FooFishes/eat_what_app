import 'package:eat/core/platform/device/device_profile.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/device.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const _route = 'POST /device/register';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv()..adapter.on(_route, [FakeAdapter.ok()]);
  });

  Future<void> register({DeviceProfile profile = testDeviceProfile}) async {
    env.deviceProfile = profile;
    final container = await env.container();
    await container.read(deviceRegistrationProvider).register();
  }

  test('注册时带上安装 ID 和设备档案', () async {
    await register();

    expect(env.adapter.sent(_route).single.body, {
      'installId': testInstallId,
      'platform': 'android',
      'hardwareId': 'a3f9c2e1d4b5a6f7',
      'model': 'Pixel 8',
      'osVersion': '14',
      'appVersion': '0.1.0',
      'appBuild': '1',
      'screenWidth': 412,
      'screenHeight': 915,
      'pixelRatio': 2.625,
    });
    expect(env.kv.values[DeviceRegistration.digestKey], isNotNull);
  });

  test('读不到的档案项不发送', () async {
    await register(profile: const DeviceProfile(platform: 'web'));

    expect(env.adapter.sent(_route).single.body, {
      'installId': testInstallId,
      'platform': 'web',
    });
  });

  test('档案没变时下次冷启动不重发', () async {
    await register();
    await register();

    expect(env.adapter.sent(_route), hasLength(1));
  });

  test('App 版本或系统版本变了时重发', () async {
    await register();
    await register(
      profile: const DeviceProfile(
        platform: 'android',
        hardwareId: 'a3f9c2e1d4b5a6f7',
        model: 'Pixel 8',
        osVersion: '15',
        appVersion: '0.2.0',
        appBuild: '2',
        screenWidth: 412,
        screenHeight: 915,
        pixelRatio: 2.625,
      ),
    );

    expect(env.adapter.sent(_route), hasLength(2));
  });

  test('失败时静默，不记下摘要，下次冷启动重试', () async {
    env.adapter.on(_route, [const FakeResponse.offline(), FakeAdapter.ok()]);

    await register();
    expect(env.kv.values[DeviceRegistration.digestKey], isNull);

    await register();
    expect(env.adapter.sent(_route), hasLength(2));
    expect(env.kv.values[DeviceRegistration.digestKey], isNotNull);
  });

  test('同一次运行内只注册一次', () async {
    final container = await env.container();
    final registration = container.read(deviceRegistrationProvider);

    await Future.wait([registration.register(), registration.register()]);

    expect(env.adapter.sent(_route), hasLength(1));
  });

  group('触发时机', () {
    test('本机没有同意记录时不注册', () async {
      final container = await env.container();

      await container.read(consentedServicesProvider.notifier).start();
      await pumpEventQueue();

      expect(env.adapter.sent(_route), isEmpty);
    });

    test('有同意记录后注册', () async {
      env.kv.values[PrivacyConsentStore.key] = '{"version":"2026-10"}';
      final container = await env.container();

      await container.read(consentedServicesProvider.notifier).start();
      await pumpEventQueue();

      expect(env.adapter.sent(_route), hasLength(1));
    });
  });

  test('摘要与平台无关地稳定', () {
    expect(DeviceRegistration.digestOf(''), '811c9dc5');
    expect(DeviceRegistration.digestOf('a'), 'e40c292c');
    expect(DeviceRegistration.digestOf('foobar'), 'bf9cf968');
  });
}
