import 'package:eat/domain/models/client_config.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/remote_config_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Announcement _notice(
  int id, {
  AnnouncementLevel level = AnnouncementLevel.normal,
  DateTime? startsAt,
  DateTime? endsAt,
}) => Announcement(
  id: id,
  level: level,
  content: '公告 $id',
  startsAt: startsAt,
  endsAt: endsAt,
);

void main() {
  final now = DateTime(2026, 11, 16, 12);

  group('版本检查', () {
    const line = VersionLine(minBuild: 20, latestBuild: 30);

    test('低于最低构建号强制更新，低于最新构建号建议更新', () {
      expect(updateDecision(line, 19), UpdateDecision.force);
      expect(updateDecision(line, 20), UpdateDecision.suggest);
      expect(updateDecision(line, 29), UpdateDecision.suggest);
      expect(updateDecision(line, 30), UpdateDecision.none);
      expect(updateDecision(line, 31), UpdateDecision.none);
    });

    test('版本线未设置、缺失或构建号未知时不检查', () {
      expect(updateDecision(const VersionLine(), 1), UpdateDecision.none);
      expect(updateDecision(null, 1), UpdateDecision.none);
      expect(updateDecision(line, null), UpdateDecision.none);
      expect(
        updateDecision(const VersionLine(latestBuild: 30), 10),
        UpdateDecision.suggest,
        reason: '只设了最新构建号时不强制',
      );
    });

    test('同一个最新构建号只提示一次', () {
      expect(shouldPromptUpdate(UpdateDecision.suggest, line, null), isTrue);
      expect(shouldPromptUpdate(UpdateDecision.suggest, line, 30), isFalse);
      expect(
        shouldPromptUpdate(UpdateDecision.suggest, line, 25),
        isTrue,
        reason: '又出了新版本时再提示',
      );
      expect(shouldPromptUpdate(UpdateDecision.force, line, null), isFalse);
      expect(shouldPromptUpdate(UpdateDecision.none, line, null), isFalse);
    });
  });

  group('公告', () {
    test('生效期按开始和结束时间判断，结束时间不含', () {
      expect(isAnnouncementLive(_notice(1), now), isTrue);
      expect(
        isAnnouncementLive(
          _notice(1, startsAt: now.add(const Duration(minutes: 1))),
          now,
        ),
        isFalse,
      );
      expect(isAnnouncementLive(_notice(1, startsAt: now), now), isTrue);
      expect(isAnnouncementLive(_notice(1, endsAt: now), now), isFalse);
    });

    test('公告条取第一条没关掉的普通公告', () {
      final all = [
        _notice(9, level: AnnouncementLevel.important),
        _notice(8),
        _notice(7),
      ];
      expect(bannerAnnouncement(all, {}, now)?.id, 8);
      expect(bannerAnnouncement(all, {8}, now)?.id, 7);
      expect(bannerAnnouncement(all, {8, 7}, now), isNull);
    });

    test('重要公告取第一条没看过且生效中的', () {
      final all = [
        _notice(
          9,
          level: AnnouncementLevel.important,
          endsAt: now.subtract(const Duration(hours: 1)),
        ),
        _notice(8, level: AnnouncementLevel.important),
        _notice(7),
      ];
      expect(pendingImportantAnnouncement(all, {}, now)?.id, 8);
      expect(pendingImportantAnnouncement(all, {8}, now), isNull);
    });
  });

  group('拦截', () {
    const readOnly = ClientConfig(
      maintenance: Maintenance(mode: MaintenanceMode.readOnly),
    );
    const commentOff = ClientConfig(
      flags: {RemoteFeature.comment: FeatureFlag(on: false, reason: '评论区在调整')},
    );

    test('配置正常时放行', () {
      expect(
        remoteGate(
          ClientConfig.empty,
          feature: RemoteFeature.comment,
          write: true,
        ),
        isA<RemoteOpen>(),
      );
    });

    test('只读时拦写操作，放行只读操作', () {
      expect(remoteGate(readOnly, write: true), isA<RemoteReadOnly>());
      expect(remoteGate(readOnly, write: false), isA<RemoteOpen>());
    });

    test('只读先于功能开关', () {
      const both = ClientConfig(
        flags: {RemoteFeature.comment: FeatureFlag(on: false)},
        maintenance: Maintenance(mode: MaintenanceMode.readOnly),
      );
      expect(
        remoteGate(both, feature: RemoteFeature.comment, write: true),
        isA<RemoteReadOnly>(),
      );
    });

    test('功能关闭时带上原因', () {
      final gate = remoteGate(
        commentOff,
        feature: RemoteFeature.comment,
        write: true,
      );
      expect(gate, isA<RemoteFeatureOff>());
      expect((gate as RemoteFeatureOff).flag.reason, '评论区在调整');
      expect(
        remoteGate(commentOff, feature: RemoteFeature.publish, write: true),
        isA<RemoteOpen>(),
      );
    });

    test('受限操作对应的功能开关', () {
      expect(remoteFeatureOf(Capability.publishDish), RemoteFeature.publish);
      expect(remoteFeatureOf(Capability.editDish), RemoteFeature.publish);
      expect(remoteFeatureOf(Capability.createShop), RemoteFeature.newShop);
      expect(remoteFeatureOf(Capability.comment), RemoteFeature.comment);
      expect(remoteFeatureOf(Capability.reply), RemoteFeature.comment);
      expect(remoteFeatureOf(Capability.like), isNull);
    });

    test('查看类操作不算写操作', () {
      expect(isWriteCapability(Capability.viewInbox), isFalse);
      expect(isWriteCapability(Capability.viewProfile), isFalse);
      expect(isWriteCapability(Capability.like), isTrue);
      expect(isWriteCapability(Capability.publishDish), isTrue);
    });
  });

  group('提示文案', () {
    test('只读提示带预计恢复时间', () {
      expect(
        readOnlyMessage(
          Maintenance(
            mode: MaintenanceMode.readOnly,
            until: DateTime(2026, 11, 16, 23, 30),
          ),
          now,
        ),
        '系统维护中，暂停发布，预计 23:30 恢复',
      );
      expect(
        readOnlyMessage(const Maintenance(mode: MaintenanceMode.readOnly), now),
        '系统维护中，暂停发布',
      );
    });

    test('运营写了维护说明时用说明原文', () {
      expect(
        readOnlyMessage(
          const Maintenance(
            mode: MaintenanceMode.readOnly,
            message: '数据迁移中，暂停发布',
          ),
          now,
        ),
        '数据迁移中，暂停发布',
      );
    });

    test('功能关闭提示有原因时接上原因', () {
      expect(featureOffMessage(const FeatureFlag(on: false)), '该功能暂时关闭');
      expect(
        featureOffMessage(const FeatureFlag(on: false, reason: '评论区在调整')),
        '该功能暂时关闭，评论区在调整',
      );
    });

    test('恢复时间按距今天数写', () {
      expect(recoveryTime(DateTime(2026, 11, 16, 23, 30), now), '23:30');
      expect(recoveryTime(DateTime(2026, 11, 17, 8), now), '明天 08:00');
      expect(recoveryTime(DateTime(2026, 11, 30, 8), now), '11 月 30 日 08:00');
      expect(
        recoveryTime(DateTime(2027, 1, 2, 8), now),
        '2027 年 1 月 2 日 08:00',
      );
    });
  });
}
