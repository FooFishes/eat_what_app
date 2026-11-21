import 'package:clock/clock.dart';
import 'package:eat/core/platform/hot_update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../../support/fakes.dart';

void main() {
  late FakeShorebirdUpdater updater;
  late HotUpdate hotUpdate;

  setUp(() {
    updater = FakeShorebirdUpdater();
    hotUpdate = HotUpdate(updater);
  });

  test('不是 shorebird release 构建的包：没有补丁号，也不检查更新', () async {
    updater.patch = 3;

    expect(await hotUpdate.currentPatch(), isNull);
    await hotUpdate.downloadIfAvailable();
    expect(updater.checks, 0);
  });

  test('可用时读出补丁号；没装过补丁时为 null', () async {
    updater.isAvailable = true;
    expect(await hotUpdate.currentPatch(), isNull);

    updater.patch = 3;
    expect(await hotUpdate.currentPatch(), 3);
  });

  test('有新补丁才下载，已是最新时不下载', () async {
    updater.isAvailable = true;
    await hotUpdate.downloadIfAvailable();
    expect(updater.updates, 0);

    updater.status = UpdateStatus.outdated;
    await hotUpdate.downloadIfAvailable();
    expect(updater.updates, 1);
  });

  test('下载失败不抛出，等下次回到前台再检查', () async {
    updater
      ..isAvailable = true
      ..status = UpdateStatus.outdated
      ..updateError = const UpdateException(
        message: 'offline',
        reason: UpdateFailureReason.downloadFailed,
      );

    await expectLater(hotUpdate.downloadIfAvailable(), completes);
  });

  group('回到前台', () {
    final start = DateTime(2026, 11, 21, 12);

    Future<void> resumeAt(Duration elapsed) =>
        withClock(Clock.fixed(start.add(elapsed)), hotUpdate.resume);

    setUp(() => updater.isAvailable = true);

    test('还没开始检查过时不检查', () async {
      await resumeAt(Duration.zero);
      expect(updater.checks, 0);
    });

    test('距上次成功检查不到 10 分钟不再检查，超过后再查一次', () async {
      await withClock(Clock.fixed(start), hotUpdate.downloadIfAvailable);
      expect(updater.checks, 1);

      await resumeAt(const Duration(minutes: 9));
      expect(updater.checks, 1);

      updater.status = UpdateStatus.outdated;
      await resumeAt(const Duration(minutes: 11));
      expect(updater.checks, 2);
      expect(updater.updates, 1);
    });

    test('上次检查失败时回到前台就重试', () async {
      updater
        ..status = UpdateStatus.outdated
        ..updateError = const UpdateException(
          message: 'offline',
          reason: UpdateFailureReason.downloadFailed,
        );
      await withClock(Clock.fixed(start), hotUpdate.downloadIfAvailable);
      expect(updater.checks, 1);

      updater.updateError = null;
      await resumeAt(const Duration(minutes: 1));
      expect(updater.checks, 2);
      expect(updater.updates, 2);
    });
  });

  test('并发检查共用一次请求，只下载一次', () async {
    updater
      ..isAvailable = true
      ..status = UpdateStatus.outdated;

    final background = hotUpdate.downloadIfAvailable();
    final manual = hotUpdate.check();
    await background;

    expect(await manual, PatchCheck.ready);
    expect(updater.checks, 1);
    expect(updater.updates, 1);
  });
}
