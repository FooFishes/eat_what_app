import 'package:eat/core/network/idempotency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('生成第 4 版 UUID，每次不同', () {
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final keys = {for (var i = 0; i < 100; i++) newIdempotencyKey()};

    expect(keys, everyElement(matches(uuid)));
    expect(keys, hasLength(100));
  });
}
