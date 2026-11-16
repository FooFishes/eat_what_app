/// 远程配置 (`GET /remote-config`) 的领域模型: 功能开关, 运营参数, 公告, 维护状态和各平台的版本线.
///
/// 配置只能关闭已有功能或给出提示, 不能开启新功能或新的数据收集 (产品 12.2).
library;

/// 远程配置中可单独关闭的功能, 枚举名即接口 `flags` 中的键.
enum RemoteFeature { publish, newShop, comment, push, topic }

/// 单个功能开关.
class const FeatureFlag({
  required final bool on,

  /// 关闭原因, 仅在 [on] 为 false 时可能有值.
  final String? reason,
}) {
  static const enabled = FeatureFlag(on: true);
}

/// 全站维护状态. 服务端不据此拒绝请求, 由客户端负责拦截.
enum MaintenanceMode {
  none,

  /// 全站只读: 能浏览, 写操作点击后提示维护中.
  readOnly,

  /// 停服维护: 所有页面进入维护页.
  down,
}

class const Maintenance({
  final MaintenanceMode mode = MaintenanceMode.none,

  /// 运营填写的维护说明.
  final String? message,

  /// 预计恢复时间.
  final DateTime? until,
});

enum AnnouncementLevel {
  /// 普通公告: 显示在发现页抽屉顶部, 可关闭.
  normal,

  /// 重要公告: 打开 App 时弹窗, 看过一次后不再弹出.
  important,
}

class const Announcement({
  required final int id,
  required final AnnouncementLevel level,
  final String? title,
  required final String content,

  /// 详情链接, 为 https 地址或站内绝对路径.
  final String? linkUrl,
  final DateTime? startsAt,
  final DateTime? endsAt,
});

/// 单个平台的版本线. 构建号为 0 表示未设置.
class const VersionLine({
  /// 最低可用构建号, 低于该值时强制更新.
  final int minBuild = 0,

  /// 最新构建号, 低于该值时建议更新.
  final int latestBuild = 0,
  final String? latestVersionName,

  /// 商店地址, 为 https, `market` 或 `itms-apps` 链接.
  final String? storeUrl,
  final String? releaseNotes,
});

/// 一份完整的远程配置快照.
class const ClientConfig({
  /// 服务端配置的总版本号, 每次修改递增.
  final int configVersion = 0,
  final Map<RemoteFeature, FeatureFlag> flags = const {},

  /// 运营参数的原始值, 键为接口中的参数名 (如 `batchSize`). 未出现的参数由使用方取默认值.
  final Map<String, Object?> params = const {},

  /// 当前生效的公告, 重要公告在前.
  final List<Announcement> announcements = const [],
  final Maintenance maintenance = const Maintenance(),

  /// 各平台的版本线, 键为 `android`, `ios` 或 `web`.
  final Map<String, VersionLine> versions = const {},
}) {
  /// 内置默认值也无法读取时的兜底配置: 功能全部开启, 没有公告和维护, 不检查版本.
  static const empty = ClientConfig();

  /// 读取功能开关. 配置中没有的开关按开启处理.
  FeatureFlag flag(RemoteFeature feature) =>
      flags[feature] ?? FeatureFlag.enabled;
}
