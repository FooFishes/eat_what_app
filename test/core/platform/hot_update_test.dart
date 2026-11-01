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

  test('下载失败不抛出，等下次启动再检查', () async {
    updater
      ..isAvailable = true
      ..status = UpdateStatus.outdated
      ..updateError = const UpdateException(
        message: 'offline',
        reason: UpdateFailureReason.downloadFailed,
      );

    await expectLater(hotUpdate.downloadIfAvailable(), completes);
  });
}
