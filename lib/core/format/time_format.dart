/// 界面上的时间格式: "刚刚" "12 分钟前" "3 小时前" "昨天" "周一" "10 月 18 日".
abstract final class TimeFormat {
  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  /// 消息和足迹中的相对时间. 一周内显示星期, 更早显示日期, 非今年的日期带年份.
  static String relative(DateTime time, DateTime now) {
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    final today = DateTime(now.year, now.month, now.day);
    if (!time.isBefore(today)) return '${diff.inHours} 小时前';
    final yesterday = today.subtract(const Duration(days: 1));
    if (!time.isBefore(yesterday)) return '昨天';
    if (!time.isBefore(today.subtract(const Duration(days: 6)))) {
      return _weekdays[time.weekday - 1];
    }
    return date(time, now);
  }

  /// 日期, 如 "10 月 18 日". 非今年时带年份, 如 "2025 年 10 月 18 日".
  static String date(DateTime time, DateTime now) => time.year == now.year
      ? '${time.month} 月 ${time.day} 日'
      : '${time.year} 年 ${time.month} 月 ${time.day} 日';
}
