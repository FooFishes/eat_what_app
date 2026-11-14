/// 使用统计开关. [retentionDays] 是事件保存的天数, 服务端没有给出时为 null.
class const UsageStats({required final bool enabled, final int? retentionDays});
