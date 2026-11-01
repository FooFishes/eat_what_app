import 'package:eat/domain/models/dish.dart';

/// 按时刻划分饭点. 每个饭点从 [_starts] 中的时刻开始, 到下一个饭点开始时结束.
abstract final class MealRules {
  /// 各饭点的起始时刻, 以一天中的分钟数表示.
  static const _starts = {
    MealTime.breakfast: 5 * 60,
    MealTime.lunch: 10 * 60 + 30,
    MealTime.dinner: 14 * 60 + 30,
    MealTime.night: 20 * 60 + 30,
  };

  static MealTime at(DateTime time) {
    final minute = time.hour * 60 + time.minute;
    if (minute < _starts[MealTime.breakfast]!) return MealTime.night;
    if (minute < _starts[MealTime.lunch]!) return MealTime.breakfast;
    if (minute < _starts[MealTime.dinner]!) return MealTime.lunch;
    if (minute < _starts[MealTime.night]!) return MealTime.dinner;
    return MealTime.night;
  }

  /// [time] 所在饭点时间段的结束时刻.
  ///
  /// 手动选择的饭点保持到该时刻, 之后恢复为按当前时间判断.
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
