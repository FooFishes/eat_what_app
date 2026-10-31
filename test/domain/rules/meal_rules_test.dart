import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/meal_rules.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _at(int hour, int minute, {int day = 1}) =>
    DateTime(2026, 11, day, hour, minute);

void main() {
  test('按时间段归到饭点，边界算后一顿', () {
    expect(MealRules.at(_at(4, 59)), MealTime.night);
    expect(MealRules.at(_at(5, 0)), MealTime.breakfast);
    expect(MealRules.at(_at(10, 29)), MealTime.breakfast);
    expect(MealRules.at(_at(10, 30)), MealTime.lunch);
    expect(MealRules.at(_at(14, 30)), MealTime.dinner);
    expect(MealRules.at(_at(20, 29)), MealTime.dinner);
    expect(MealRules.at(_at(20, 30)), MealTime.night);
    expect(MealRules.at(_at(23, 59)), MealTime.night);
  });

  test('时间段在下一顿开始时结束，夜宵跨到第二天早上 5 点', () {
    expect(MealRules.periodEnd(_at(7, 0)), _at(10, 30));
    expect(MealRules.periodEnd(_at(12, 0)), _at(14, 30));
    expect(MealRules.periodEnd(_at(18, 0)), _at(20, 30));
    expect(MealRules.periodEnd(_at(22, 0)), _at(5, 0, day: 2));
    expect(MealRules.periodEnd(_at(2, 0)), _at(5, 0));
  });
}
