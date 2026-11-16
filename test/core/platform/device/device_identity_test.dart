import 'package:eat/core/platform/device/device_identity.dart';
import 'package:eat/core/platform/device/device_profile.dart';
import 'package:eat/core/storage/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

/// 读或写会失败的安全存储, 模拟备份恢复后无法解密等情况.
class _BrokenSecureStore extends MemorySecureStore {
  _BrokenSecureStore({this.readFails = false, this.writeFails = false});

  final bool readFails;
  final bool writeFails;

  @override
  Future<String?> read(String key) async {
    if (readFails) throw Exception('unwrap failed');
    return super.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (writeFails) throw Exception('keystore unavailable');
    await super.write(key, value);
  }
}

final _v7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  group('安装 ID', () {
    test('首次使用时生成 UUID v7 并存进安全存储', () async {
      final store = MemorySecureStore();

      final id = await DeviceIdentity(store).installId();

      expect(id, matches(_v7));
      expect(store.values[DeviceIdentity.key], id);
    });

    test('已有安装 ID 时沿用，新实例也读到同一个', () async {
      final store = MemorySecureStore();
      final first = await DeviceIdentity(store).installId();

      expect(await DeviceIdentity(store).installId(), first);
    });

    test('存着的值不是 UUID 时重新生成', () async {
      final store = MemorySecureStore()..values[DeviceIdentity.key] = 'junk';

      final id = await DeviceIdentity(store).installId();

      expect(id, matches(_v7));
      expect(store.values[DeviceIdentity.key], id);
    });

    test('读安全存储失败时重新生成并覆盖，不抛出', () async {
      final SecureStore store = _BrokenSecureStore(readFails: true);

      final id = await DeviceIdentity(store).installId();

      expect(id, matches(_v7));
      expect((store as MemorySecureStore).values[DeviceIdentity.key], id);
    });

    test('写不进安全存储时本次运行内仍用同一个 ID', () async {
      final identity = DeviceIdentity(_BrokenSecureStore(writeFails: true));

      final id = await identity.installId();

      expect(id, matches(_v7));
      expect(await identity.installId(), id);
    });
  });

  group('构建号', () {
    test('有补丁号时附在构建号后面', () {
      expect(appBuildOf('62', 3), '62+3');
      expect(appBuildOf('62', null), '62');
      expect(appBuildOf('', 3), isNull);
      expect(appBuildOf(null, null), isNull);
    });
  });
}
