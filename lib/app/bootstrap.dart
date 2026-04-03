import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eat_what_app/app/app.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> bootstrap() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  // Follow the Baidu Flutter plugin init order: consent + key before any map
  // widget is created by runApp.
  BMFMapSDK.setAgreePrivacy(true);
  if (Platform.isIOS) {
    BMFMapSDK.setApiKeyAndCoordType(
      'bltVOlVysogOx8a7QcH4hPiIPCgluXwx',
      BMF_COORD_TYPE.COMMON,
    );
  } else if (Platform.isAndroid) {
    BMFMapSDK.setCoordType(BMF_COORD_TYPE.COMMON);
  }

  final locPlugin = LocationFlutterPlugin();
  locPlugin.setAgreePrivacy(true);
  if (Platform.isIOS) {
    locPlugin.authAK('bltVOlVysogOx8a7QcH4hPiIPCgluXwx');
  }

  await SentryFlutter.init(
    (options) {
      // ── 基础配置 ──────────────────────────────────────────
      options.dsn = kDebugMode
          ? 'https://0247296817d5b39d78805706e0c88c70@sentry.orbithy.com/3' // Debug 环境不上报，避免污染线上数据
          : 'https://0247296817d5b39d78805706e0c88c70@sentry.orbithy.com/3';

      options.environment = kDebugMode ? 'debug' : 'production';

      // ── 采样率 ──────────────────────────────────────────
      options.tracesSampleRate = kDebugMode ? 1.0 : 0.3;
      options.profilesSampleRate = kDebugMode ? 1.0 : 0.1;
      options.replay.onErrorSampleRate = 1.0; // 出错时总是录制
      options.replay.sessionSampleRate = kDebugMode ? 1.0 : 0.1;

      // ── 调试 ──────────────────────────────────────────
      options.debug = kDebugMode;
      options.diagnosticLevel =
          kDebugMode ? SentryLevel.warning : SentryLevel.warning;

      // ── 增强功能 ──────────────────────────────────────────
      options.attachScreenshot = true;
      options.attachViewHierarchy = true;
      options.reportSilentFlutterErrors = true;
      options.enableUserInteractionTracing = true;
      options.considerInAppFramesByDefault = true;

      // ── ANR / App Hang 检测 ──────────────────────────────
      options.anrEnabled = true;
      options.enableAppHangTracking = true;

      // ── beforeSend 过滤 ──────────────────────────────────
      options.beforeSend = (event, hint) {
        final throwable = event.throwable;
        // 过滤掉用户主动取消请求的事件
        if (throwable is NetworkException &&
            throwable.dioExceptionType ==
                DioExceptionType.cancel) {
          return null;
        }
        return event;
      };
    },
    appRunner: () =>
        runApp(ProviderScope(child: SentryWidget(child: const App()))),
  );
}
