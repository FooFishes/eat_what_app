import 'package:eat/data/common/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dateFromIso', () {
    test('读带时区的时间，转成本地时间', () {
      final date = dateFromIso('2026-11-01T04:00:00Z')!;

      expect(date.isUtc, isFalse);
      expect(date.toUtc(), DateTime.utc(2026, 11, 1, 4));
    });

    test('纳秒精度只保留到微秒', () {
      expect(
        dateFromIso('2026-11-01T04:00:00.123456789Z')!.toUtc(),
        DateTime.utc(2026, 11, 1, 4, 0, 0, 123, 456),
      );
    });

    test('缺失或无法解析时为 null', () {
      expect(dateFromIso(null), isNull);
      expect(dateFromIso(''), isNull);
      expect(dateFromIso('1793505600000'), isNull);
    });
  });

  test('设备名称：未知设备和空白都当作没有名称', () {
    expect(deviceNameOf(' Pixel 8 '), 'Pixel 8');
    expect(deviceNameOf('未知设备'), isNull);
    expect(deviceNameOf('  '), isNull);
    expect(deviceNameOf(null), isNull);
  });
}
