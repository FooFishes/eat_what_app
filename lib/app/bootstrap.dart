import 'package:eat_what_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> bootstrap() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://0247296817d5b39d78805706e0c88c70@sentry.orbithy.com/3';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.replay.onErrorSampleRate = 1.0;
      options.replay.sessionSampleRate = 1.0;
      options.debug = false;
      options.diagnosticLevel = SentryLevel.debug;
      options.considerInAppFramesByDefault = true;
    },
    appRunner: () =>
        runApp(ProviderScope(child: SentryWidget(child: const App()))),
  );
}
