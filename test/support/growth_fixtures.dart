/// 等级接口的响应样例.
library;

/// `/user/level` 的 `data`. 默认 Lv.3, 累计 125, 下一级门槛 250.
Map<String, Object?> growthJson({
  int level = 3,
  int total = 125,
  int start = 100,
  int? next = 250,
}) => {
  'level': level,
  'experience': total,
  'levelExperience': start,
  'nextLevel': next == null ? null : level + 1,
  'nextLevelExperience': next,
  'toNextLevel': next == null ? null : next - total,
  'maxLevel': next == null,
  'dailyUseExperience': 5,
};

/// `/user/level/logs` 的一笔.
Map<String, Object?> experienceJson({
  int id = 1,
  String date = '2026-11-10',
  String source = 'daily_use',
  String? sourceName = '每日使用',
  int experience = 5,
}) => {
  'id': id,
  'source': source,
  'sourceName': sourceName,
  'amount': experience,
  'day': date,
  'createdAt': DateTime.parse('${date}T00:05:00Z').millisecondsSinceEpoch,
};
