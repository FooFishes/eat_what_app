import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';

/// 未登录也可访问的页面, 用作路由的 `metadata`.
///
/// 守卫只读取该标记, 不维护路径白名单.
const publicRoute = <String, dynamic>{'public': true};

// TODO: 强制更新和停服维护的跳转未实现. 远程配置接口上线后在此加入对应规则.
/// 顶层守卫. 返回访问 [location] 时应重定向到的地址, 无需重定向时返回 null.
///
/// [isPublic] 是目标页面的未登录可访问标记. [canMatch] 判断站内地址能否匹配路由表.
String? resolveRedirect({
  required Uri location,
  required bool isPublic,
  required SessionState session,
  required bool Function(Uri location) canMatch,
}) {
  switch (session) {
    case SignedOut(:final reason):
      if (isPublic) return null;
      // 用户主动退出时不记录原地址. 目标是发现页时也不记录, 因为登录后默认进入发现页.
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

/// 登录后返回的地址. 只接受能匹配路由表的站内路径, 且不能是登录页本身.
///
/// `from` 来自地址栏, 任何人都能构造. 不校验时, 构造的链接可以在登录后把用户带到外站.
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
