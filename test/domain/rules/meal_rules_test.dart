import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/rules/meal_rules.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _at(int hour, int minute, {int day = 1}) =>
    DateTime(2026, 11, day, hour, minute);

void main() {
  test('按时间段归到饭点，边界算后一顿', () {
    expect(MealRules.at(_at(0, 0)), MealTime.night);
    expect(MealRules.at(_at(4, 59)), MealTime.night);
    expect(MealRules.at(_at(5, 0)), MealTime.breakfast);
    expect(MealRules.at(_at(9, 59)), MealTime.breakfast);
    expect(MealRules.at(_at(10, 0)), MealTime.lunch);
    expect(MealRules.at(_at(14, 59)), MealTime.lunch);
    expect(MealRules.at(_at(15, 0)), MealTime.dinner);
    expect(MealRules.at(_at(20, 59)), MealTime.dinner);
    expect(MealRules.at(_at(21, 0)), MealTime.night);
    expect(MealRules.at(_at(23, 59)), MealTime.night);
  });

  test('时间段在下一顿开始时结束，夜宵跨到第二天早上 5 点', () {
    expect(MealRules.periodEnd(_at(7, 0)), _at(10, 0));
    expect(MealRules.periodEnd(_at(9, 59)), _at(10, 0));
    expect(MealRules.periodEnd(_at(10, 0)), _at(15, 0));
    expect(MealRules.periodEnd(_at(15, 0)), _at(21, 0));
    expect(MealRules.periodEnd(_at(21, 0)), _at(5, 0, day: 2));
    expect(MealRules.periodEnd(_at(23, 59)), _at(5, 0, day: 2));
    expect(MealRules.periodEnd(_at(0, 0)), _at(5, 0));
    expect(MealRules.periodEnd(_at(4, 59)), _at(5, 0));
  });
}
