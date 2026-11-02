import 'package:eat/core/storage/device_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  test('首次读取时生成并保存，之后读到同一个', () async {
    final store = MemorySecureStore();

    final first = await DeviceId(store).read();
    final again = await DeviceId(store).read();

    expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(store.values[DeviceId.key], first);
    expect(again, first);
  });

  test('存的值格式不符时重新生成', () async {
    final store = MemorySecureStore()..values[DeviceId.key] = 'bad id';

    final id = await DeviceId(store).read();

    expect(id, isNot('bad id'));
    expect(store.values[DeviceId.key], id);
  });

  test('同一实例并发读取只生成一次', () async {
    final id = DeviceId(MemorySecureStore());

    final ids = await Future.wait([id.read(), id.read()]);

    expect(ids[0], ids[1]);
  });

  test('每次生成的标识不同', () {
    expect(DeviceId.generate(), isNot(DeviceId.generate()));
  });
}
