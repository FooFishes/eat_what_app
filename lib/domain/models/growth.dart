/// 当前用户的等级与经验进度.
///
/// 升级门槛均为累计经验值, [nextLevelAt] 为 null 表示已满级.
class const GrowthProgress({
  required final int level,
  required final int totalExperience,
  required final int levelStartAt,
  final int? nextLevelAt,
  required final int toNextLevel,

  /// 每日首次使用可获得的经验值.
  required final int dailyExperience,
}) {
  bool get isMaxLevel => nextLevelAt == null;

  /// 当前等级进度, 范围为 0–1, 满级时为 1.
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

/// 经验获取来源. [label] 为服务端未提供显示名称时的兜底名称.
enum ExperienceSource {
  dailyUse('每日使用'),

  /// 客户端暂未识别的来源.
  other('获得经验');

  const new(this.label);

  final String label;

  static ExperienceSource fromApi(String? value) => switch (value) {
    'daily_use' => dailyUse,
    _ => other,
  };
}

/// 单条经验明细. [date] 为该笔经验所属的北京时间日期, 仅日期部分有效.
///
/// [label] 为明细展示名称 (如 "每日使用"), 优先采用服务端下发的显示名.
class const ExperienceEntry({
  required final String id,
  required final ExperienceSource source,
  required final String label,
  required final int amount,
  required final DateTime date,
});
