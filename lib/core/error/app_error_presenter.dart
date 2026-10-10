import 'package:eat_what_app/shared/presentation/widgets/app_toast.dart';
import 'package:flutter/material.dart';

import 'api_exception_ext.dart';

final class AppErrorPresenter {
  const new _();

  static void showErrorToast(BuildContext context, Object error) {
    AppToast.show(
      context,
      message: resolveUserMessage(error),
      type: AppToastType.error,
    );
  }

  static void showMessageToast(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    AppToast.show(context, message: message, type: type, duration: duration);
  }
}
