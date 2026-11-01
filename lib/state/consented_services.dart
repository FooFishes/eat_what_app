import 'dart:async';

import 'package:eat/core/platform/hot_update.dart';
import 'package:eat/core/telemetry/crash_reporter.dart';
import 'package:eat/state/privacy_consent.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consented_services.g.dart';

/// 必须在同意隐私政策后才能启动的服务: 崩溃上报和热更新检查.
///
/// 启动时本机已有同意记录, 由 `bootstrap` 在首帧前启动.
/// 首次登录时由登录流程在写入同意记录后启动.
/// 状态表示是否已启动.
@Riverpod(keepAlive: true)
class ConsentedServices extends _$ConsentedServices {
  @override
  bool build() => false;

  /// 本机有同意记录时启动各项服务. 重复调用只生效一次.
  ///
  /// 任何一项失败都不影响应用使用.
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
  }

  static int? _userId(SessionState session) => switch (session) {
    SignedIn(:final user?) => user.id,
    _ => null,
  };
}
