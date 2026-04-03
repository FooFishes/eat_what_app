import 'package:eat_what_app/features/profile/data/models/user_info_response.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry 用户上下文管理
///
/// 在认证状态变更和用户信息加载后调用，确保 Sentry 事件
/// 始终包含当前登录用户的信息，便于排查线上问题。
class SentryUserBinding {
  SentryUserBinding._();

  /// 登录/注册成功后立即调用（此时只有 token，无详细信息）
  static void bindToken(String tokenValue) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        data: {'tokenValue': tokenValue},
      ));
    });
  }

  /// 用户信息加载完成后调用，补充完整上下文
  static void bindUserInfo(UserInfoResponse userInfo) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userInfo.id.toString(),
        username: userInfo.userName,
        data: {
          if (userInfo.realName.isNotEmpty) 'realName': userInfo.realName,
          'loginAt': DateTime.now().toIso8601String(),
        },
      ));
    });
  }

  /// 退出登录时清除用户上下文
  static void unbind() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }
}
