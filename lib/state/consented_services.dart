import 'dart:async';

import 'package:eat/core/platform/hot_update.dart';
import 'package:eat/core/telemetry/crash_reporter.dart';
import 'package:eat/state/device.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consented_services.g.dart';

/// 管理须在同意隐私政策后方可启动的服务 (崩溃上报, 热更新检查和设备注册), 状态值表示是否已启动.
///
/// 若启动时本机已有同意记录, 则由 `bootstrap` 在首帧前启动; 首次登录时由登录流程在写入同意记录后启动.
@Riverpod(keepAlive: true)
class ConsentedServices extends _$ConsentedServices {
  @override
  bool build() => false;

  /// 在确认本机存在同意记录后启动各项服务, 重复调用仅生效一次.
  ///
  /// 单项服务失败不会影响应用正常使用.
  Future<void> start() async {
    if (state) return;
    if (await ref.read(privacyConsentStoreProvider).agreedVersion() == null) {
      return;
    }
    state = true;
    final reporter = ref.read(crashReporterProvider);
    try {
      await reporter.start(patch: await ref.read(currentPatchProvider.future));
    } on Object catch (e) {
      debugPrint('crash reporter failed to start: $e');
    }
    ref.listen(
      sessionProvider,
      (_, session) => unawaited(reporter.setUser(_userId(session))),
      fireImmediately: true,
    );
    unawaited(ref.read(hotUpdateProvider).downloadIfAvailable());
    unawaited(ref.read(deviceRegistrationProvider).register());
  }

  static int? _userId(SessionState session) => switch (session) {
    SignedIn(:final user?) => user.id,
    _ => null,
  };
}
