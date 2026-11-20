import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late MemoryKvStore kv;
  late PrivacyConsentStore store;

  setUp(() {
    kv = MemoryKvStore();
    store = PrivacyConsentStore(kv);
  });

  test('没有记录时未同意，版本为空', () async {
    expect(await store.agreed(), isFalse);
    expect(await store.agreedVersion(), isNull);
  });

  test('带服务端版本记录：存版本和时间', () async {
    final now = DateTime(2026, 11, 20, 12);
    await withClock(Clock.fixed(now), () => store.record('v3'));

    expect(jsonDecode(kv.values[PrivacyConsentStore.key]!), {
      'version': 'v3',
      'at': now.millisecondsSinceEpoch,
    });
    expect(await store.agreed(), isTrue);
    expect(await store.agreedVersion(), 'v3');
  });

  test('没有服务端版本时只记时间，仍算同意过', () async {
    await store.record(null);

    final saved = jsonDecode(kv.values[PrivacyConsentStore.key]!) as Map;
    expect(saved.containsKey('version'), isFalse);
    expect(saved['at'], isA<int>());
    expect(await store.agreed(), isTrue);
    expect(await store.agreedVersion(), isNull);
  });

  test('旧格式的记录（客户端常量版本）仍算同意过', () async {
    kv.values[PrivacyConsentStore.key] =
        '{"version":"2026-10","at":1792763739329}';

    expect(await store.agreed(), isTrue);
    expect(await store.agreedVersion(), '2026-10');
  });

  test('记录无法解析时按没同意过处理', () async {
    kv.values[PrivacyConsentStore.key] = 'not json';

    expect(await store.agreed(), isFalse);
    expect(await store.agreedVersion(), isNull);
  });
}
