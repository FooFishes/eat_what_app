import 'package:eat/domain/models/topic.dart';

/// 专题的时间段文字和各处的说明文字.
abstract final class TopicRules {
  /// 专题是否正在进行. 开始时刻属于专题, 结束时刻不属于.
  static bool isCurrent(Topic topic, DateTime now) =>
      !now.isBefore(topic.startsAt) && now.isBefore(topic.endsAt);

  /// 起止日期, 如 "10 月 20 日–10 月 26 日". 不在今年的日期带年份.
  ///
  /// 结束日取结束时刻前一刻所在的日期. 结束时刻通常是次日零点, 直接取日期会多出一天.
  static String range(Topic topic, DateTime now) {
    final start = topic.startsAt.toLocal();
    final end = topic.endsAt.toLocal().subtract(
      const Duration(microseconds: 1),
    );
    final last = end.isBefore(start) ? start : end;
    return '${_date(start, now)}–${_date(last, now)}';
  }

  /// 专题的称呼: 正在进行的是 "本周专题", 其余是 "往期专题".
  static String kind(Topic topic, DateTime now) =>
      isCurrent(topic, now) ? '本周专题' : '往期专题';

  /// 菜品详情店卡下的提示. 正在进行的专题写 "本周专题", 其余只写 "专题".
  static String dishHint(Topic topic, DateTime now) =>
      isCurrent(topic, now) ? '收进了本周专题「${topic.name}」' : '收进了专题「${topic.name}」';

  static String _date(DateTime time, DateTime now) => time.year == now.year
      ? '${time.month} 月 ${time.day} 日'
      : '${time.year} 年 ${time.month} 月 ${time.day} 日';
}
