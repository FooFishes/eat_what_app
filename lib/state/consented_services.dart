import 'dart:async';

import 'package:eat/core/platform/hot_update.dart';
import 'package:eat/core/telemetry/crash_reporter.dart';
import 'package:eat/state/analytics.dart';
import 'package:eat/state/device.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/remote_config.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consented_services.g.dart';

/// 管理须在同意隐私政策后方可启动的服务 (崩溃上报, 远程配置, 热更新检查, 设备注册和使用统计), 状态值表示是否已启动.
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
    unawaited(ref.read(remoteConfigProvider.notifier).refresh());
    unawaited(ref.read(hotUpdateProvider).downloadIfAvailable());
    unawaited(ref.read(deviceRegistrationProvider).register());
    // 等待使用统计读出本机开关, 首帧前记录的冷启动事件才不会被丢弃. 之后每次登录时同步服务端的开关.
    final analytics = ref.read(analyticsProvider);
    await analytics.start();
    ref.listen(sessionProvider, (previous, next) {
      if (next is SignedIn && previous is! SignedIn) {
        unawaited(analytics.syncConsent());
      }
    });
  }

  static int? _userId(SessionState session) => switch (session) {
    SignedIn(:final user?) => user.id,
    _ => null,
  };
}
