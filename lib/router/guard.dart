import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';

/// 路由的 `metadata`：没登录也能进的页面。守卫只看这个标记，不写死路径表。
const publicRoute = <String, dynamic>{'public': true};

/// 顶层守卫：要去 [location] 时该不该改道、改去哪；不用改道返回 null（技术架构 5.3）。
///
/// [isPublic] 是目标页面的「未登录可进」标记，[canMatch] 判断一个站内地址能不能对上路由表。
/// 强制更新和停服维护要等远程配置接口，现在只有登录的两条。
String? resolveRedirect({
  required Uri location,
  required bool isPublic,
  required SessionState session,
  required bool Function(Uri location) canMatch,
}) {
  switch (session) {
    case SignedOut(:final reason):
      if (isPublic) return null;
      // 自己退出的不记原地址；要去的本来就是发现页也不用记，登录后默认就去那里。
      final remember =
          reason != SignOutReason.loggedOut && location.path != Paths.discover;
      return Uri(
        path: Paths.login,
        queryParameters: {
          if (remember) 'from': location.toString(),
          if (reason == SignOutReason.expired) 'expired': '1',
        }.nullIfEmpty,
      ).toString();
    case SignedIn(:final justRegistered):
      if (!isLoginPath(location.path)) return null;
      final from = safeReturnPath(location.queryParameters['from'], canMatch);
      if (justRegistered) {
        return Uri(
          path: Paths.verify,
          queryParameters: {'onboarding': '1', 'from': ?from},
        ).toString();
      }
      return from ?? Paths.discover;
  }
}

bool isLoginPath(String path) =>
    path == Paths.login || path.startsWith('${Paths.login}/');

/// 登录后要回去的地址：只接受对得上路由表的站内路径，且不是登录页本身。
///
/// `from` 来自地址栏，谁都能拼；不校验的话，一个拼好的链接能在登录后把人带到外站。
String? safeReturnPath(String? from, bool Function(Uri location) canMatch) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  final uri = Uri.tryParse(from);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (isLoginPath(uri.path)) return null;
  return canMatch(uri) ? from : null;
}

extension on Map<String, String> {
  Map<String, String>? get nullIfEmpty => isEmpty ? null : this;
}
