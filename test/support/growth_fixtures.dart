/// 等级接口的响应样例.
library;

/// `/user/growth` 的 `data`. 默认 Lv.3, 累计 125, 下一级门槛 250.
Map<String, Object?> growthJson({
  int level = 3,
  int total = 125,
  int start = 100,
  int? next = 250,
}) => {
  'totalExperience': total,
  'level': level,
  'levelStartExperience': start,
  'nextLevelExperience': next,
  'experienceInLevel': total - start,
  'experienceToNextLevel': next == null ? 0 : next - total,
  'maxLevel': next == null,
  'levelRuleVersion': 'growth-levels-v1',
  'dailyExperience': 5,
};

/// 经验明细的一笔.
Map<String, Object?> experienceJson({
  String id = 'e-1',
  String date = '2026-11-10',
  String source = 'DAILY_USE',
  int experience = 5,
}) => {
  'entryId': id,
  'businessDate': date,
  'sourceType': source,
  'experience': experience,
  'ruleVersion': 'daily-use-v1',
  'createdAt': '${date}T00:05:00Z',
};
