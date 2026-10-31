import 'package:eat/domain/models/dish.dart';

/// 饭点的时间段（产品 4.5）：早饭 05:00–10:30、午饭 10:30–14:30、晚饭 14:30–20:30、
/// 夜宵 20:30–次日 05:00。
abstract final class MealRules {
  /// 每个饭点从一天里的第几分钟开始。
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

  /// [time] 所在时间段在什么时候结束。手动选的饭点保持到这个时候，之后回到按时间（产品 4.5）。
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
