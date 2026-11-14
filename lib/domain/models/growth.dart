/// 本人的等级和经验进度.
///
/// 门槛都是累计经验. [nextLevelAt] 为 null 表示已满级.
class const GrowthProgress({
  required final int level,
  required final int totalExperience,
  required final int levelStartAt,
  final int? nextLevelAt,
  required final int toNextLevel,

  /// 每天第一次使用得到的经验.
  required final int dailyExperience,
}) {
  bool get isMaxLevel => nextLevelAt == null;

  /// 本级进度, 0 到 1. 满级时为 1.
  double get levelProgress => switch (nextLevelAt) {
    null => 1,
    final next when next <= levelStartAt => 0,
    final next =>
      ((totalExperience - levelStartAt) / (next - levelStartAt)).clamp(
        0.0,
        1.0,
      ),
  };
}

/// 经验的来源. [label] 是服务端没有给出显示名时用的名称.
enum ExperienceSource {
  dailyUse('每日使用'),

  /// 客户端还不认识的来源.
  other('获得经验');

  const new(this.label);

  final String label;

  static ExperienceSource fromApi(String? value) => switch (value) {
    'daily_use' => dailyUse,
    _ => other,
  };
}

/// 经验明细中的一笔. [date] 是这笔经验所属的那一天 (北京时间), 只有日期部分有意义.
///
/// [label] 是明细中的名称, 如 "每日使用", 优先用服务端给的显示名.
class const ExperienceEntry({
  required final String id,
  required final ExperienceSource source,
  required final String label,
  required final int amount,
  required final DateTime date,
});
