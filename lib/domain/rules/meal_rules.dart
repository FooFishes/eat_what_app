import 'package:eat/domain/models/meal_time.dart';

/// 按时刻划分饭点. 每个饭点从 [_starts] 中的时刻开始, 到下一个饭点开始时结束.
///
/// 边界和后端不传 `mealTime` 时的默认划分 (`RestaurantTraits.slotAt`) 一致,
/// 都是整点 5、10、15、21 点, 起点归后一顿; 产品文档 4.5 也按这套写.
abstract final class MealRules {
  /// 各饭点的起始时刻, 以一天中的分钟数表示.
  static const _starts = {
    MealTime.breakfast: 5 * 60,
    MealTime.lunch: 10 * 60,
    MealTime.dinner: 15 * 60,
    MealTime.night: 21 * 60,
  };

  static MealTime at(DateTime time) {
    final minute = time.hour * 60 + time.minute;
    if (minute < _starts[MealTime.breakfast]!) return MealTime.night;
    if (minute < _starts[MealTime.lunch]!) return MealTime.breakfast;
    if (minute < _starts[MealTime.dinner]!) return MealTime.lunch;
    if (minute < _starts[MealTime.night]!) return MealTime.dinner;
    return MealTime.night;
  }

  /// 计算 [time] 所在饭点时间段的结束时刻.
  ///
  /// 手动切换的饭点将保留至该时刻, 过期后恢复为按当前时间自动判断.
  static DateTime periodEnd(DateTime time) {
    final day = DateTime(time.year, time.month, time.day);
    DateTime atMinute(int minute, {int addDays = 0}) =>
        day.add(Duration(days: addDays, minutes: minute));
    return switch (at(time)) {
      MealTime.breakfast => atMinute(_starts[MealTime.lunch]!),
      MealTime.lunch => atMinute(_starts[MealTime.dinner]!),
      MealTime.dinner => atMinute(_starts[MealTime.night]!),
      MealTime.night when time.hour < 5 => atMinute(
        _starts[MealTime.breakfast]!,
      ),
      MealTime.night => atMinute(_starts[MealTime.breakfast]!, addDays: 1),
    };
  }
}
