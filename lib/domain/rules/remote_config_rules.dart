/// 远程配置的产品规则: 版本检查, 公告筛选, 维护和功能开关对操作的拦截及其提示文案.
library;

import 'package:eat/domain/models/client_config.dart';
import 'package:eat/domain/rules/permission_policy.dart';

/// 本机构建号与版本线比较的结果.
enum UpdateDecision {
  none,

  /// 低于最新构建号, 在发现页提示一次 "有新版本".
  suggest,

  /// 低于最低可用构建号, 所有页面进入更新页.
  force,
}

/// 用构建号 [build] 与版本线 [line] 比较, 不比较版本名.
///
/// 版本线缺失, 构建号未知或版本线未设置 (构建号为 0) 时返回 [UpdateDecision.none].
UpdateDecision updateDecision(VersionLine? line, int? build) {
  if (line == null || build == null) return UpdateDecision.none;
  if (line.minBuild > 0 && build < line.minBuild) return UpdateDecision.force;
  if (line.latestBuild > 0 && build < line.latestBuild) {
    return UpdateDecision.suggest;
  }
  return UpdateDecision.none;
}

/// 判断建议更新是否还需要提示. 同一个最新构建号只提示一次, [promptedBuild] 为上次提示过的构建号.
bool shouldPromptUpdate(
  UpdateDecision decision,
  VersionLine? line,
  int? promptedBuild,
) =>
    decision == UpdateDecision.suggest &&
    line != null &&
    (promptedBuild == null || promptedBuild < line.latestBuild);

/// 判断公告在 [now] 是否处于生效期.
///
/// 服务端只在请求时按生效期筛选, 本地快照可能已越过结束时间, 因此展示前重新判断.
bool isAnnouncementLive(Announcement announcement, DateTime now) {
  final starts = announcement.startsAt;
  final ends = announcement.endsAt;
  return (starts == null || !starts.isAfter(now)) &&
      (ends == null || ends.isAfter(now));
}

/// 发现页抽屉顶部要显示的普通公告: 生效中且未被关掉的第一条.
Announcement? bannerAnnouncement(
  List<Announcement> announcements,
  Set<int> dismissed,
  DateTime now,
) => announcements
    .where(
      (a) =>
          a.level == AnnouncementLevel.normal &&
          !dismissed.contains(a.id) &&
          isAnnouncementLive(a, now),
    )
    .firstOrNull;

/// 打开 App 时要弹出的重要公告: 生效中且本机未看过的第一条.
Announcement? pendingImportantAnnouncement(
  List<Announcement> announcements,
  Set<int> seen,
  DateTime now,
) => announcements
    .where(
      (a) =>
          a.level == AnnouncementLevel.important &&
          !seen.contains(a.id) &&
          isAnnouncementLive(a, now),
    )
    .firstOrNull;

/// 远程配置对一次操作的判定结果.
sealed class RemoteGate {
  const RemoteGate();
}

final class RemoteOpen extends RemoteGate {
  const RemoteOpen();
}

/// 全站只读维护中, 写操作被拦截.
final class RemoteReadOnly extends RemoteGate {
  const RemoteReadOnly(this.maintenance);

  final Maintenance maintenance;
}

/// 操作所属的功能已被关闭.
final class RemoteFeatureOff extends RemoteGate {
  const RemoteFeatureOff(this.feature, this.flag);

  final RemoteFeature feature;
  final FeatureFlag flag;
}

/// 判断远程配置是否允许一次操作. [feature] 为操作所属的功能, [write] 表示操作会修改数据.
///
/// 先看全站只读, 再看功能开关 (技术架构 8.2). 停服维护时页面已进入维护页, 写操作仍按只读拦截.
RemoteGate remoteGate(
  ClientConfig config, {
  RemoteFeature? feature,
  required bool write,
}) {
  if (write && config.maintenance.mode != MaintenanceMode.none) {
    return RemoteReadOnly(config.maintenance);
  }
  if (feature != null) {
    final flag = config.flag(feature);
    if (!flag.on) return RemoteFeatureOff(feature, flag);
  }
  return const RemoteOpen();
}

/// 受限操作所属的可远程关闭的功能, 不属于任何开关时返回 null.
///
/// 专题暂缓 (`PendingFeature.topics`), 发现页没有专题入口, 因此 [RemoteFeature.topic] 暂无对应操作.
/// 推送开关不对应受限操作, 由通知设置页单独判断.
RemoteFeature? remoteFeatureOf(Capability capability) => switch (capability) {
  Capability.publishDish || Capability.editDish => RemoteFeature.publish,
  Capability.createShop => RemoteFeature.newShop,
  Capability.comment || Capability.reply => RemoteFeature.comment,
  _ => null,
};

/// 判断受限操作是否会修改数据. 全站只读时只放行不修改数据的操作.
///
/// 未列出的操作按写操作处理, 新增的操作默认在只读期间被拦截.
bool isWriteCapability(Capability capability) => switch (capability) {
  Capability.viewHistory ||
  Capability.viewFollows ||
  Capability.viewGrowth ||
  Capability.viewInbox ||
  Capability.viewProfile ||
  Capability.viewFavorites => false,
  _ => true,
};

/// 全站只读时点击写操作的提示, 如 "系统维护中，暂停发布，预计 23:30 恢复".
///
/// 运营填写了维护说明时直接使用说明原文.
String readOnlyMessage(Maintenance maintenance, DateTime now) {
  final message = maintenance.message?.trim();
  if (message != null && message.isNotEmpty) return message;
  return switch (maintenance.until) {
    final until? => '系统维护中，暂停发布，预计 ${recoveryTime(until, now)} 恢复',
    null => '系统维护中，暂停发布',
  };
}

/// 点击已关闭功能的提示. 有关闭原因时接在后面.
String featureOffMessage(FeatureFlag flag) {
  final reason = flag.reason?.trim();
  return reason == null || reason.isEmpty ? '该功能暂时关闭' : '该功能暂时关闭，$reason';
}

/// 格式化预计恢复时间: 当天为 "23:30", 次日为 "明天 08:00", 更晚为 "11 月 30 日 08:00", 跨年时附带年份.
String recoveryTime(DateTime until, DateTime now) {
  final local = until.toLocal();
  final hm =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = day.difference(today).inDays;
  if (days <= 0) return hm;
  if (days == 1) return '明天 $hm';
  final date = local.year == now.year
      ? '${local.month} 月 ${local.day} 日'
      : '${local.year} 年 ${local.month} 月 ${local.day} 日';
  return '$date $hm';
}
