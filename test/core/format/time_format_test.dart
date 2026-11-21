import 'package:eat/core/format/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('一天中的时刻补足两位', () {
    expect(TimeFormat.clock(5 * 60), '05:00');
    expect(TimeFormat.clock(21 * 60 + 30), '21:30');
    expect(TimeFormat.clock(0), '00:00');
  });
}
